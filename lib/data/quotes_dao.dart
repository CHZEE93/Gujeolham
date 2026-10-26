import 'package:drift/drift.dart';

import 'database.dart';

part 'quotes_dao.g.dart';

/// 최근 저장한 책 정보(자동완성용).
typedef RecentBook = ({String title, String? author});

String nowIso() => DateTime.now().toUtc().toIso8601String();

@DriftAccessor(tables: [Quotes])
class QuotesDao extends DatabaseAccessor<AppDatabase> with _$QuotesDaoMixin {
  QuotesDao(super.db);

  /// 삭제되지 않은 구절을 최신순으로. [query]가 있으면
  /// content·book_title·author 중 하나라도 부분일치하는 것만.
  Stream<List<Quote>> watchQuotes({String query = ''}) {
    final q = query.trim();
    final select = this.select(quotes)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (q.isNotEmpty) {
      final pattern = '%${_escapeLike(q)}%';
      select.where(
        (t) =>
            t.content.like(pattern, escapeChar: r'\') |
            t.bookTitle.like(pattern, escapeChar: r'\') |
            t.author.like(pattern, escapeChar: r'\'),
      );
    }
    return select.watch();
  }

  Stream<Quote?> watchQuote(String id) {
    return (select(quotes)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  Future<Quote?> findById(String id) {
    return (select(quotes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 최근 저장한 책 제목(중복 제거, 최근순). 저자는 그 책의 가장 최근 값.
  Future<List<RecentBook>> recentBooks({int limit = 20}) async {
    final rows = await customSelect(
      'SELECT q.book_title AS title, '
      '(SELECT q2.author FROM quotes q2 '
      '  WHERE q2.book_title = q.book_title AND q2.deleted_at IS NULL '
      '  ORDER BY q2.updated_at DESC LIMIT 1) AS author '
      'FROM quotes q '
      "WHERE q.deleted_at IS NULL AND q.book_title IS NOT NULL AND q.book_title <> '' "
      'GROUP BY q.book_title '
      'ORDER BY MAX(q.updated_at) DESC '
      'LIMIT ?',
      variables: [Variable.withInt(limit)],
      readsFrom: {quotes},
    ).get();
    return [
      for (final r in rows)
        (
          title: r.read<String>('title'),
          author: r.readNullable<String>('author'),
        ),
    ];
  }

  Future<void> insertQuote(QuotesCompanion entry) {
    return into(quotes).insert(entry);
  }

  /// 내용을 수정하고 updated_at을 갱신한다.
  Future<void> updateQuote(String id, QuotesCompanion changes) {
    return (update(quotes)..where((t) => t.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(nowIso())),
    );
  }

  /// 소프트 삭제: deleted_at·updated_at만 세팅한다.
  Future<void> softDelete(String id) {
    final now = nowIso();
    return (update(quotes)..where((t) => t.id.equals(id))).write(
      QuotesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// 동기화용: 삭제된 것을 포함한 전체.
  Future<List<Quote>> allIncludingDeleted() => select(quotes).get();

  /// 동기화 결과 반영. 트랜잭션 안에서 로컬 updated_at을 다시 확인해
  /// 그 사이 로컬에서 더 늦게 고친 항목은 덮어쓰지 않는다. image_path는 건드리지 않는다.
  Future<int> applyRemote(
    List<QuotesCompanion> entries, {
    required bool Function(String remote, String local) isNewer,
  }) {
    return transaction(() async {
      var applied = 0;
      for (final e in entries) {
        final row = e.copyWith(imagePath: const Value.absent());
        final local = await findById(e.id.value);
        if (local == null) {
          await into(quotes).insert(row);
        } else if (isNewer(e.updatedAt.value, local.updatedAt)) {
          await (update(
            quotes,
          )..where((t) => t.id.equals(e.id.value))).write(row);
        } else {
          continue;
        }
        applied++;
      }
      return applied;
    });
  }

  static String _escapeLike(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
