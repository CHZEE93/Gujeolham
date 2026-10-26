// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotes_dao.dart';

// ignore_for_file: type=lint
mixin _$QuotesDaoMixin on DatabaseAccessor<AppDatabase> {
  $QuotesTable get quotes => attachedDatabase.quotes;
  QuotesDaoManager get managers => QuotesDaoManager(this);
}

class QuotesDaoManager {
  final _$QuotesDaoMixin _db;
  QuotesDaoManager(this._db);
  $$QuotesTableTableManager get quotes =>
      $$QuotesTableTableManager(_db.attachedDatabase, _db.quotes);
}
