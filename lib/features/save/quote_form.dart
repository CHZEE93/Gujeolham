import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../data/quote_repository.dart';
import '../../data/quotes_dao.dart';

/// 담기·수정 화면이 함께 쓰는 입력 컨트롤러 묶음.
class QuoteFormControllers {
  QuoteFormControllers({
    String content = '',
    String? bookTitle,
    String? author,
    int? page,
    String? memo,
  }) : content = TextEditingController(text: content),
       bookTitle = TextEditingController(text: bookTitle ?? ''),
       author = TextEditingController(text: author ?? ''),
       page = TextEditingController(text: page?.toString() ?? ''),
       memo = TextEditingController(text: memo ?? '');

  factory QuoteFormControllers.fromQuote(Quote q) => QuoteFormControllers(
    content: q.content,
    bookTitle: q.bookTitle,
    author: q.author,
    page: q.page,
    memo: q.memo,
  );

  final TextEditingController content;
  final TextEditingController bookTitle;
  final TextEditingController author;
  final TextEditingController page;
  final TextEditingController memo;

  QuoteInput toInput() => QuoteInput(
    content: content.text.trim(),
    bookTitle: bookTitle.text,
    author: author.text,
    page: int.tryParse(page.text.trim()),
    memo: memo.text,
  );

  void dispose() {
    for (final c in [content, bookTitle, author, page, memo]) {
      c.dispose();
    }
  }
}

class QuoteFormFields extends StatelessWidget {
  const QuoteFormFields({super.key, required this.controllers});

  final QuoteFormControllers controllers;

  @override
  Widget build(BuildContext context) {
    final c = controllers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: c.content,
          minLines: 4,
          maxLines: null,
          style: context.text.bodyLarge,
          textCapitalization: TextCapitalization.sentences,
          decoration: _areaDecoration(context, S.contentLabel),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? S.contentRequired : null,
        ),
        const SizedBox(height: 16),
        _BookTitleField(controller: c.bookTitle, authorController: c.author),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: c.author,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: S.authorLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: c.page,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: S.pageLabel),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  return int.tryParse(t) == null ? S.pageInvalid : null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: c.memo,
          minLines: 2,
          maxLines: null,
          decoration: _areaDecoration(context, S.memoLabel),
        ),
      ],
    );
  }
}

/// 최근 저장한 책 제목을 자동완성으로 제안한다. 고르면 저자가 비어 있을 때 채운다.
class _BookTitleField extends ConsumerStatefulWidget {
  const _BookTitleField({
    required this.controller,
    required this.authorController,
  });

  final TextEditingController controller;
  final TextEditingController authorController;

  @override
  ConsumerState<_BookTitleField> createState() => _BookTitleFieldState();
}

class _BookTitleFieldState extends ConsumerState<_BookTitleField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(recentBooksProvider).value ?? const <RecentBook>[];
    final c = context.hanji;

    return RawAutocomplete<RecentBook>(
      textEditingController: widget.controller,
      focusNode: _focus,
      displayStringForOption: (b) => b.title,
      optionsBuilder: (value) {
        final q = value.text.trim();
        if (books.isEmpty) return const [];
        if (q.isEmpty) return books.take(5);
        return books
            .where((b) => b.title.contains(q) && b.title != q)
            .take(5);
      },
      onSelected: (b) {
        if (widget.authorController.text.trim().isEmpty && b.author != null) {
          widget.authorController.text = b.author!;
        }
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: S.bookTitleLabel),
            onFieldSubmitted: (_) => onSubmitted(),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: c.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kCardRadius),
            side: BorderSide(color: c.line),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 240,
              maxWidth: MediaQuery.sizeOf(context).width - 32,
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final b in options)
                  ListTile(
                    dense: true,
                    title: Text(b.title, style: context.text.bodyMedium),
                    subtitle: b.author == null
                        ? null
                        : Text(b.author!, style: context.text.bodySmall),
                    onTap: () => onSelected(b),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 여러 줄 입력은 알약 대신 카드와 같은 20px 모서리를 쓴다.
InputDecoration _areaDecoration(BuildContext context, String label) {
  final c = context.hanji;
  OutlineInputBorder b(Color color, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(kCardRadius),
    borderSide: BorderSide(color: color, width: w),
  );
  return InputDecoration(
    labelText: label,
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
    border: b(c.line),
    enabledBorder: b(c.line),
    focusedBorder: b(c.yeongal, 1.5),
    errorBorder: b(c.dahong),
    focusedErrorBorder: b(c.dahong, 1.5),
  );
}
