import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ocr_region.dart';
import '../../core/router.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../core/widgets/hanji_page.dart';
import '../../core/widgets/puffy.dart';
import 'capture_session.dart';

/// 사진 위에 손가락으로 네모를 그려 담을 부분만 고르는 화면.
class RegionScreen extends ConsumerStatefulWidget {
  const RegionScreen({super.key});

  @override
  ConsumerState<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends ConsumerState<RegionScreen> {
  Size? _imageSize;
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) => setState(
      () => _imageSize = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ),
    ),
  );

  /// 그린 영역(원본 픽셀 좌표).
  Rect? _region;
  Offset? _dragStart;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = ref.read(captureSessionProvider).imagePath;
    if (_stream != null || path == null) return;
    _stream = FileImage(File(path)).resolve(createLocalImageConfiguration(context))
      ..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  void _next(Rect? region) {
    ref.read(captureSessionProvider.notifier).useRegion(region);
    context.push(Routes.select);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(captureSessionProvider);
    final region = _region;
    final wordCount = region == null
        ? 0
        : session.lines
              .expand((l) => l.words)
              .where((w) => wordInRegion(w, region))
              .length;

    return HanjiPage(
      title: S.regionTitle,
      actions: [
        if (region != null)
          RoundIconButton(
            icon: Icons.restart_alt_rounded,
            tooltip: S.regionReset,
            onPressed: () => setState(() => _region = null),
          ),
      ],
      bottom: BottomBar(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PillButton(
                label: S.regionAll,
                tone: PillTone.light,
                onPressed: () => _next(null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: PillButton(
                label: S.regionButton,
                icon: Icons.crop_rounded,
                onPressed: wordCount == 0 ? null : () => _next(region),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
            child: Text(
              region != null && wordCount == 0
                  ? S.regionEmpty
                  : S.regionGuide,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: switch ((session.imagePath, _imageSize)) {
                (final path?, final size?) => _buildCanvas(path, size, session),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas(String path, Size imageSize, CaptureSession session) {
    return LayoutBuilder(
      builder: (context, box) {
        // 사진을 화면 안에 맞춰(contain) 그린다. scale: 원본 픽셀 → 화면 좌표.
        final scale = math.min(
          box.maxWidth / imageSize.width,
          box.maxHeight / imageSize.height,
        );
        final shown = imageSize * scale;
        Offset toImage(Offset local) => Offset(
          (local.dx / scale).clamp(0.0, imageSize.width),
          (local.dy / scale).clamp(0.0, imageSize.height),
        );

        return Center(
          child: SizedBox.fromSize(
            size: shown,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kCardRadius - 6),
              child: GestureDetector(
                onPanStart: (d) {
                  final p = toImage(d.localPosition);
                  setState(() {
                    _dragStart = p;
                    _region = Rect.fromPoints(p, p);
                  });
                },
                onPanUpdate: (d) {
                  final start = _dragStart;
                  if (start == null) return;
                  setState(
                    () => _region = Rect.fromPoints(
                      start,
                      toImage(d.localPosition),
                    ),
                  );
                },
                onPanEnd: (_) {
                  _dragStart = null;
                  // 너무 작게 그린 것은 실수로 본다.
                  final r = _region;
                  if (r != null && (r.width * scale < 16 || r.height * scale < 16)) {
                    setState(() => _region = null);
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path), fit: BoxFit.fill),
                    CustomPaint(
                      painter: _RegionPainter(
                        lines: session.lines,
                        region: _region,
                        scale: scale,
                        colors: context.hanji,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 읽은 단어 위치를 옅게, 그린 영역 밖은 어둡게, 영역 안 단어는 치자색으로 칠한다.
class _RegionPainter extends CustomPainter {
  _RegionPainter({
    required this.lines,
    required this.region,
    required this.scale,
    required this.colors,
  });

  final List<OcrLine> lines;
  final Rect? region;
  final double scale;
  final HanjiColors colors;

  Rect _toScreen(Rect r) => Rect.fromLTRB(
    r.left * scale,
    r.top * scale,
    r.right * scale,
    r.bottom * scale,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final region = this.region;
    final faint = Paint()..color = colors.chija.withValues(alpha: 0.16);
    final picked = Paint()..color = colors.chija.withValues(alpha: 0.45);

    if (region != null) {
      final r = _toScreen(region);
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(6))),
        ),
        Paint()..color = colors.galmuk.withValues(alpha: 0.45),
      );
    }

    for (final w in lines.expand((l) => l.words)) {
      final inside = region != null && wordInRegion(w, region);
      canvas.drawRRect(
        RRect.fromRectAndRadius(_toScreen(w.box), const Radius.circular(3)),
        inside ? picked : faint,
      );
    }

    if (region != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(_toScreen(region), const Radius.circular(6)),
        Paint()
          ..color = colors.dahong
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_RegionPainter old) =>
      old.region != region || old.scale != scale || old.lines != lines;
}
