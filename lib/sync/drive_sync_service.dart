import 'dart:async';
import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../data/quotes_dao.dart';
import 'sync_merge.dart';

/// 원격 파일 형식이 이 앱이 아는 것보다 새로울 때.
class UnsupportedRemoteFormat implements Exception {
  const UnsupportedRemoteFormat(this.version);
  final Object? version;
}

/// Drive appDataFolder의 `quotes.json` 하나로 전체를 동기화한다.
///
/// 원격 다운로드 → id 매칭 → updated_at이 늦은 쪽 채택(deleted_at 포함)
/// → 로컬 반영 → 병합 결과 업로드. 원격 파일이 없으면 로컬 전체로 새로 만든다.
class DriveSyncService {
  DriveSyncService(this._dao);

  static const fileName = 'quotes.json';
  static const _appData = 'appDataFolder';

  final QuotesDao _dao;
  Future<void>? _running;
  bool _rerun = false;

  bool get isRunning => _running != null;

  /// 동시에 한 번만 실행한다. 실행 중에 다시 요청되면 끝난 뒤 한 번 더 돈다
  /// (그 사이 로컬 변경이 업로드에서 빠지지 않도록).
  Future<void> sync(http.Client client) {
    if (_running case final running?) {
      _rerun = true;
      return running;
    }
    final run = _loop(client).whenComplete(() => _running = null);
    _running = run;
    return run;
  }

  Future<void> _loop(http.Client client) async {
    do {
      _rerun = false;
      await _syncOnce(drive.DriveApi(client));
    } while (_rerun);
  }

  Future<void> _syncOnce(drive.DriveApi api) async {
    final remoteFile = await _find(api);
    final remote = remoteFile == null
        ? const <Never>[]
        : parseExport(await _download(api, remoteFile.id!));

    final local = await _dao.allIncludingDeleted();
    final winners = remoteWinners(local, remote);
    if (winners.isNotEmpty) {
      await _dao.applyRemote(winners, isNewer: isNewer);
    }

    final merged = await _dao.allIncludingDeleted();
    await _upload(api, remoteFile?.id, buildExport(merged));
  }

  Future<drive.File?> _find(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: _appData,
      q: "name = '$fileName' and trashed = false",
      $fields: 'files(id, modifiedTime)',
      orderBy: 'modifiedTime desc',
      pageSize: 10,
    );
    final files = list.files ?? const [];
    return files.isEmpty ? null : files.first;
  }

  Future<Object?> _download(drive.DriveApi api, String id) async {
    final media =
        await api.files.get(
              id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) return null;
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map) {
      final version = decoded['version'];
      if (version is! int || version > kSyncFormatVersion) {
        throw UnsupportedRemoteFormat(version);
      }
    }
    return decoded;
  }

  Future<void> _upload(
    drive.DriveApi api,
    String? existingId,
    Map<String, Object?> body,
  ) async {
    final bytes = utf8.encode(jsonEncode(body));
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
    if (existingId == null) {
      await api.files.create(
        drive.File()
          ..name = fileName
          ..parents = [_appData]
          ..mimeType = 'application/json',
        uploadMedia: media,
      );
    } else {
      await api.files.update(drive.File(), existingId, uploadMedia: media);
    }
  }
}
