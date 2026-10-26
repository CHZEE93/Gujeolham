import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme.dart';

/// 마스코트 '함이' — 둥근 함 + 뚜껑 + 붉은 매듭 손잡이 + 볼터치.
/// [lidOpen] 0이면 닫힘, 1이면 뚜껑이 톡 열린 상태. [smile] 0이면 동그란 눈, 1이면 웃는 눈.
class Hami extends StatelessWidget {
  const Hami({super.key, this.size = 120, this.lidOpen = 0, this.smile = 0});

  final double size;
  final double lidOpen;
  final double smile;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: HamiPainter(
        colors: context.hanji,
        lidOpen: lidOpen,
        smile: smile,
      ),
    );
  }
}

class HamiPainter extends CustomPainter {
  const HamiPainter({
    required this.colors,
    this.lidOpen = 0,
    this.smile = 0,
  });

  final HanjiColors colors;
  final double lidOpen;
  final double smile;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = colors;
    final body = Color.lerp(c.galmuk, c.yeongal, 0.28)!;
    final white = c.paper;

    // 몸통
    final bodyRect = Rect.fromLTRB(0.16 * s, 0.40 * s, 0.84 * s, 0.86 * s);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bodyRect,
        topLeft: Radius.circular(0.05 * s),
        topRight: Radius.circular(0.05 * s),
        bottomLeft: Radius.circular(0.16 * s),
        bottomRight: Radius.circular(0.16 * s),
      ),
      Paint()..color = body,
    );

    // 볼터치
    final cheek = Paint()..color = c.dahong.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(0.29 * s, 0.66 * s), 0.040 * s, cheek);
    canvas.drawCircle(Offset(0.71 * s, 0.66 * s), 0.040 * s, cheek);

    // 눈: 동그란 눈 → 웃는 눈(^ ^)
    final eyeY = 0.58 * s;
    for (final ex in [0.39 * s, 0.61 * s]) {
      if (smile < 0.5) {
        final r = 0.036 * s * (1 - smile * 0.6);
        canvas.drawCircle(Offset(ex, eyeY), r, Paint()..color = white);
      } else {
        final arc = Paint()
          ..color = white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.028 * s
          ..strokeCap = StrokeCap.round;
        final w = 0.05 * s;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(ex, eyeY + 0.012 * s), width: w * 1.6, height: w * 1.5),
          math.pi * 1.1,
          math.pi * 0.8,
          false,
          arc,
        );
      }
    }

    // 입: 웃을수록 크게
    final mouth = Paint()
      ..color = white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.026 * s
      ..strokeCap = StrokeCap.round;
    final mw = lerpDouble(0.08, 0.13, smile)! * s;
    final mh = lerpDouble(0.05, 0.10, smile)! * s;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0.5 * s, 0.665 * s), width: mw, height: mh),
      math.pi * 0.12,
      math.pi * 0.76,
      false,
      mouth,
    );

    // 뚜껑 + 매듭 손잡이: 톡 튀어 오르며 오른쪽으로 살짝 젖혀진다
    canvas.save();
    final pivot = Offset(0.12 * s, 0.42 * s);
    canvas.translate(pivot.dx, pivot.dy - lidOpen * 0.10 * s);
    canvas.rotate(-lidOpen * 0.32);
    canvas.translate(-pivot.dx, -pivot.dy);

    final lidRect = Rect.fromLTRB(0.10 * s, 0.28 * s, 0.90 * s, 0.43 * s);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        lidRect,
        topLeft: Radius.circular(0.09 * s),
        topRight: Radius.circular(0.09 * s),
        bottomLeft: Radius.circular(0.03 * s),
        bottomRight: Radius.circular(0.03 * s),
      ),
      Paint()..color = c.galmuk,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0.43 * s, 0.17 * s, 0.57 * s, 0.30 * s),
        Radius.circular(0.045 * s),
      ),
      Paint()..color = c.dahong,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(HamiPainter old) =>
      old.lidOpen != lidOpen || old.smile != smile || old.colors != colors;
}

/// 저장 완료 등에서 쓰는 '뚜껑이 톡 열리며 웃는' 애니메이션.
class HamiCheer extends StatefulWidget {
  const HamiCheer({super.key, this.size = 140, this.onDone});

  final double size;
  final VoidCallback? onDone;

  @override
  State<HamiCheer> createState() => _HamiCheerState();
}

class _HamiCheerState extends State<HamiCheer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _lid = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.8, curve: Curves.elasticOut),
  );
  late final Animation<double> _smile = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, -math.sin(_c.value * math.pi) * widget.size * 0.05),
        child: Hami(
          size: widget.size,
          lidOpen: _lid.value * 0.8,
          smile: _smile.value,
        ),
      ),
    );
  }
}
