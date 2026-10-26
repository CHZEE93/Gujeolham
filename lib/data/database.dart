import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'quotes_dao.dart';

part 'database.g.dart';

/// 저장된 구절. 날짜는 모두 ISO8601 UTC 문자열로 보관한다.
@DataClassName('Quote')
class Quotes extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  TextColumn get bookTitle => text().nullable()();
  TextColumn get author => text().nullable()();
  IntColumn get page => integer().nullable()();
  TextColumn get memo => text().nullable()();

  /// 로컬 전용(동기화 제외). 앱 문서 디렉토리 기준 상대 경로.
  TextColumn get imagePath => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  /// 소프트 삭제 시각. 값이 있으면 목록·검색에서 제외된다.
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Quotes], daos: [QuotesDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'gujeolham'));

  @override
  int get schemaVersion => 1;
}
