import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/decor.dart';
import '../../core/widgets/puffy.dart';
import '../../core/widgets/seal.dart';
import '../../data/database.dart';

/// 글로 보낼 때의 내용.
///
/// ```
/// 구절
///
/// — 책 제목 · 저자 · 12쪽
/// #구절함
/// ```
String shareText(Quote q) {
  final source = [
    ?q.bookTitle,
    ?q.author,
    if (q.page != null) S.pageSuffix(q.page!),
  ].join(' · ');
  return [
    q.content,
    if (source.isNotEmpty) '\n— $source',
    S.shareTag,
  ].join('\n');
}

Future<void> showShareSheet(BuildContext context, Quote quote) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.hanji.hanji,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kCardRadius)),
    ),
    builder: (context) => _ShareSheet(quote: quote),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.quote});

  final Quote quote;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  /// iPad에서는 공유 창을 띄울 기준 위치가 필요하다.
  Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(S.shareFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareImage(Rect? origin) => _run(() async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'gujeolham_${widget.quote.id}.png'));
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: shareText(widget.quote),
        sharePositionOrigin: origin,
      ),
    );
  });

  Future<void> _shareText(Rect? origin) => _run(
    () => SharePlus.instance.share(
      ShareParams(text: shareText(widget.quote), sharePositionOrigin: origin),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.shareTitle, style: context.text.titleLarge),
            const SizedBox(height: 4),
            Text(S.shareGuide, style: context.text.bodySmall),
            const SizedBox(height: 18),
            RepaintBoundary(
              key: _cardKey,
              child: ShareCard(quote: widget.quote),
            ),
            const SizedBox(height: 22),
            Builder(
              builder: (context) => PillButton(
                label: S.shareAsImage,
                icon: Icons.image_rounded,
                onPressed: _busy ? null : () => _shareImage(_origin(context)),
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) => PillButton(
                label: S.shareAsText,
                icon: Icons.notes_rounded,
                tone: PillTone.light,
                onPressed: _busy ? null : () => _shareText(_origin(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이미지로 보내는 구절 카드. 한지 바탕 + 구름 코너 + '구절함' 낙관.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final source = [?quote.author, if (quote.page != null) S.pageSuffix(quote.page!)];

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius),
        child: ColoredBox(
          color: c.hanji,
          child: Stack(
            children: [
              const Positioned.fill(child: CloudCorners(layers: 1)),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 44, 32, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              quote.content,
                              style: juaStyle(
                                context.text.headlineSmall?.copyWith(
                                  fontSize: 20,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (quote.bookTitle != null)
                                Text(
                                  quote.bookTitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.titleSmall,
                                ),
                              if (source.isNotEmpty)
                                Text(
                                  source.join(' · '),
                                  style: context.text.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Seal(
                          text: S.sealAppName,
                          size: 30,
                          angle: -6 * math.pi / 180,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
