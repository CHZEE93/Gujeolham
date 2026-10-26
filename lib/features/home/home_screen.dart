import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/hami.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../core/widgets/seal.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quotesProvider);
    final query = ref.watch(searchQueryProvider);
    final count = quotes.value?.length;

    return HanjiPage(
      cornerLayers: 2,
      norigae: true,
      showBack: false,
      actions: [
        RoundIconButton(
          icon: Icons.settings_rounded,
          tooltip: S.settings,
          onPressed: () => context.push(Routes.settings),
        ),
      ],
      floating: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: PillButton(
          label: S.fabCapture,
          icon: Icons.add_rounded,
          expand: false,
          onPressed: () => context.push(Routes.capture),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(S.appName, style: context.text.headlineLarge),
          SizedBox(
            height: 22,
            child: count == null || query.trim().isNotEmpty
                ? null
                : Text(S.quoteCount(count), style: context.text.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: _SearchField(
              onChanged: ref.read(searchQueryProvider.notifier).set,
            ),
          ),
          Expanded(
            child: quotes.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text(S.unknownError)),
              data: (list) => list.isEmpty
                  ? _Empty(searching: query.trim().isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 110),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemBuilder: (context, i) =>
                          QuoteCard(quote: list[i], index: i),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    return ValueListenableBuilder(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: S.searchHint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 6),
            child: Icon(Icons.search_rounded, size: 21, color: c.yeongal),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: c.yeongal),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hami(size: 96, smile: searching ? 0 : 0.3),
          const SizedBox(height: 16),
          Text(
            searching ? S.emptySearch : S.emptyQuotes,
            style: context.text.bodyMedium?.copyWith(
              color: context.hanji.galmukSub,
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

/// 홈 목록 카드. 카드마다 다홍/옥/치자 낙관을 번갈아 삐뚤게 찍는다.
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.quote, required this.index});

  final Quote quote;
  final int index;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      S.dateFormatShort,
      S.locale,
    ).format(DateTime.parse(quote.createdAt).toLocal());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PuffyCard(
          onTap: () => context.push(Routes.detail(quote.id)),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: Text(
                  quote.content,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (quote.bookTitle != null)
                          SandChip(
                            quote.bookTitle!,
                            icon: Icons.menu_book_rounded,
                          ),
                        if (quote.author != null) SandChip(quote.author!),
                        if (quote.page != null)
                          SandChip(S.pageSuffix(quote.page!)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(date, style: context.text.bodySmall),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: 16,
          child: Seal.forIndex(context, index, size: 30),
        ),
      ],
    );
  }
}
