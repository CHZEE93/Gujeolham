import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../core/widgets/seal.dart';
import '../capture/capture_session.dart';

class SelectScreen extends ConsumerWidget {
  const SelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(captureSessionProvider);
    final count = session.selected.length;

    return HanjiPage(
      title: S.selectTitle,
      bottom: BottomBar(
        child: PillButton(
          label: count == 0 ? S.selectNone : S.selectButton(count),
          onPressed: count == 0 ? null : () => context.push(Routes.save),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 6),
            child: Text(S.selectGuide, style: context.text.bodySmall),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
              itemCount: session.sentences.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _SentenceTile(
                text: session.sentences[i],
                order: session.selected.indexOf(i),
                onTap: () =>
                    ref.read(captureSessionProvider.notifier).toggle(i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceTile extends StatelessWidget {
  const _SentenceTile({
    required this.text,
    required this.order,
    required this.onTap,
  });

  final String text;

  /// 선택 순서(0부터). 선택되지 않았으면 -1.
  final int order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final selected = order >= 0;

    return Semantics(
      selected: selected,
      button: true,
      child: PuffyCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
        color: selected ? c.sand : c.paper,
        borderColor: selected ? c.yeongal : c.line,
        borderWidth: selected ? 1.5 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, a) =>
                    ScaleTransition(scale: a, child: child),
                child: selected
                    ? Seal(
                        key: ValueKey(order),
                        text: '${order + 1}',
                        size: 26,
                        color: c.sealColors[order % 3],
                        angle: (order.isEven ? -5 : 5) * math.pi / 180,
                      )
                    : Container(
                        key: const ValueKey(-1),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.yeongal, width: 1.5),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: context.text.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
