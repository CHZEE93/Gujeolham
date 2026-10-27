import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'hami.dart';

/// 둥근 낙관. [text]가 여러 글자면 세로로 쓴다.
class Seal extends StatelessWidget {
  const Seal({
    super.key,
    this.text = S.sealDam,
    this.size = 30,
    this.color,
    this.angle = 0,
  });

  final String text;
  final double size;
  final Color? color;

  /// 라디안. 가이드: ±4~7°로 삐뚤게.
  final double angle;

  /// 인덱스마다 다홍/옥/치자를 번갈아, 기울기도 ±4~7° 사이에서 번갈아.
  factory Seal.forIndex(BuildContext context, int index, {double size = 30}) {
    final colors = context.hanji.sealColors;
    const degrees = [-6.0, 4.5, -4.0, 7.0, -5.5, 5.0];
    return Seal(
      size: size,
      color: colors[index % colors.length],
      angle: degrees[index % degrees.length] * math.pi / 180,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final chars = text.characters.toList();
    final vertical = chars.length > 1;
    final radius = (kSealRadius * size / 40).clamp(7.0, 12.0);

    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: vertical ? size * (0.62 + 0.42 * chars.length) : size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color ?? c.dahong,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          vertical ? chars.join('\n') : text,
          textAlign: TextAlign.center,
          style: juaStyle(
            TextStyle(
              color: c.paper,
              fontSize: size * (vertical ? 0.42 : 0.5),
              height: vertical ? 1.0 : 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 마음에 새긴 구절 표시. 새기면 0.4초 동안 꾹 찍히고(scale+fade), 거두면 사라진다.
class CherishStamp extends StatelessWidget {
  const CherishStamp({super.key, required this.cherished, this.size = 30});

  final bool cherished;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.8, end: 1).animate(a),
          child: child,
        ),
      ),
      child: cherished
          ? Seal(
              key: const ValueKey(true),
              text: S.sealCherished,
              size: size,
              angle: 5 * math.pi / 180,
            )
          : SizedBox(key: const ValueKey(false), width: size),
    );
  }
}

/// 저장 완료 연출: 함이가 뚜껑을 톡 열며 웃고, 낙관이 0.4초 동안 찍힌다(scale+fade).
class SaveCelebration extends StatefulWidget {
  const SaveCelebration({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SaveCelebration> createState() => _SaveCelebrationState();
}

class _SaveCelebrationState extends State<SaveCelebration> {
  bool _stamp = false;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    return ColoredBox(
      color: c.hanji.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 170,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  HamiCheer(
                    size: 150,
                    onDone: () => setState(() => _stamp = true),
                  ),
                  if (_stamp)
                    Positioned(
                      right: 0,
                      bottom: 8,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        onEnd: widget.onDone,
                        builder: (context, t, child) => Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 1.8 - 0.8 * t,
                            child: child,
                          ),
                        ),
                        child: Seal(
                          size: 52,
                          angle: -6 * math.pi / 180,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _stamp ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Text(S.saved, style: context.text.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}
