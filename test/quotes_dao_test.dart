import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/data/database.dart';
import 'package:gujeolham/data/image_store.dart';
import 'package:gujeolham/data/quote_repository.dart';
import 'package:gujeolham/sync/sync_merge.dart';

void main() {
  late AppDatabase db;
  late QuoteRepository repo;
  var changes = 0;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    changes = 0;
    repo = QuoteRepository(db.quotesDao, ImageStore(), onChanged: () => changes++);
  });
  tearDown(() => db.close());

  Future<List<Quote>> visible([String q = '']) =>
      db.quotesDao.watchQuotes(query: q).first;

  test('저장하면 목록에 최신순으로 보이고 변경 훅이 호출된다', () async {
    await repo.create(const QuoteInput(content: '첫째'));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create(const QuoteInput(content: '둘째', bookTitle: ' 책 '));
    final list = await visible();
    expect(list.map((e) => e.content), ['둘째', '첫째']);
    expect(list.first.bookTitle, '책');
    expect(list.last.bookTitle, isNull);
    expect(changes, 2);
  });

  test('검색은 content·book_title·author 부분일치, LIKE 특수문자는 그대로 검색', () async {
    await repo.create(const QuoteInput(content: '바람이 분다', author: '김소월'));
    await repo.create(const QuoteInput(content: '100% 진심', bookTitle: '진달래꽃'));
    expect((await visible('바람')).length, 1);
    expect((await visible('소월')).length, 1);
    expect((await visible('달래')).length, 1);
    expect((await visible('%')).single.content, '100% 진심');
    expect(await visible('없는말'), isEmpty);
  });

  test('수정은 updated_at을 갱신하고, 삭제는 소프트 삭제다', () async {
    final id = await repo.create(const QuoteInput(content: '원문'));
    final before = (await db.quotesDao.findById(id))!;
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.update(id, const QuoteInput(content: '고친 글', page: 12));
    final after = (await db.quotesDao.findById(id))!;
    expect(after.content, '고친 글');
    expect(after.page, 12);
    expect(after.createdAt, before.createdAt);
    expect(isNewer(after.updatedAt, before.updatedAt), isTrue);

    await repo.delete(id);
    expect(await visible(), isEmpty);
    final deleted = (await db.quotesDao.findById(id))!;
    expect(deleted.deletedAt, isNotNull);
    expect((await db.quotesDao.allIncludingDeleted()).length, 1);
  });

  test('마음에 새기면 새긴 구절 목록에 보이고, 거두면 빠진다', () async {
    final a = await repo.create(const QuoteInput(content: '새길 구절'));
    await repo.create(const QuoteInput(content: '그냥 구절'));
    final before = (await db.quotesDao.findById(a))!;
    changes = 0;
    await Future<void>.delayed(const Duration(milliseconds: 2));

    await repo.setCherished(a, true);
    final cherished = (await db.quotesDao.findById(a))!;
    expect(cherished.cherishedAt, isNotNull);
    expect(isNewer(cherished.updatedAt, before.updatedAt), isTrue);
    expect(changes, 1);
    expect(
      (await db.quotesDao.watchQuotes(cherishedOnly: true).first).map((q) => q.id),
      [a],
    );
    expect(await db.quotesDao.watchQuotes(query: '그냥', cherishedOnly: true).first, isEmpty);

    await repo.setCherished(a, false);
    expect((await db.quotesDao.findById(a))!.cherishedAt, isNull);
    expect(await db.quotesDao.watchQuotes(cherishedOnly: true).first, isEmpty);
    expect((await visible()).length, 2);
  });

  test('최근 책 제목은 중복 없이 최근순, 저자 포함', () async {
    await repo.create(const QuoteInput(content: 'a', bookTitle: '책1', author: '갑'));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create(const QuoteInput(content: 'b', bookTitle: '책2'));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.create(const QuoteInput(content: 'c', bookTitle: '책1', author: '을'));
    final books = await db.quotesDao.recentBooks();
    expect(books.map((b) => b.title), ['책1', '책2']);
    expect(books.first.author, '을');
  });

  test('applyRemote는 image_path를 보존하고 더 늦은 로컬 수정은 덮어쓰지 않는다', () async {
    await db.quotesDao.insertQuote(
      QuotesCompanion.insert(
        id: 'x',
        content: '로컬',
        imagePath: const Value('images/x.jpg'),
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-02T00:00:00.000Z',
      ),
    );
    final newer = quoteFromJson({
      'id': 'x',
      'content': '원격',
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-03T00:00:00.000Z',
      'deleted_at': '2026-01-03T00:00:00.000Z',
    })!;
    final older = quoteFromJson({
      'id': 'x',
      'content': '옛 원격',
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T12:00:00.000Z',
    })!;

    expect(await db.quotesDao.applyRemote([older], isNewer: isNewer), 0);
    expect((await db.quotesDao.findById('x'))!.content, '로컬');

    expect(await db.quotesDao.applyRemote([newer], isNewer: isNewer), 1);
    final row = (await db.quotesDao.findById('x'))!;
    expect(row.content, '원격');
    expect(row.deletedAt, isNotNull);
    expect(row.imagePath, 'images/x.jpg');
  });
}
