import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../core/widgets/seal.dart';
import '../../data/app_settings.dart';
import '../../data/providers.dart';
import '../capture/capture_session.dart';
import 'quote_form.dart';

/// 구절 담기. 촬영에서 고른 문장으로 시작하거나, [manual]이면 빈 칸에서 직접 쓴다.
/// 읽고 있는 책이 정해져 있으면 책 제목과 저자를 미리 채운다.
class SaveScreen extends ConsumerStatefulWidget {
  const SaveScreen({super.key, this.manual = false});

  final bool manual;

  @override
  ConsumerState<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends ConsumerState<SaveScreen> {
  final _formKey = GlobalKey<FormState>();
  late final QuoteFormControllers _c = QuoteFormControllers(
    content: widget.manual
        ? ''
        : ref.read(captureSessionProvider).joinedSelection,
    bookTitle: ref.read(readingBookProvider)?.title,
    author: ref.read(readingBookProvider)?.author,
  );
  bool _saving = false;
  bool _celebrating = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref
          .read(quoteRepositoryProvider)
          .create(
            _c.toInput(),
            sourceImagePath: widget.manual
                ? null
                : ref.read(captureSessionProvider).imagePath,
          );
      if (mounted) setState(() => _celebrating = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.unknownError)));
    }
  }

  Future<void> _afterCelebration() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    ref.read(captureSessionProvider.notifier).clear();
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HanjiPage(
          title: S.saveTitle,
          bottom: BottomBar(
            child: PillButton(
              label: S.saveButton,
              icon: Icons.inventory_2_rounded,
              onPressed: _saving ? null : _save,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.manual ? S.writeGuide : S.saveEditGuide,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
                  ),
                ),
                QuoteFormFields(controllers: _c, autofocus: widget.manual),
              ],
            ),
          ),
        ),
        if (_celebrating)
          Positioned.fill(child: SaveCelebration(onDone: _afterCelebration)),
      ],
    );
  }
}
