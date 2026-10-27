import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../core/widgets/seal.dart';
import '../../data/providers.dart';
import '../capture/capture_session.dart';
import 'quote_form.dart';

class SaveScreen extends ConsumerStatefulWidget {
  const SaveScreen({super.key});

  @override
  ConsumerState<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends ConsumerState<SaveScreen> {
  final _formKey = GlobalKey<FormState>();
  late final QuoteFormControllers _c = QuoteFormControllers(
    content: ref.read(captureSessionProvider).joinedSelection,
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
            sourceImagePath: ref.read(captureSessionProvider).imagePath,
          );
      if (mounted) setState(() => _celebrating = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(S.unknownError)));
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
                    S.saveEditGuide,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall,
                  ),
                ),
                QuoteFormFields(controllers: _c),
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
