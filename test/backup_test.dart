import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/data/database.dart';
import 'package:gujeolham/sync/backup_service.dart';
import 'package:gujeolham/sync/sync_merge.dart';

QuotesCompanion _row(String id, String content, String updatedAt, {String? deletedAt}) =>
    QuotesCompanion.insert(
      id: id,
      content: content,
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: updatedAt,
      deletedAt: Value(deletedAt),
    );

List<int> _bytes(Object? json) => utf8.encode(jsonEncode(json));

void main() {
  late AppDatabase source;
  late AppDatabase target;
  late BackupService backup;

  setUp(() {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
    backup = BackupService(target.quotesDao);
  });
  tearDown(() async {
    await source.close();
    await target.close();
  });

  Future<List<int>> exported() async =>
      _bytes(buildExport(await source.quotesDao.allIncludingDeleted()));

  test('내보낸 파일을 빈 앱에 가져오면 구절이 그대로 들어온다', () async {
    await source.quotesDao.insertQuote(_row('a', '첫째', '2026-01-02T00:00:00Z'));
    await source.quotesDao.insertQuote(_row('b', '둘째', '2026-01-03T00:00:00Z'));

    expect(await backup.importBytes(await exported()), 2);
    final rows = await target.quotesDao.allIncludingDeleted();
    expect(rows.map((q) => q.content), unorderedEquals(['첫째', '둘째']));
  });

  test('가져오기는 합친다: 더 늦게 고친 쪽이 남고, 버린 구절은 세지 않는다', () async {
    await target.quotesDao.insertQuote(_row('keep', '기기에서 고침', '2026-02-01T00:00:00Z'));
    await target.quotesDao.insertQuote(_row('old', '옛 내용', '2026-01-01T00:00:00Z'));
    await target.quotesDao.insertQuote(_row('mine', '기기에만 있음', '2026-01-01T00:00:00Z'));

    await source.quotesDao.insertQuote(_row('keep', '파일의 옛 내용', '2026-01-15T00:00:00Z'));
    await source.quotesDao.insertQuote(_row('old', '파일에서 고침', '2026-01-20T00:00:00Z'));
    await source.quotesDao.insertQuote(
      _row('gone', '버린 구절', '2026-01-20T00:00:00Z', deletedAt: '2026-01-20T00:00:00Z'),
    );

    expect(await backup.importBytes(await exported()), 1);
    final byId = {
      for (final q in await target.quotesDao.allIncludingDeleted()) q.id: q,
    };
    expect(byId['keep']!.content, '기기에서 고침');
    expect(byId['old']!.content, '파일에서 고침');
    expect(byId['mine']!.content, '기기에만 있음');
    expect(byId['gone']!.deletedAt, isNotNull);
  });

  test('같은 파일을 두 번 가져오면 두 번째는 0개', () async {
    await source.quotesDao.insertQuote(_row('a', '첫째', '2026-01-02T00:00:00Z'));
    final bytes = await exported();
    expect(await backup.importBytes(bytes), 1);
    expect(await backup.importBytes(bytes), 0);
  });

  test('구절함 백업이 아닌 파일은 FormatException', () async {
    for (final bad in [
      utf8.encode('그냥 글'),
      <int>[],
      _bytes([1, 2]),
      _bytes({'version': 1}),
    ]) {
      await expectLater(backup.importBytes(bad), throwsFormatException);
    }
    expect(await target.quotesDao.allIncludingDeleted(), isEmpty);
  });

  test('더 새로운 형식 버전은 UnsupportedRemoteFormat', () async {
    await expectLater(
      backup.importBytes(_bytes({'version': kSyncFormatVersion + 1, 'quotes': []})),
      throwsA(isA<UnsupportedRemoteFormat>()),
    );
  });
}
