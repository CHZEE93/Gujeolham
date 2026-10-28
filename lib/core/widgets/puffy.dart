import 'package:flutter/material.dart';

import '../theme.dart';

enum PillTone {
  /// 다홍 · 주요 버튼
  primary,

  /// 갈먹 · 어두운 버튼
  dark,

  /// 종이 백색 · 보조 버튼
  light,
}

/// 알약 버튼. 그림자 대신 아래쪽 단색 그림자(0 3px 0), 누르면 쏙 들어간다.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = PillTone.primary,
    this.expand = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillTone tone;
  final bool expand;
  final double height;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final enabled = widget.onPressed != null;
    final (bg, fg, drop, border) = switch (widget.tone) {
      _ when !enabled => (c.sand, c.yeongal, Colors.transparent, null),
      PillTone.primary => (c.dahong, c.paper, c.dahongDrop, null),
      PillTone.dark => (c.galmuk, c.paper, c.galmukDrop, null),
      PillTone.light => (c.paper, c.galmuk, c.cardDrop, c.line),
    };
    final pressed = _down && enabled;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: fg, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelLarge?.copyWith(color: fg),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.only(bottom: kDrop),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            transform: Matrix4.translationValues(0, pressed ? kDrop : 0, 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: border == null ? null : Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: drop,
                  offset: Offset(0, pressed ? 0 : kDrop),
                ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// 둥근 아이콘 버튼(뒤로·설정·고치기 등).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(bottom: kDrop),
            decoration: BoxDecoration(
              color: c.paper,
              shape: BoxShape.circle,
              border: Border.all(color: c.line),
              boxShadow: [BoxShadow(color: c.cardDrop, offset: const Offset(0, kDrop))],
            ),
            child: Icon(icon, size: 20, color: color ?? c.galmuk),
          ),
        ),
      ),
    );
  }
}

/// 둥근 카드(모서리 20px + 아래쪽 단색 그림자). [onTap]이 있으면 눌리는 느낌을 준다.
class PuffyCard extends StatefulWidget {
  const PuffyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  @override
  State<PuffyCard> createState() => _PuffyCardState();
}

class _PuffyCardState extends State<PuffyCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final pressed = _down && widget.onTap != null;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      padding: widget.padding,
      transform: Matrix4.translationValues(0, pressed ? kDrop - 1 : 0, 0),
      decoration: BoxDecoration(
        color: widget.color ?? c.paper,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(
          color: widget.borderColor ?? c.line,
          width: widget.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: c.cardDrop,
            offset: Offset(0, pressed ? 1 : kDrop + 1),
          ),
        ],
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}

/// 연한 모래색 칩.
class SandChip extends StatelessWidget {
  const SandChip(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: c.sand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c.galmukSub),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(color: c.galmuk),
            ),
          ),
        ],
      ),
    );
  }
}

/// 알약 모양 선택 칩(홈의 모든 구절/새긴 구절, 보내기의 카드/글).
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.hanji;
    final fg = selected ? c.paper : c.galmuk;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.galmuk : c.paper,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c.galmuk : c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? c.paper : c.dahong),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: context.text.bodySmall?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
