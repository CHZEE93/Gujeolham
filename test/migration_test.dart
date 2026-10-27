import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/data/database.dart';

void main() {
  test('스키마 1 → 2: 기존 구절은 그대로, cherished_at 열이 생긴다', () async {
    // 1판의 quotes 테이블을 직접 만든다.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('''
          CREATE TABLE IF NOT EXISTS quotes (
            id TEXT NOT NULL, content TEXT NOT NULL, book_title TEXT, author TEXT,
            page INTEGER, memo TEXT, image_path TEXT, created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL, deleted_at TEXT, PRIMARY KEY (id));
          INSERT OR IGNORE INTO quotes (id, content, created_at, updated_at)
            VALUES ('old', '옛 구절', '2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z');
          PRAGMA user_version = 1;
        '''),
      ),
    );
    addTearDown(db.close);

    final row = (await db.quotesDao.findById('old'))!;
    expect(row.content, '옛 구절');
    expect(row.cherishedAt, isNull);

    await db.quotesDao.setCherished('old', true);
    expect((await db.quotesDao.findById('old'))!.cherishedAt, isNotNull);
  });
}
