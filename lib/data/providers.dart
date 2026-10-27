import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'image_store.dart';
import 'quote_repository.dart';
import 'quotes_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final quotesDaoProvider = Provider<QuotesDao>(
  (ref) => ref.watch(databaseProvider).quotesDao,
);

final imageStoreProvider = Provider<ImageStore>((ref) => ImageStore());

/// 데이터 변경 후 호출할 훅. 동기화 계층이 override 없이 덮어쓸 수 있도록 분리.
final quoteChangedHookProvider = Provider<void Function()>((ref) => () {});

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(
    ref.watch(quotesDaoProvider),
    ref.watch(imageStoreProvider),
    onChanged: ref.watch(quoteChangedHookProvider),
  );
});

/// 홈 검색어.
class SearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQuery, String>(
  SearchQuery.new,
);

/// 홈에서 새긴 구절만 볼지.
class CherishedFilter extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final cherishedFilterProvider = NotifierProvider<CherishedFilter, bool>(
  CherishedFilter.new,
);

final quotesProvider = StreamProvider<List<Quote>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final cherishedOnly = ref.watch(cherishedFilterProvider);
  return ref
      .watch(quotesDaoProvider)
      .watchQuotes(query: query, cherishedOnly: cherishedOnly);
});

final quoteProvider = StreamProvider.family<Quote?, String>(
  (ref, id) => ref.watch(quotesDaoProvider).watchQuote(id),
);

final recentBooksProvider = FutureProvider.autoDispose<List<RecentBook>>(
  (ref) => ref.watch(quotesDaoProvider).recentBooks(),
);

final quoteImageProvider = FutureProvider.autoDispose.family<File?, String?>(
  (ref, relativePath) => ref.watch(imageStoreProvider).resolve(relativePath),
);
