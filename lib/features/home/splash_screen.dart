import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/decor.dart';
import '../../core/widgets/hami.dart';

/// 함이가 뚜껑을 열며 인사하는 스플래시.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final Animation<double> _lid = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.15, 0.55, curve: Curves.elasticOut),
  );
  late final Animation<double> _smile = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
  );
  late final Animation<double> _title = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: SafeArea(child: CloudCorners(layers: 2)),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hami(size: 150, lidOpen: _lid.value * 0.8, smile: _smile.value),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: _title.value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - _title.value) * 12),
                      child: Column(
                        children: [
                          Text(
                            S.appName,
                            style: context.text.displaySmall?.copyWith(
                              fontSize: 44,
                            ),
                          ),
                          Text(
                            S.appNameHanja,
                            style: context.text.bodySmall?.copyWith(
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
