import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import '../core/strings.dart';
import '../data/providers.dart';
import 'drive_sync_service.dart';
import 'google_auth.dart';
import 'sync_state_store.dart';

class SyncStatus {
  const SyncStatus({
    this.ready = false,
    this.linked = false,
    this.email,
    this.lastSyncAt,
    this.lastError,
    this.syncing = false,
  });

  final bool ready;
  final bool linked;
  final String? email;
  final DateTime? lastSyncAt;
  final String? lastError;
  final bool syncing;

  SyncStatus copyWith({
    bool? ready,
    bool? linked,
    String? Function()? email,
    DateTime? Function()? lastSyncAt,
    String? Function()? lastError,
    bool? syncing,
  }) => SyncStatus(
    ready: ready ?? this.ready,
    linked: linked ?? this.linked,
    email: email != null ? email() : this.email,
    lastSyncAt: lastSyncAt != null ? lastSyncAt() : this.lastSyncAt,
    lastError: lastError != null ? lastError() : this.lastError,
    syncing: syncing ?? this.syncing,
  );

  StoredSyncState toStored() => StoredSyncState(
    linked: linked,
    email: email,
    lastSyncAt: lastSyncAt,
    lastError: lastError,
  );
}

final googleAuthProvider = Provider<GoogleAuth>((ref) => GoogleAuth());
final syncStateStoreProvider = Provider<SyncStateStore>(
  (ref) => SyncStateStore(),
);
final driveSyncServiceProvider = Provider<DriveSyncService>(
  (ref) => DriveSyncService(ref.watch(quotesDaoProvider)),
);

/// 연동 상태와 동기화 실행을 관리한다. 미연동·오류 시에는 조용히 건너뛰고
/// 마지막 오류만 기록한다.
class SyncController extends Notifier<SyncStatus> {
  late final GoogleAuth _auth = ref.read(googleAuthProvider);
  late final SyncStateStore _store = ref.read(syncStateStoreProvider);
  late final DriveSyncService _service = ref.read(driveSyncServiceProvider);

  @override
  SyncStatus build() {
    Future.microtask(_bootstrap);
    return const SyncStatus();
  }

  /// 앱 시작 시: 저장된 상태 복원 → 연동돼 있으면 조용히 로그인 복원 후 동기화.
  Future<void> _bootstrap() async {
    final stored = await _store.load();
    state = state.copyWith(
      ready: true,
      linked: stored.linked,
      email: () => stored.email,
      lastSyncAt: () => stored.lastSyncAt,
      lastError: () => stored.lastError,
    );
    if (!stored.linked) return;
    final account = await _auth.restore();
    if (account != null) {
      state = state.copyWith(email: () => account.email);
    }
    await syncNow();
  }

  /// 로그인하고 최초 동기화(원격이 없으면 로컬 전체 업로드)를 수행한다.
  /// 실패 시 사용자에게 보여줄 메시지를 돌려준다.
  Future<String?> link() async {
    if (!GoogleAuth.isConfigured) return S.googleNotConfigured;
    try {
      final account = await _auth.signIn();
      state = state.copyWith(
        linked: true,
        email: () => account.email,
        lastError: () => null,
      );
      await _persist();
    } catch (e) {
      return _message(e);
    }
    final ok = await syncNow(interactive: true);
    return ok ? null : state.lastError;
  }

  Future<void> unlink() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // 로그아웃 실패와 무관하게 로컬 연동 상태는 해제한다.
    }
    state = state.copyWith(
      linked: false,
      email: () => null,
      lastError: () => null,
    );
    await _persist();
  }

  /// 저장·수정·삭제 직후 호출. 결과를 기다리지 않는다.
  void syncSilently() => unawaited(syncNow());

  /// 동기화를 실행하고 성공 여부를 돌려준다. 미연동이면 아무것도 하지 않는다.
  Future<bool> syncNow({bool interactive = false}) async {
    if (!state.linked) return false;
    state = state.copyWith(syncing: true);
    try {
      if (!GoogleAuth.isConfigured) throw const _NotConfigured();
      if (_auth.account == null) {
        await _auth.restore();
        if (_auth.account == null && interactive) await _auth.signIn();
      }
      final account = _auth.account;
      if (account == null) throw const _NotSignedIn();

      final client = await _auth.authClient(interactive: interactive);
      if (client == null) throw const _NotAuthorized();
      try {
        await _service.sync(client);
      } finally {
        client.close();
      }
      state = state.copyWith(
        email: () => account.email,
        lastSyncAt: () => DateTime.now().toUtc(),
        lastError: () => null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(lastError: () => _message(e));
      return false;
    } finally {
      state = state.copyWith(syncing: _service.isRunning);
      await _persist();
    }
  }

  Future<void> _persist() => _store.save(state.toStored());

  static String _message(Object e) => switch (e) {
    GoogleSignInException(code: GoogleSignInExceptionCode.canceled) =>
      S.signInCanceled,
    GoogleSignInException(:final description) =>
      '${S.signInFailed}${description == null ? '' : ' ($description)'}',
    _NotConfigured() => S.googleNotConfigured,
    _NotSignedIn() => S.syncNotLinked,
    _NotAuthorized() => S.authorizationDenied,
    drive.DetailedApiRequestError(:final status, :final message) =>
      '${S.driveError} ($status${message == null ? '' : ': $message'})',
    SocketException() || TimeoutException() || HttpException() =>
      S.networkError,
    UnsupportedRemoteFormat() => S.remoteFormatError,
    FormatException() => S.remoteFormatError,
    _ => '${S.unknownError} ($e)',
  };
}

class _NotConfigured implements Exception {
  const _NotConfigured();
}

class _NotSignedIn implements Exception {
  const _NotSignedIn();
}

class _NotAuthorized implements Exception {
  const _NotAuthorized();
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);
