import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/puffy.dart';
import '../../data/app_settings.dart';
import '../save/quote_form.dart';

/// 홈에 놓는 '읽고 있는 책' 알약. 누르면 책을 정하거나 바꾼다.
class ReadingBookChip extends ConsumerWidget {
  const ReadingBookChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(readingBookProvider);
    final c = context.hanji;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => const ReadingBookDialog(),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
          decoration: BoxDecoration(
            color: book == null ? c.paper : c.sand,
            borderRadius: BorderRadius.circular(999),
            border: book == null ? Border.all(color: c.line) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 14, color: c.dahong),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  book == null ? S.readingNone : S.readingNow(book.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: book == null ? c.galmukSub : c.galmuk,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: c.yeongal),
            ],
          ),
        ),
      ),
    );
  }
}

/// 읽고 있는 책 정하기. 최근 담은 책을 제목 칸에서 고를 수 있다.
class ReadingBookDialog extends ConsumerStatefulWidget {
  const ReadingBookDialog({super.key});

  @override
  ConsumerState<ReadingBookDialog> createState() => _ReadingBookDialogState();
}

class _ReadingBookDialogState extends ConsumerState<ReadingBookDialog> {
  late final _title = TextEditingController(
    text: ref.read(readingBookProvider)?.title ?? '',
  );
  late final _author = TextEditingController(
    text: ref.read(readingBookProvider)?.author ?? '',
  );

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _set() async {
    await ref.read(readingBookProvider.notifier).set(_title.text, _author.text);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _clear() async {
    await ref.read(readingBookProvider.notifier).set('', '');
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasBook = ref.watch(readingBookProvider) != null;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.readingTitle,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              S.readingDesc,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
            const SizedBox(height: 18),
            BookTitleField(controller: _title, authorController: _author),
            const SizedBox(height: 12),
            TextFormField(
              controller: _author,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: S.authorLabel),
              onFieldSubmitted: (_) => _set(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: hasBook ? S.readingClear : S.cancel,
                    tone: PillTone.light,
                    height: 46,
                    onPressed: hasBook ? _clear : () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    label: S.readingSet,
                    height: 46,
                    onPressed: _set,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
