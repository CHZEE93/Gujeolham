import 'dart:math' as math;

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
    final cherishedOnly = ref.watch(cherishedFilterProvider);
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
                : Text(
                    cherishedOnly
                        ? S.cherishedCount(count)
                        : S.quoteCount(count),
                    style: context.text.bodySmall,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: _SearchField(
              onChanged: ref.read(searchQueryProvider.notifier).set,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _FilterChip(
                  label: S.filterAll,
                  selected: !cherishedOnly,
                  onTap: () =>
                      ref.read(cherishedFilterProvider.notifier).set(false),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: S.filterCherished,
                  icon: Icons.favorite_rounded,
                  selected: cherishedOnly,
                  onTap: () =>
                      ref.read(cherishedFilterProvider.notifier).set(true),
                ),
              ],
            ),
          ),
          Expanded(
            child: quotes.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text(S.unknownError)),
              data: (list) => list.isEmpty
                  ? _Empty(
                      searching: query.trim().isNotEmpty,
                      cherishedOnly: cherishedOnly,
                    )
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

/// 모든 구절 / 새긴 구절 고르기.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final fg = selected ? c.paper : c.galmuk;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.galmuk : c.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c.galmuk : c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? c.paper : c.dahong),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: context.text.bodySmall?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.searching, required this.cherishedOnly});

  final bool searching;
  final bool cherishedOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hami(size: 96, smile: searching ? 0 : 0.3),
          const SizedBox(height: 16),
          Text(
            searching
                ? S.emptySearch
                : cherishedOnly
                ? S.emptyCherished
                : S.emptyQuotes,
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
          child: quote.cherishedAt != null
              ? Seal(
                  text: S.sealCherished,
                  size: 30,
                  angle: 5 * math.pi / 180,
                )
              : Seal.forIndex(context, index, size: 30),
        ),
      ],
    );
  }
}
