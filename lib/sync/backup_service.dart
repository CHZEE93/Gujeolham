import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/providers.dart';
import '../data/quotes_dao.dart';
import 'sync_merge.dart';

/// Google 등록 없이 쓰는 백업. Drive 동기화와 같은 형식의 `quotes.json`을
/// 파일로 내보내고, 가져올 때는 동기화와 같은 규칙(updated_at이 늦은 쪽)으로 합친다.
/// 버린 구절(deleted_at)도 담아야 다른 기기에서 가져올 때 버린 것이 되살아나지 않는다.
class BackupService {
  BackupService(this._dao);

  final QuotesDao _dao;

  /// 백업 파일을 임시 폴더에 쓰고 돌려준다. 이름에 날짜를 붙인다.
  Future<File> writeBackupFile() async {
    final quotes = await _dao.allIncludingDeleted();
    final dir = Directory(
      p.join((await getTemporaryDirectory()).path, 'backup'),
    );
    await dir.create(recursive: true);
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final file = File(p.join(dir.path, 'gujeolham_backup_$date.json'));
    await file.writeAsString(jsonEncode(buildExport(quotes)), flush: true);
    return file;
  }

  /// 백업 파일을 합치고, 새로 들어오거나 바뀐 (버리지 않은) 구절 수를 돌려준다.
  /// 파일이 잘못되면 [FormatException]·[UnsupportedRemoteFormat]을 던진다.
  Future<int> importBytes(List<int> bytes) async {
    final incoming = decodeBackup(bytes);
    final winners = remoteWinners(await _dao.allIncludingDeleted(), incoming);
    if (winners.isEmpty) return 0;
    await _dao.applyRemote(winners, isNewer: isNewer);
    return winners.where((w) => w.deletedAt.value == null).length;
  }
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(quotesDaoProvider)),
);
