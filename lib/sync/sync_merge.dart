import 'package:drift/drift.dart';

import '../data/database.dart';

/// Drive에 올리는 파일 형식 버전.
const kSyncFormatVersion = 1;

/// image_path를 제외한 구절 → JSON.
Map<String, Object?> quoteToJson(Quote q) => {
  'id': q.id,
  'content': q.content,
  'book_title': q.bookTitle,
  'author': q.author,
  'page': q.page,
  'memo': q.memo,
  'created_at': q.createdAt,
  'updated_at': q.updatedAt,
  'deleted_at': q.deletedAt,
  'cherished_at': q.cherishedAt,
};

/// JSON → DB 반영용 Companion(image_path 없음). 형식이 틀리면 null.
QuotesCompanion? quoteFromJson(Map<String, Object?> j) {
  final id = j['id'];
  final content = j['content'];
  final createdAt = j['created_at'];
  final updatedAt = j['updated_at'];
  if (id is! String ||
      content is! String ||
      createdAt is! String ||
      updatedAt is! String ||
      DateTime.tryParse(updatedAt) == null) {
    return null;
  }
  final page = j['page'];
  return QuotesCompanion(
    id: Value(id),
    content: Value(content),
    bookTitle: Value(j['book_title'] as String?),
    author: Value(j['author'] as String?),
    page: Value(page is num ? page.toInt() : null),
    memo: Value(j['memo'] as String?),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    deletedAt: Value(j['deleted_at'] as String?),
    cherishedAt: Value(j['cherished_at'] as String?),
  );
}

Map<String, Object?> buildExport(List<Quote> quotes) => {
  'version': kSyncFormatVersion,
  'exported_at': DateTime.now().toUtc().toIso8601String(),
  'quotes': [for (final q in quotes) quoteToJson(q)],
};

/// 원격 파일의 quotes 목록을 파싱한다. 잘못된 항목은 건너뛴다.
List<QuotesCompanion> parseExport(Object? decoded) {
  if (decoded is! Map) return const [];
  final list = decoded['quotes'];
  if (list is! List) return const [];
  return [
    for (final e in list)
      if (e is Map) ?quoteFromJson(e.cast<String, Object?>()),
  ];
}

bool isNewer(String a, String b) =>
    DateTime.parse(a).isAfter(DateTime.parse(b));

/// id 기준으로 매칭해 원격이 더 최신(updated_at 기준)이거나 로컬에 없는 항목만 돌려준다.
/// 같으면 로컬을 유지한다.
List<QuotesCompanion> remoteWinners(
  List<Quote> local,
  List<QuotesCompanion> remote,
) {
  final byId = {for (final q in local) q.id: q};
  return [
    for (final r in remote)
      if (byId[r.id.value] == null ||
          isNewer(r.updatedAt.value, byId[r.id.value]!.updatedAt))
        r,
  ];
}
