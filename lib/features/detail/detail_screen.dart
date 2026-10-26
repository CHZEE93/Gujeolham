import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/hami.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../core/widgets/seal.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../save/quote_form.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  QuoteFormControllers? _editing;
  bool _busy = false;

  @override
  void dispose() {
    _editing?.dispose();
    super.dispose();
  }

  void _startEdit(Quote q) =>
      setState(() => _editing = QuoteFormControllers.fromQuote(q));

  void _cancelEdit() {
    final c = _editing;
    setState(() => _editing = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => c?.dispose());
  }

  Future<void> _update() async {
    final c = _editing;
    if (c == null || _busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(quoteRepositoryProvider).update(widget.id, c.toInput());
      if (mounted) _cancelEdit();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(S.unknownError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmDialog(
        title: S.deleteConfirmTitle,
        body: S.deleteConfirmBody,
        confirm: S.delete,
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(quoteRepositoryProvider).delete(widget.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(quoteProvider(widget.id));
    final quote = async.value;
    final editing = _editing;

    if (editing != null) {
      return HanjiPage(
        title: S.edit,
        bottom: BottomBar(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PillButton(
                  label: S.cancel,
                  tone: PillTone.light,
                  onPressed: _busy ? null : _cancelEdit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: PillButton(
                  label: S.update,
                  onPressed: _busy ? null : _update,
                ),
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [QuoteFormFields(controllers: editing)],
          ),
        ),
      );
    }

    return HanjiPage(
      cornerLayers: 2,
      norigae: true,
      actions: [
        if (quote != null) ...[
          RoundIconButton(
            icon: Icons.edit_rounded,
            tooltip: S.edit,
            onPressed: () => _startEdit(quote),
          ),
          RoundIconButton(
            icon: Icons.delete_rounded,
            tooltip: S.delete,
            color: context.hanji.dahong,
            onPressed: _delete,
          ),
        ],
      ],
      body: switch (async) {
        AsyncData(value: null) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Hami(size: 90),
              const SizedBox(height: 12),
              Text(S.notFound, style: context.text.bodyMedium),
            ],
          ),
        ),
        AsyncData(:final value?) => _QuoteView(quote: value),
        AsyncError() => Center(child: Text(S.unknownError)),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _QuoteView extends StatelessWidget {
  const _QuoteView({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat(S.dateFormat, S.locale);
    String date(String iso) => fmt.format(DateTime.parse(iso).toLocal());

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 40),
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PuffyCard(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              child: SelectableText(
                quote.content,
                style: juaStyle(
                  context.text.headlineSmall?.copyWith(
                    fontSize: 22,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: -12,
              child: Seal(
                text: S.sealAppName,
                size: 34,
                angle: -6 * math.pi / 180,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        if (quote.bookTitle != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: context.hanji.yeongal,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  quote.bookTitle!,
                  textAlign: TextAlign.center,
                  style: context.text.titleMedium,
                ),
              ),
            ],
          ),
        if (quote.author != null || quote.page != null) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              if (quote.author != null) SandChip(quote.author!),
              if (quote.page != null) SandChip(S.pageSuffix(quote.page!)),
            ],
          ),
        ],
        if (quote.memo != null) ...[
          const SizedBox(height: 24),
          PuffyCard(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.memoLabel, style: context.text.titleSmall),
                const SizedBox(height: 6),
                Text(quote.memo!, style: context.text.bodyMedium),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Center(
          child: Text(
            [
              '${S.createdAtLabel} ${date(quote.createdAt)}',
              if (quote.updatedAt != quote.createdAt)
                '${S.updatedAtLabel} ${date(quote.updatedAt)}',
            ].join('  ·  '),
            style: context.text.bodySmall,
          ),
        ),
        if (quote.imagePath != null) ...[
          const SizedBox(height: 24),
          _OriginalImage(relativePath: quote.imagePath!),
        ],
      ],
    );
  }
}

/// 원본 사진. 기본은 접힌 상태.
class _OriginalImage extends ConsumerStatefulWidget {
  const _OriginalImage({required this.relativePath});

  final String relativePath;

  @override
  ConsumerState<_OriginalImage> createState() => _OriginalImageState();
}

class _OriginalImageState extends ConsumerState<_OriginalImage> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final file = ref.watch(quoteImageProvider(widget.relativePath));

    return PuffyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.image_rounded, color: c.yeongal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(S.originalImage, style: context.text.titleSmall),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, color: c.yeongal),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: switch (file) {
                      AsyncData(value: final f?) => ClipRRect(
                        borderRadius: BorderRadius.circular(kCardRadius - 6),
                        child: InteractiveViewer(
                          maxScale: 4,
                          child: Image.file(f, fit: BoxFit.contain),
                        ),
                      ),
                      AsyncData() || AsyncError() => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          S.imageMissing,
                          style: context.text.bodySmall,
                        ),
                      ),
                      _ => const SizedBox(height: 48),
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

