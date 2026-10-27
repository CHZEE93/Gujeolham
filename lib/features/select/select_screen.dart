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
                onEdit: () async {
                  final fixed = await showSentenceEditor(
                    context,
                    session.sentences[i],
                  );
                  if (fixed != null) {
                    ref
                        .read(captureSessionProvider.notifier)
                        .editSentence(i, fixed);
                  }
                },
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
    required this.onEdit,
  });

  final String text;
  final VoidCallback onEdit;

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
            Semantics(
              button: true,
              label: S.sentenceEdit,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 0, 8),
                  child: Icon(Icons.edit_rounded, size: 19, color: c.yeongal),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 문장 하나를 고치는 창. 고친 글을 돌려주고, 취소하면 null.
Future<String?> showSentenceEditor(BuildContext context, String initial) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.hanji.hanji,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kCardRadius)),
    ),
    builder: (context) => _SentenceEditor(initial: initial),
  );
}

class _SentenceEditor extends StatefulWidget {
  const _SentenceEditor({required this.initial});

  final String initial;

  @override
  State<_SentenceEditor> createState() => _SentenceEditorState();
}

class _SentenceEditorState extends State<_SentenceEditor> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 키보드가 올라오면 그만큼 위로 민다.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.sentenceEdit, style: context.text.titleLarge),
              const SizedBox(height: 4),
              Text(
                S.sentenceEditGuide,
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                style: context.text.bodyLarge,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(kCardRadius)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PillButton(
                      label: S.cancel,
                      tone: PillTone.light,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: PillButton(
                      label: S.sentenceEditDone,
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.pop(context, _controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
