import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// 구름 코너 장식 — 회문을 둥글게 푼 선을 네 모서리에 둔다.
/// 홈·상세는 [layers] 2(2겹+점), 나머지 화면은 1(1겹+점).
class CloudCorners extends StatelessWidget {
  const CloudCorners({
    super.key,
    this.layers = 1,
    this.size = 46,
    this.inset = 10,
    this.color,
  });

  final int layers;
  final double size;
  final double inset;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final painter = _CloudCornerPainter(
      color: color ?? context.hanji.yeongal,
      layers: layers,
    );
    Widget corner(double sx, double sy) => Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(sx, sy, 1),
      child: CustomPaint(size: Size.square(size), painter: painter),
    );

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: Stack(
          children: [
            Align(alignment: Alignment.topLeft, child: corner(1, 1)),
            Align(alignment: Alignment.topRight, child: corner(-1, 1)),
            Align(alignment: Alignment.bottomLeft, child: corner(1, -1)),
            Align(alignment: Alignment.bottomRight, child: corner(-1, -1)),
          ],
        ),
      ),
    );
  }
}

/// 왼쪽 위 모서리 기준으로 그린다(나머지는 뒤집어서 사용).
class _CloudCornerPainter extends CustomPainter {
  const _CloudCornerPainter({required this.color, required this.layers});

  final Color color;
  final int layers;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, s * 0.03)
      ..strokeCap = StrokeCap.round;

    void corner(double o, double len, double r) {
      final path = Path()
        ..moveTo(len, o)
        ..lineTo(o + r, o)
        ..arcToPoint(Offset(o, o + r), radius: Radius.circular(r), clockwise: false)
        ..lineTo(o, len);
      canvas.drawPath(path, stroke);
    }

    corner(0, s, s * 0.36);
    var dotAt = s * 0.30;
    if (layers >= 2) {
      final o = s * 0.14;
      corner(o, s * 0.80, s * 0.24);
      dotAt = s * 0.40;
    }
    canvas.drawCircle(Offset(dotAt, dotAt), s * 0.065, stroke);
  }

  @override
  bool shouldRepaint(_CloudCornerPainter old) =>
      old.color != color || old.layers != layers;
}

/// 통통 노리개 — 동그란 장식 + 동그란 매듭 + 굵은 술. 살랑살랑 흔들린다.
class Norigae extends StatefulWidget {
  const Norigae({super.key, this.height = 92, this.swing = true});

  final double height;
  final bool swing;

  @override
  State<Norigae> createState() => _NorigaeState();
}

class _NorigaeState extends State<Norigae> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.swing) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final h = widget.height;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.rotate(
          alignment: Alignment.topCenter,
          angle: (Curves.easeInOut.transform(_c.value) - 0.5) * 0.08,
          child: child,
        ),
        child: CustomPaint(
          size: Size(h * 0.34, h),
          painter: _NorigaePainter(c),
        ),
      ),
    );
  }
}

class _NorigaePainter extends CustomPainter {
  const _NorigaePainter(this.c);

  final HanjiColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final cx = size.width / 2;
    final u = h / 100; // 100 단위 좌표계

    final cord = Paint()
      ..color = c.galmuk
      ..strokeWidth = 1.6 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, 0), Offset(cx, 16 * u), cord);

    // 동그란 장식: 갈먹 고리 + 종이 바탕 + 다홍 점
    final ringCenter = Offset(cx, 27 * u);
    canvas.drawCircle(ringCenter, 11 * u, Paint()..color = c.galmuk);
    canvas.drawCircle(ringCenter, 7.2 * u, Paint()..color = c.paper);
    canvas.drawCircle(ringCenter, 3.6 * u, Paint()..color = c.dahong);

    canvas.drawLine(Offset(cx, 38 * u), Offset(cx, 46 * u), cord);

    // 동그란 매듭
    canvas.drawCircle(Offset(cx, 50 * u), 4.6 * u, Paint()..color = c.dahong);

    // 술 머리(갈먹 띠)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 58 * u), width: 9 * u, height: 5 * u),
        Radius.circular(1.6 * u),
      ),
      Paint()..color = c.galmuk,
    );

    // 굵은 술: 아래로 살짝 퍼지는 둥근 다홍 덩어리
    final tassel = Path()
      ..moveTo(cx - 4 * u, 60.5 * u)
      ..lineTo(cx + 4 * u, 60.5 * u)
      ..quadraticBezierTo(cx + 6.5 * u, 80 * u, cx + 6 * u, 96 * u)
      ..quadraticBezierTo(cx, 100 * u, cx - 6 * u, 96 * u)
      ..quadraticBezierTo(cx - 6.5 * u, 80 * u, cx - 4 * u, 60.5 * u)
      ..close();
    canvas.drawPath(tassel, Paint()..color = c.dahong);
    final fringe = Paint()
      ..color = c.dahongDrop.withValues(alpha: 0.55)
      ..strokeWidth = 0.9 * u
      ..strokeCap = StrokeCap.round;
    for (final dx in [-2.5, 0.0, 2.5]) {
      canvas.drawLine(
        Offset(cx + dx * u, 66 * u),
        Offset(cx + dx * 1.5 * u, 93 * u),
        fringe,
      );
    }
  }

  @override
  bool shouldRepaint(_NorigaePainter old) => old.c != c;
}
