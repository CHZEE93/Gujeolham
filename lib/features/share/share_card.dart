import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/decor.dart';
import '../../core/widgets/seal.dart';
import '../../data/database.dart';

/// 카드는 이 크기로 그리고, 화면·썸네일·이미지 저장 때 비율대로 늘리거나 줄인다.
const kShareCardSize = Size(320, 400);

/// 보내기 카드 모양. 기본 카드는 앱 테마와 같은 담백한 구성이고,
/// 프레스티지 카드는 금박·자개처럼 장식을 그려 넣고 명조(고운바탕)로 쓴다.
enum ShareCardStyle {
  theme('지금 테마'),
  hanji('한지'),
  cheongja('청자'),
  meok('먹'),
  jjok('쪽빛'),
  geumbak('금박', prestige: true),
  najeon('자개', prestige: true),
  gungjung('궁중', prestige: true),
  dalbit('달빛', prestige: true),
  bidan('비단', prestige: true);

  const ShareCardStyle(this.label, {this.prestige = false});

  final String label;
  final bool prestige;

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
    this.ornament,
  });

  final Decoration background;
  final Color ink;
  final Color accent;
  final Color seal;
  final Color? sealInk;
  final EdgeInsets padding;

  /// 바탕 위·글자 아래에 그리는 장식. 없으면 구름 코너.
  final CustomPainter? ornament;
}

/// 금박 결. 선·점·낙관에 셰이더로 입힌다.
const _gold = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF8A6A2C),
    Color(0xFFE8CD85),
    Color(0xFFB08A3E),
    Color(0xFFF6E7B0),
    Color(0xFF9A7634),
  ],
  stops: [0, 0.3, 0.5, 0.72, 1],
);

const _goldSolid = Color(0xFFD9BC72);
const _sealRed = Color(0xFFB23A2E);

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
  const prestigePadding = EdgeInsets.fromLTRB(38, 52, 38, 34);

  return switch (style) {
    ShareCardStyle.theme => palette(theme),
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
    ShareCardStyle.geumbak => _Look(
      background: _gradient(const [Color(0xFF2A231C), Color(0xFF14110E)]),
      ink: const Color(0xFFF3E9D2),
      accent: _goldSolid,
      seal: _sealRed,
      padding: prestigePadding,
      ornament: const _GeumbakPainter(),
    ),
    ShareCardStyle.najeon => _Look(
      background: _gradient(const [Color(0xFF1C1E27), Color(0xFF0B0C11)]),
      ink: const Color(0xFFEFEBF4),
      accent: const Color(0xFFC9C3F2),
      seal: _sealRed,
      padding: prestigePadding,
      ornament: const _NajeonPainter(),
    ),
    ShareCardStyle.gungjung => _Look(
      background: _gradient(const [Color(0xFF8A2328), Color(0xFF581317)]),
      ink: const Color(0xFFFBF1DE),
      accent: _goldSolid,
      seal: _goldSolid,
      sealInk: const Color(0xFF581317),
      padding: const EdgeInsets.fromLTRB(38, 62, 38, 48),
      ornament: const _GungjungPainter(),
    ),
    ShareCardStyle.dalbit => _Look(
      background: _gradient(const [Color(0xFF1E3160), Color(0xFF0D1730)]),
      ink: const Color(0xFFF4EDDA),
      accent: _goldSolid,
      seal: const Color(0xFFC9594C),
      padding: const EdgeInsets.fromLTRB(38, 100, 38, 34),
      ornament: const _DalbitPainter(),
    ),
    ShareCardStyle.bidan => _Look(
      background: _gradient(const [
        Color(0xFF3A1431),
        Color(0xFF6E2449),
        Color(0xFF4A1A3C),
      ]),
      ink: const Color(0xFFFAEEE6),
      accent: _goldSolid,
      seal: _goldSolid,
      sealInk: const Color(0xFF4A1A3C),
      padding: prestigePadding,
      ornament: const _BidanPainter(),
    ),
  };
}

/// 한글은 글자마다 줄이 바뀔 수 있어 '사람/이다'처럼 낱말이 갈린다.
/// 낱말 안의 글자 사이에 단어 결합자(U+2060)를 넣어 띄어쓰기에서만 줄을 바꾼다.
/// 한 낱말이 한 줄보다 길면 카드가 글자를 줄여 맞춘다.
String keepWords(String text) => text.replaceAllMapped(
  RegExp(r'\S{2,}'),
  (m) => m[0]!.characters.join('⁠'),
);

/// 보내는 구절 카드. [kShareCardSize] 크기로 그린다.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.quote, required this.style});

  final Quote quote;
  final ShareCardStyle style;

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
      return prestige ? GoogleFonts.gowunBatang(textStyle: base) : juaStyle(base);
    }

    final seal = Seal(
      text: S.sealAppName,
      size: prestige ? 26 : 30,
      color: look.seal,
      textColor: look.sealInk ?? const Color(0xFFFBF7EE),
      angle: (prestige ? -4 : -6) * math.pi / 180,
    );

    final quoteText = Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: kShareCardSize.width - look.padding.horizontal,
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
            style: prestige
                ? font(12, sub)
                : dodumStyle(TextStyle(fontSize: 12.5, color: sub)),
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
              const SizedBox(height: 12),
              seal,
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
      size: kShareCardSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius),
        child: DecoratedBox(
          decoration: look.background,
          child: Stack(
            children: [
              Positioned.fill(
                child: look.ornament == null
                    ? CloudCorners(layers: 1, color: look.accent)
                    : CustomPaint(painter: look.ornament),
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

// ── 프레스티지 장식 ─────────────────────────────────────────────

Paint _goldStroke(Rect bounds, double width) => Paint()
  ..shader = _gold.createShader(bounds)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width;

Paint _goldFill(Rect bounds) => Paint()..shader = _gold.createShader(bounds);

RRect _frame(Size size, double inset, double radius) => RRect.fromRectAndRadius(
  (Offset.zero & size).deflate(inset),
  Radius.circular(radius),
);

/// 흩뿌린 금가루·별. 같은 카드는 늘 같은 자리에 찍히도록 씨앗을 고정한다.
void _scatter(
  Canvas canvas,
  Size size, {
  required int seed,
  required int count,
  required Paint Function(double alpha) paint,
  double maxRadius = 1.3,
}) {
  final r = math.Random(seed);
  for (var i = 0; i < count; i++) {
    final p = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
    canvas.drawCircle(
      p,
      0.35 + r.nextDouble() * maxRadius,
      paint(0.18 + r.nextDouble() * 0.55),
    );
  }
}

/// 금박: 겹 테두리 + 모서리 꺾쇠 + 위아래 마름모 + 금가루.
class _GeumbakPainter extends CustomPainter {
  const _GeumbakPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    _scatter(
      canvas,
      size,
      seed: 7,
      count: 70,
      paint: (a) => Paint()..color = _goldSolid.withValues(alpha: a * 0.6),
    );
    canvas.drawRRect(_frame(size, 12, 14), _goldStroke(bounds, 0.9));
    canvas.drawRect(bounds.deflate(19), _goldStroke(bounds, 1.8));

    // 모서리 꺾쇠: 바깥으로 한 번 더 꺾인 ㄱ자 두 겹.
    final stroke = _goldStroke(bounds, 1.4);
    for (final (sx, sy) in [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]) {
      canvas.save();
      canvas.translate(sx > 0 ? 0 : size.width, sy > 0 ? 0 : size.height);
      canvas.scale(sx, sy);
      final path = Path()
        ..moveTo(25, 52)
        ..lineTo(25, 25)
        ..lineTo(52, 25)
        ..moveTo(31, 42)
        ..lineTo(31, 31)
        ..lineTo(42, 31);
      canvas.drawPath(path, stroke);
      canvas.drawRect(const Rect.fromLTWH(34.5, 34.5, 4, 4), _goldFill(bounds));
      canvas.restore();
    }

    // 위·아래 가운데 마름모.
    for (final y in [19.0, size.height - 19]) {
      canvas.save();
      canvas.translate(size.width / 2, y);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(const Rect.fromLTWH(-5, -5, 10, 10), Paint()..color = const Color(0xFF1B1713));
      canvas.drawRect(const Rect.fromLTWH(-5, -5, 10, 10), _goldStroke(bounds, 1.4));
      canvas.drawRect(const Rect.fromLTWH(-2, -2, 4, 4), _goldFill(bounds));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GeumbakPainter old) => false;
}

/// 자개 결: 보는 각도마다 색이 바뀌는 무지갯빛.
const _nacre = SweepGradient(
  colors: [
    Color(0xFFF7C6D9),
    Color(0xFFB9E4E0),
    Color(0xFFC9C3F2),
    Color(0xFFF5E6B8),
    Color(0xFFA8D8F0),
    Color(0xFFF7C6D9),
  ],
);

/// 자개: 옻칠 바탕에 매화 가지와 꽃잎을 자개로 박아 넣는다.
class _NajeonPainter extends CustomPainter {
  const _NajeonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final nacre = Paint()..shader = _nacre.createShader(bounds);
    final nacreLine = Paint()
      ..shader = _nacre.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(_frame(size, 13, 14), nacreLine);
    canvas.drawRRect(
      _frame(size, 17, 11),
      nacreLine..color = Colors.white.withValues(alpha: 0.3),
    );

    void blossom(Offset c, double r, double turn) {
      for (var i = 0; i < 5; i++) {
        final a = turn + i * 2 * math.pi / 5;
        canvas.save();
        canvas.translate(c.dx + math.cos(a) * r * 0.55, c.dy + math.sin(a) * r * 0.55);
        canvas.rotate(a);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: r * 0.95, height: r * 0.72),
          Paint()
            ..shader = _nacre.createShader(bounds)
            ..color = Colors.white.withValues(alpha: 0.85),
        );
        canvas.restore();
      }
      canvas.drawCircle(c, r * 0.18, Paint()..color = const Color(0xFFE8CD85));
    }

    // 왼쪽 위에서 내려오는 가지, 오른쪽 아래에서 올라오는 가지.
    final branch = Paint()
      ..shader = _nacre.createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    for (final flip in [false, true]) {
      canvas.save();
      if (flip) {
        canvas.translate(size.width, size.height);
        canvas.rotate(math.pi);
      }
      canvas.drawPath(
        Path()
          ..moveTo(17, 70)
          ..quadraticBezierTo(46, 54, 62, 30)
          ..moveTo(42, 52)
          ..quadraticBezierTo(70, 52, 96, 40),
        branch,
      );
      blossom(const Offset(62, 30), 12, 0.3);
      blossom(const Offset(96, 40), 9, 1.1);
      blossom(const Offset(34, 58), 7, 0.7);
      canvas.drawCircle(const Offset(80, 30), 2.4, nacre);
      canvas.drawCircle(const Offset(110, 50), 1.8, nacre);
      canvas.restore();
    }

    // 잘게 부순 자개 조각.
    final r = math.Random(11);
    for (var i = 0; i < 26; i++) {
      final p = Offset(
        24 + r.nextDouble() * (size.width - 48),
        24 + r.nextDouble() * (size.height - 48),
      );
      final s = 1.2 + r.nextDouble() * 2.2;
      final shard = Path()
        ..moveTo(p.dx, p.dy - s)
        ..lineTo(p.dx + s, p.dy + s * 0.6)
        ..lineTo(p.dx - s * 0.8, p.dy + s * 0.4)
        ..close();
      canvas.drawPath(shard, nacre..color = Colors.white.withValues(alpha: 0.25 + r.nextDouble() * 0.3));
    }
  }

  @override
  bool shouldRepaint(_NajeonPainter old) => false;
}

/// 궁중: 홍색 바탕에 금테 두 겹, 위아래 단청 띠, 금빛 구름 코너.
class _GungjungPainter extends CustomPainter {
  const _GungjungPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(_frame(size, 10, 15), _goldStroke(bounds, 2.2));
    canvas.drawRRect(_frame(size, 15, 11), _goldStroke(bounds, 0.8));

    // 단청 띠: 원(초록 점) ― 마름모(청) 번갈아.
    const green = Color(0xFF3F8A6B);
    const blue = Color(0xFF2E5C8A);
    for (final y in [30.0, size.height - 30]) {
      final band = Rect.fromLTRB(24, y - 7, size.width - 24, y + 7);
      canvas.drawLine(band.topLeft, band.topRight, _goldStroke(bounds, 0.8));
      canvas.drawLine(band.bottomLeft, band.bottomRight, _goldStroke(bounds, 0.8));
      const step = 17.0;
      final n = (band.width / step).floor();
      final start = band.left + (band.width - (n - 1) * step) / 2;
      for (var i = 0; i < n; i++) {
        final c = Offset(start + i * step, y);
        if (i.isEven) {
          canvas.drawCircle(c, 4.2, _goldFill(bounds));
          canvas.drawCircle(c, 2.2, Paint()..color = green);
        } else {
          canvas.save();
          canvas.translate(c.dx, c.dy);
          canvas.rotate(math.pi / 4);
          canvas.drawRect(const Rect.fromLTWH(-3, -3, 6, 6), _goldFill(bounds));
          canvas.drawRect(const Rect.fromLTWH(-1.5, -1.5, 3, 3), Paint()..color = blue);
          canvas.restore();
        }
      }
    }

    // 금빛 구름 코너(앱의 구름 코너 선을 금색으로).
    final stroke = _goldStroke(bounds, 1.4)..strokeCap = StrokeCap.round;
    for (final (sx, sy) in [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]) {
      canvas.save();
      canvas.translate(sx > 0 ? 0 : size.width, sy > 0 ? 0 : size.height);
      canvas.scale(sx, sy);
      canvas.translate(24, 46);
      canvas.drawPath(
        Path()
          ..moveTo(26, 0)
          ..lineTo(10, 0)
          ..arcToPoint(const Offset(0, 10), radius: const Radius.circular(10), clockwise: false)
          ..lineTo(0, 26),
        stroke,
      );
      canvas.drawCircle(const Offset(8, 8), 2, stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GungjungPainter old) => false;
}

/// 달빛: 남색 밤하늘에 보름달과 별, 아래로 먼 산 능선.
class _DalbitPainter extends CustomPainter {
  const _DalbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    _scatter(
      canvas,
      size,
      seed: 3,
      count: 46,
      maxRadius: 0.9,
      paint: (a) => Paint()..color = Colors.white.withValues(alpha: a),
    );

    // 반짝이는 별 몇 개.
    final sparkle = Paint()..color = const Color(0xFFF6E7B0);
    for (final (p, s) in [
      (const Offset(54, 64), 5.0),
      (const Offset(118, 34), 3.5),
      (Offset(size.width - 46, 150), 3.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - s)
          ..quadraticBezierTo(p.dx, p.dy, p.dx + s, p.dy)
          ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s)
          ..quadraticBezierTo(p.dx, p.dy, p.dx - s, p.dy)
          ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s),
        sparkle,
      );
    }

    // 보름달: 번진 달무리 + 달.
    final moon = Offset(size.width - 74, 64);
    canvas.drawCircle(
      moon,
      70,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF0C8).withValues(alpha: 0.32),
            const Color(0xFFFFF0C8).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: moon, radius: 70)),
    );
    canvas.drawCircle(
      moon,
      26,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFF8E2), Color(0xFFEBD69C)],
        ).createShader(Rect.fromCircle(center: moon, radius: 26)),
    );
    final crater = Paint()..color = const Color(0xFFD9C185).withValues(alpha: 0.45);
    canvas.drawCircle(moon + const Offset(-8, 5), 4.5, crater);
    canvas.drawCircle(moon + const Offset(7, -7), 3, crater);
    canvas.drawCircle(moon + const Offset(9, 9), 2.2, crater);

    // 먼 산 두 겹.
    final h = size.height;
    final w = size.width;
    canvas.drawPath(
      Path()
        ..moveTo(0, h - 62)
        ..quadraticBezierTo(w * 0.22, h - 96, w * 0.42, h - 66)
        ..quadraticBezierTo(w * 0.62, h - 40, w * 0.8, h - 78)
        ..quadraticBezierTo(w * 0.92, h - 96, w, h - 70)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFF162447).withValues(alpha: 0.85),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h - 34)
        ..quadraticBezierTo(w * 0.3, h - 64, w * 0.55, h - 38)
        ..quadraticBezierTo(w * 0.78, h - 18, w, h - 46)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0xFF0A1226).withValues(alpha: 0.9),
    );

    canvas.drawRRect(_frame(size, 12, 14), _goldStroke(bounds, 0.9));
  }

  @override
  bool shouldRepaint(_DalbitPainter old) => false;
}

/// 비단: 자줏빛 비단에 사선 윤기와 청해파(물결) 무늬, 금테.
class _BidanPainter extends CustomPainter {
  const _BidanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    // 비단 윤기: 사선으로 지나가는 옅은 빛.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-1, -0.6),
          end: const Alignment(1, 0.6),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.25, 0.45, 0.65],
        ).createShader(bounds),
    );

    // 청해파: 아래쪽에 겹겹이 놓인 반원 물결.
    canvas.save();
    canvas.clipRRect(_frame(size, 14, 14));
    final wave = Paint()
      ..color = _goldSolid.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    const r = 22.0;
    for (var row = 0; row < 4; row++) {
      final y = size.height - 8 - row * r * 0.55;
      final shift = row.isOdd ? r : 0.0;
      for (var x = -r + shift; x < size.width + r; x += r * 2) {
        final c = Offset(x, y);
        canvas.drawCircle(c, r + 2, Paint()..color = const Color(0xFF4A1A3C).withValues(alpha: 0.55));
        for (final k in [1.0, 0.72, 0.44]) {
          canvas.drawCircle(c, r * k, wave);
        }
      }
    }
    canvas.restore();

    canvas.drawRRect(_frame(size, 12, 14), _goldStroke(bounds, 1.6));
    canvas.drawRRect(_frame(size, 17, 10), _goldStroke(bounds, 0.6));

    // 위 가운데 매듭 장식.
    final top = Offset(size.width / 2, 12);
    canvas.drawCircle(top, 6, Paint()..color = const Color(0xFF3A1431));
    canvas.drawCircle(top, 6, _goldStroke(bounds, 1.2));
    canvas.drawCircle(top, 2.4, _goldFill(bounds));
  }

  @override
  bool shouldRepaint(_BidanPainter old) => false;
}
