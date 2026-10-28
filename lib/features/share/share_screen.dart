import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import '../../data/app_settings.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import 'share_card.dart';

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

/// 카드 이미지의 가로 픽셀 수.
const _imageWidth = 1080.0;

/// 마지막에 고른 카드 모양. 다음에 보낼 때도 그 모양으로 시작한다.
class ShareCardStyleController extends Notifier<ShareCardStyle> {
  static const _key = 'share_card_style';
  bool _picked = false;

  @override
  ShareCardStyle build() {
    unawaited(_load());
    return ShareCardStyle.theme;
  }

  Future<void> _load() async {
    final name = await ref.read(appSettingsStoreProvider).read(_key);
    if (name != null && !_picked) state = ShareCardStyle.byName(name);
  }

  Future<void> select(ShareCardStyle style) async {
    _picked = true;
    state = style;
    await ref.read(appSettingsStoreProvider).write(_key, style.name);
  }
}

final shareCardStyleProvider =
    NotifierProvider<ShareCardStyleController, ShareCardStyle>(
      ShareCardStyleController.new,
    );

/// 보내기: 카드나 글로 보낼 모습을 미리 보고, 카드 모양을 고른 뒤 보낸다.
class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  final _cardKey = GlobalKey();
  bool _asText = false;
  bool _busy = false;

  /// iPad에서는 공유 창을 띄울 기준 위치가 필요하다.
  Rect? _origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _send(Quote quote, Rect? origin) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_asText) {
        await SharePlus.instance.share(
          ShareParams(text: shareText(quote), sharePositionOrigin: origin),
        );
      } else {
        final file = await _renderCard(quote);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: shareText(quote),
            sharePositionOrigin: origin,
          ),
        );
      }
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

  /// 미리 보기 카드를 화면 크기와 무관하게 가로 1080픽셀 PNG로 저장한다.
  Future<File> _renderCard(Quote quote) async {
    final boundary =
        _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: _imageWidth / kShareCardSize.width,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'gujeolham_${quote.id}.png'));
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    final quote = ref.watch(quoteProvider(widget.id)).value;
    final style = ref.watch(shareCardStyleProvider);

    return HanjiPage(
      title: S.shareTitle,
      body: quote == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PillChip(
                      label: S.shareModeCard,
                      icon: Icons.image_rounded,
                      selected: !_asText,
                      onTap: () => setState(() => _asText = false),
                    ),
                    const SizedBox(width: 8),
                    PillChip(
                      label: S.shareModeText,
                      icon: Icons.notes_rounded,
                      selected: _asText,
                      onTap: () => setState(() => _asText = true),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 18, 32, 14),
                    child: _asText
                        ? _TextPreview(quote: quote)
                        : _CardPreview(
                            cardKey: _cardKey,
                            quote: quote,
                            style: style,
                          ),
                  ),
                ),
                if (!_asText)
                  _StylePicker(
                    quote: quote,
                    selected: style,
                    onSelect: (s) =>
                        ref.read(shareCardStyleProvider.notifier).select(s),
                  ),
              ],
            ),
      bottom: quote == null
          ? null
          : BottomBar(
              child: Builder(
                builder: (context) => PillButton(
                  label: _asText ? S.shareSendText : S.shareSendCard,
                  icon: Icons.ios_share_rounded,
                  onPressed: _busy ? null : () => _send(quote, _origin(context)),
                ),
              ),
            ),
    );
  }
}

/// 보낼 카드 그대로의 미리 보기. 이 RepaintBoundary를 그대로 이미지로 저장한다.
class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.cardKey,
    required this.quote,
    required this.style,
  });

  final GlobalKey cardKey;
  final Quote quote;
  final ShareCardStyle style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: kShareCardSize.aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(
                color: context.hanji.cardDrop,
                offset: const Offset(0, kDrop + 1),
              ),
            ],
          ),
          child: FittedBox(
            child: RepaintBoundary(
              key: cardKey,
              child: ShareCard(quote: quote, style: style),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PuffyCard(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Text(
              keepWords(shareText(quote)),
              style: context.text.bodyLarge,
            ),
          ),
        ),
      ),
    );
  }
}

/// 카드 모양 고르기. 기본 한 줄, 프레스티지 한 줄. 좁은 화면에서는 줄마다 가로로 넘긴다.
class _StylePicker extends StatelessWidget {
  const _StylePicker({
    required this.quote,
    required this.selected,
    required this.onSelect,
  });

  final Quote quote;
  final ShareCardStyle selected;
  final ValueChanged<ShareCardStyle> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    Widget tile(ShareCardStyle s) => _StyleTile(
      quote: quote,
      style: s,
      selected: s == selected,
      onTap: () => onSelect(s),
    );
    Widget group(String title, {required bool prestige}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30, bottom: 4),
          child: Row(
            children: [
              if (prestige) ...[
                Icon(Icons.auto_awesome_rounded, size: 13, color: c.dahong),
                const SizedBox(width: 3),
              ],
              Text(
                title,
                style: context.text.bodySmall?.copyWith(
                  color: prestige ? c.dahong : c.galmukSub,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              for (final s in ShareCardStyle.values)
                if (s.prestige == prestige) tile(s),
            ],
          ),
        ),
      ],
    );

    return Column(
      children: [
        group(S.shareCardBasic, prestige: false),
        const SizedBox(height: 8),
        group(S.shareCardPrestige, prestige: true),
      ],
    );
  }
}

class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.quote,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final Quote quote;
  final ShareCardStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    return Semantics(
      button: true,
      selected: selected,
      label: style.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 70,
                padding: EdgeInsets.all(selected ? 2 : 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected ? c.galmuk : c.line,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(selected ? 10 : 11),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: ShareCard(quote: quote, style: style),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                style.label,
                style: context.text.bodySmall?.copyWith(
                  color: selected ? c.galmuk : c.galmukSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
