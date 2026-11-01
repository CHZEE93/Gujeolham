import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/decor.dart';
import '../../core/widgets/seal.dart';
import '../../data/database.dart';

/// 기본 카드는 이 크기로 그리고, 화면·썸네일·이미지 저장 때 비율대로 늘리거나 줄인다.
const kShareCardSize = Size(320, 400);

/// 그림 편지지 카드 크기. 편지지 그림(1055×1491)과 같은 비율이라 테두리가 잘리지 않는다.
const kPaperCardSize = Size(320, 452);

/// 프레스티지 편지지 한 장: 그림 파일과 글을 놓을 빈자리.
/// 편지지마다 그림 속 낙관이 있어 앱 낙관은 찍지 않는다.
class _Paper {
  const _Paper(
    this.file,
    this.padding, {
    this.size = kPaperCardSize,
    this.cute = false,
  });

  final String file;

  /// 그림을 피해 글을 놓는 자리. [size] 기준.
  final EdgeInsets padding;

  /// 카드 크기. 그림과 같은 비율로 잡는다.
  final Size size;

  /// 동물 편지지. 둥근 글씨(Jua)에 고동색으로 쓴다.
  final bool cute;

  String get asset => 'assets/letter_papers/$file.jpg';
}

/// 동물 편지지 크기: 위 두 장(582×713)과 아래 세 장(383×552)의 비율.
const _wideAnimal = Size(320, 392);
const _tallAnimal = Size(320, 461);

/// 보내기 카드 모양. 기본 카드는 앱 테마와 같은 담백한 구성이고,
/// 프레스티지 카드는 그림 편지지 위에 쓴다(수묵 편지지는 명조, 동물 편지지는 둥근 글씨).
enum ShareCardStyle {
  theme('지금 테마'),
  hanji('한지'),
  cheongja('청자'),
  meok('먹'),
  jjok('쪽빛'),
  maehwa('매화', paper: _Paper('maehwa', EdgeInsets.fromLTRB(40, 60, 112, 52))),
  sansu('산수', paper: _Paper('sansu', EdgeInsets.fromLTRB(56, 112, 40, 56))),
  seochaek('서책', paper: _Paper('seochaek', EdgeInsets.fromLTRB(40, 56, 40, 160))),
  mongnyeon('목련', paper: _Paper('mongnyeon', EdgeInsets.fromLTRB(36, 56, 100, 150))),
  hak('학', paper: _Paper('hak', EdgeInsets.fromLTRB(56, 88, 40, 60))),
  baekja('백자', paper: _Paper('baekja', EdgeInsets.fromLTRB(56, 70, 48, 150))),
  moran('모란', paper: _Paper('moran', EdgeInsets.fromLTRB(40, 56, 90, 180))),
  gukhwa('국화', paper: _Paper('gukhwa', EdgeInsets.fromLTRB(44, 56, 64, 140))),
  daenamu('대나무', paper: _Paper('daenamu', EdgeInsets.fromLTRB(36, 56, 130, 52))),
  nancho('난초', paper: _Paper('nancho', EdgeInsets.fromLTRB(40, 56, 56, 140))),
  bomnal('봄날', paper: _Paper('bomnal', EdgeInsets.fromLTRB(36, 162, 34, 48), size: _wideAnimal, cute: true)),
  dalbam('달밤', paper: _Paper('dalbam', EdgeInsets.fromLTRB(34, 162, 35, 52), size: _wideAnimal, cute: true)),
  buchae('부채', paper: _Paper('buchae', EdgeInsets.fromLTRB(34, 196, 32, 54), size: _tallAnimal, cute: true)),
  seollal('설날', paper: _Paper('seollal', EdgeInsets.fromLTRB(34, 196, 34, 70), size: _tallAnimal, cute: true)),
  danpung('단풍', paper: _Paper('danpung', EdgeInsets.fromLTRB(34, 196, 34, 54), size: _tallAnimal, cute: true));

  const ShareCardStyle(this.label, {_Paper? paper}) : _paper = paper; // ignore: prefer_initializing_formals

  final String label;
  final _Paper? _paper;

  bool get prestige => _paper != null;

  /// 둥근 글씨로 쓰는 카드(기본 카드와 동물 편지지).
  bool get rounded => _paper?.cute ?? true;

  /// 이 모양의 카드 크기.
  Size get size => _paper?.size ?? kShareCardSize;

  static ShareCardStyle byName(String? name) => ShareCardStyle.values
      .firstWhere((s) => s.name == name, orElse: () => ShareCardStyle.theme);
}

/// 카드 한 장의 색·장식.
class _Look {
  const _Look({
    required this.background,
    required this.ink,
    required this.accent,
    required this.seal,
    this.sealInk,
    this.padding = const EdgeInsets.fromLTRB(32, 44, 32, 28),
    this.paper,
  });

  final Decoration background;
  final Color ink;
  final Color accent;
  final Color seal;
  final Color? sealInk;
  final EdgeInsets padding;

  /// 바탕에 까는 편지지 그림. 없으면 구름 코너.
  final String? paper;
}

/// 편지지 위 글씨는 먹빛, 장식선은 편지지 테두리와 같은 금빛.
const _paperInk = Color(0xFF3B332C);
const _paperGold = Color(0xFFB8975A);
const _sealRed = Color(0xFFB23A2E);

/// 동물 편지지 글씨는 그림 선과 같은 고동색, 장식선은 살구빛.
const _cuteInk = Color(0xFF5B4535);
const _cuteAccent = Color(0xFFD9A07E);

BoxDecoration _flat(Color c) => BoxDecoration(color: c);

BoxDecoration _gradient(List<Color> colors) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  ),
);

_Look _lookFor(ShareCardStyle style, HanjiColors theme) {
  _Look palette(HanjiColors c) => _Look(
    background: _flat(c.hanji),
    ink: c.galmuk,
    accent: c.yeongal,
    seal: c.dahong,
    sealInk: c.paper,
  );

  final paper = style._paper;
  if (paper != null) {
    return _Look(
      background: _flat(const Color(0xFFF3EBDD)),
      ink: paper.cute ? _cuteInk : _paperInk,
      accent: paper.cute ? _cuteAccent : _paperGold,
      seal: _sealRed,
      padding: paper.padding,
      paper: paper.asset,
    );
  }

  return switch (style) {
    ShareCardStyle.hanji => palette(AppPalette.hanji.colors),
    ShareCardStyle.cheongja => _Look(
      background: _gradient(const [Color(0xFFE6EFE8), Color(0xFFD3E3D9)]),
      ink: const Color(0xFF2E4A42),
      accent: const Color(0xFF8FB0A2),
      seal: const Color(0xFFC9594C),
    ),
    ShareCardStyle.meok => _Look(
      background: _gradient(const [Color(0xFF332E2A), Color(0xFF221E1B)]),
      ink: const Color(0xFFF1EADC),
      accent: const Color(0xFF7A6F63),
      seal: const Color(0xFFC9594C),
    ),
    ShareCardStyle.jjok => _Look(
      background: _gradient(const [Color(0xFF34497A), Color(0xFF243559)]),
      ink: const Color(0xFFF3EEE2),
      accent: const Color(0xFF7D91B8),
      seal: const Color(0xFFE0B457),
      sealInk: const Color(0xFF243559),
    ),
    _ => palette(theme),
  };
}

/// 한글은 글자마다 줄이 바뀔 수 있어 '사람/이다'처럼 낱말이 갈린다.
/// 낱말 안의 글자 사이에 단어 결합자(U+2060)를 넣어 띄어쓰기에서만 줄을 바꾼다.
/// 한 낱말이 한 줄보다 길면 카드가 글자를 줄여 맞춘다.
String keepWords(String text) => text.replaceAllMapped(
  RegExp(r'\S{2,}'),
  (m) => m[0]!.characters.join('⁠'),
);

/// 보내는 구절 카드. [ShareCardStyle.size] 크기로 그린다.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.quote,
    required this.style,
    this.thumbnail = false,
  });

  final Quote quote;
  final ShareCardStyle style;

  /// 작은 고르기 칸에 그릴 때. 편지지 그림을 작게 풀어 메모리를 아낀다.
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final look = _lookFor(style, context.hanji);
    final prestige = style.prestige;
    final sub = look.ink.withValues(alpha: 0.68);
    final source = [
      ?quote.author,
      if (quote.page != null) S.pageSuffix(quote.page!),
    ].join(' · ');

    TextStyle font(double size, Color color, {double height = 1.4}) {
      final base = TextStyle(fontSize: size, color: color, height: height);
      return style.rounded ? juaStyle(base) : GoogleFonts.gowunBatang(textStyle: base);
    }

    final seal = Seal(
      text: S.sealAppName,
      size: 30,
      color: look.seal,
      textColor: look.sealInk ?? const Color(0xFFFBF7EE),
      angle: -6 * math.pi / 180,
    );

    final quoteText = Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: style.size.width - look.padding.horizontal,
            ),
            child: Text(
              keepWords(quote.content),
              textAlign: prestige ? TextAlign.center : TextAlign.start,
              style: font(prestige ? 19 : 20, look.ink, height: prestige ? 1.8 : 1.6),
            ),
          ),
        ),
      ),
    );

    final title = quote.bookTitle == null
        ? null
        : Text(
            quote.bookTitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: prestige ? TextAlign.center : TextAlign.start,
            style: font(prestige ? 14 : 15, look.ink),
          );
    final sourceText = source.isEmpty
        ? null
        : Text(
            source,
            textAlign: prestige ? TextAlign.center : TextAlign.start,
            style: style.rounded
                ? dodumStyle(TextStyle(fontSize: 12.5, color: sub))
                : font(12, sub),
          );

    final content = prestige
        ? Column(
            children: [
              quoteText,
              const SizedBox(height: 14),
              _Flourish(color: look.accent),
              const SizedBox(height: 10),
              ?title,
              ?sourceText,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              quoteText,
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [?title, ?sourceText],
                    ),
                  ),
                  const SizedBox(width: 12),
                  seal,
                ],
              ),
            ],
          );

    return SizedBox.fromSize(
      size: style.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius),
        child: DecoratedBox(
          decoration: look.background,
          child: Stack(
            children: [
              Positioned.fill(
                child: look.paper == null
                    ? CloudCorners(layers: 1, color: look.accent)
                    : Image.asset(
                        look.paper!,
                        fit: BoxFit.fill,
                        cacheWidth: thumbnail ? 180 : null,
                        gaplessPlayback: true,
                      ),
              ),
              Padding(padding: look.padding, child: content),
            ],
          ),
        ),
      ),
    );
  }
}

/// 프레스티지 카드의 구절과 출처 사이 장식: 가는 선 ― ◆ ― 가는 선.
class _Flourish extends StatelessWidget {
  const _Flourish({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(width: 34, height: 0.8, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(),
        const SizedBox(width: 6),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(width: 5, height: 5, color: color),
        ),
        const SizedBox(width: 6),
        line(),
      ],
    );
  }
}

