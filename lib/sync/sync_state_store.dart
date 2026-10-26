import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 동기화 설정·기록. 기기 로컬에만 보관한다.
class StoredSyncState {
  const StoredSyncState({
    this.linked = false,
    this.email,
    this.lastSyncAt,
    this.lastError,
  });

  final bool linked;
  final String? email;
  final DateTime? lastSyncAt;
  final String? lastError;

  Map<String, Object?> toJson() => {
    'linked': linked,
    'email': email,
    'last_sync_at': lastSyncAt?.toUtc().toIso8601String(),
    'last_error': lastError,
  };

  factory StoredSyncState.fromJson(Map<String, Object?> j) => StoredSyncState(
    linked: j['linked'] == true,
    email: j['email'] as String?,
    lastSyncAt: DateTime.tryParse(j['last_sync_at'] as String? ?? ''),
    lastError: j['last_error'] as String?,
  );
}

class SyncStateStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'sync_state.json'));
  }

  Future<StoredSyncState> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const StoredSyncState();
      final j = jsonDecode(await f.readAsString());
      return j is Map
          ? StoredSyncState.fromJson(j.cast<String, Object?>())
          : const StoredSyncState();
    } catch (_) {
      return const StoredSyncState();
    }
  }

  Future<void> save(StoredSyncState state) async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(state.toJson()));
    } catch (_) {
      // 기록 실패는 앱 동작에 영향을 주지 않는다.
    }
  }
}
