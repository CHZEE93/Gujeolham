import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/data/database.dart';
import 'package:gujeolham/sync/sync_merge.dart';

Quote _local(String id, String updatedAt, {String? imagePath}) => Quote(
  id: id,
  content: 'local $id',
  imagePath: imagePath,
  createdAt: '2026-01-01T00:00:00.000Z',
  updatedAt: updatedAt,
);

Map<String, Object?> _remote(String id, String updatedAt, {String? deletedAt}) =>
    {
      'id': id,
      'content': 'remote $id',
      'book_title': null,
      'author': null,
      'page': 3,
      'memo': null,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };

void main() {
  test('내보내기 형식: version·exported_at·quotes, image_path 제외', () {
    final export = buildExport([_local('a', '2026-01-02T00:00:00Z', imagePath: 'images/a.jpg')]);
    expect(export['version'], 1);
    expect(DateTime.tryParse(export['exported_at']! as String), isNotNull);
    final q = (export['quotes']! as List).single as Map;
    expect(q.containsKey('image_path'), isFalse);
    expect(q.keys, containsAll(['id', 'content', 'created_at', 'updated_at', 'deleted_at']));
    // JSON 왕복
    final parsed = parseExport(jsonDecode(jsonEncode(export)));
    expect(parsed.single.id.value, 'a');
  });

  test('cherished_at은 왕복되고, 없는 옛 파일은 새기지 않은 것으로 읽는다', () {
    final q = _local('a', '2026-01-02T00:00:00Z').copyWith(
      cherishedAt: const Value('2026-01-02T00:00:00Z'),
    );
    final parsed = parseExport(jsonDecode(jsonEncode(buildExport([q]))));
    expect(parsed.single.cherishedAt.value, '2026-01-02T00:00:00Z');
    expect(quoteFromJson(_remote('b', '2026-01-02T00:00:00Z'))!.cherishedAt.value, isNull);
  });

  test('잘못된 항목은 건너뛴다', () {
    final parsed = parseExport({
      'version': 1,
      'quotes': [
        _remote('ok', '2026-01-02T00:00:00Z'),
        {'id': 'no-content', 'created_at': 'x', 'updated_at': 'y'},
        'garbage',
      ],
    });
    expect(parsed.map((e) => e.id.value), ['ok']);
    expect(parsed.single.page.value, 3);
    expect(parseExport(null), isEmpty);
  });

  test('id 기준 매칭: 원격이 더 늦거나 로컬에 없을 때만 채택', () {
    final local = [
      _local('same', '2026-01-02T00:00:00.000Z'),
      _local('localNewer', '2026-01-05T00:00:00.000Z'),
      _local('remoteNewer', '2026-01-02T00:00:00.000Z'),
    ];
    final remote = parseExport({
      'version': 1,
      'quotes': [
        _remote('same', '2026-01-02T00:00:00Z'), // 형식만 다르고 같은 시각
        _remote('localNewer', '2026-01-03T00:00:00Z'),
        _remote('remoteNewer', '2026-01-04T00:00:00Z', deletedAt: '2026-01-04T00:00:00Z'),
        _remote('remoteOnly', '2026-01-01T00:00:00Z'),
      ],
    });
    final winners = remoteWinners(local, remote);
    expect(winners.map((e) => e.id.value), ['remoteNewer', 'remoteOnly']);
    expect(winners.first.deletedAt.value, isNotNull);
  });

  test('isNewer는 ISO 문자열 길이와 무관하게 시각으로 비교한다', () {
    expect(isNewer('2026-01-01T00:00:00.123456Z', '2026-01-01T00:00:00.123Z'), isTrue);
    expect(isNewer('2026-01-01T00:00:00.123Z', '2026-01-01T00:00:00.123456Z'), isFalse);
  });
}
