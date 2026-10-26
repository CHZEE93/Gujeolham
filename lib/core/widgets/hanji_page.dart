import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../strings.dart';
import '../theme.dart';
import 'decor.dart';
import 'puffy.dart';

/// 한지 바탕 + 구름 코너 장식을 깐 공통 화면 틀.
///
/// - 홈·상세: `cornerLayers: 2`, `norigae: true`(상단 중앙에 노리개)
/// - 나머지: `cornerLayers: 1`
class HanjiPage extends StatelessWidget {
  const HanjiPage({
    super.key,
    required this.body,
    this.title,
    this.cornerLayers = 1,
    this.norigae = false,
    this.actions = const [],
    this.showBack,
    this.bottom,
    this.floating,
  });

  final Widget body;
  final String? title;
  final int cornerLayers;
  final bool norigae;
  final List<Widget> actions;

  /// null이면 이전 화면이 있을 때만 뒤로 버튼을 보인다.
  final bool? showBack;
  final Widget? bottom;
  final Widget? floating;

  @override
  Widget build(BuildContext context) {
    final back = showBack ?? context.canPop();
    final leading = back
        ? RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: S.back,
            onPressed: () => context.pop(),
          )
        : const SizedBox(width: 42);
    final trailing = actions.isEmpty
        ? const SizedBox(width: 42)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions[i],
              ],
            ],
          );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 4),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            leading,
            Expanded(
              child: (title != null && !norigae)
                  ? Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: context.text.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
            trailing,
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: context.hanji.hanji,
      floatingActionButton: floating,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(child: CloudCorners(layers: cornerLayers)),
          ),
          SafeArea(
            child: Column(
              children: [
                header,
                Expanded(child: body),
                ?bottom,
              ],
            ),
          ),
          if (norigae)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: Center(child: Norigae(height: 84))),
            ),
        ],
      ),
    );
  }
}

/// 화면 하단 고정 영역(주요 버튼 자리).
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
    child: child,
  );
}
