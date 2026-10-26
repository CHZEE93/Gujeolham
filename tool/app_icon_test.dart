// 앱 아이콘 생성기: 한지 바탕 + 구름 코너 + 함이.
//   flutter test tool/app_icon_test.dart
// Android mipmap과 iOS AppIcon.appiconset의 PNG를 덮어쓴다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gujeolham/core/theme.dart';
import 'package:gujeolham/core/widgets/decor.dart';
import 'package:gujeolham/core/widgets/hami.dart';

const _base = 1024.0;

const _android = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

const _ios = {
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

/// 아이콘 그림(정사각형, 투명 없음). iOS·Android 런처가 모서리를 깎는다.
class _IconArt extends StatelessWidget {
  const _IconArt();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.hanji.hanji,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CloudCorners(layers: 1, size: 200, inset: 120),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, 20),
              child: const Hami(size: 600),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('app icons', (tester) async {
    tester.view.physicalSize = const Size(_base, _base);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Theme(
          data: buildAppTheme(),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: _IconArt(),
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      Future<void> write(String path, int px) async {
        final image = await boundary.toImage(pixelRatio: px / _base);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      }

      for (final e in _android.entries) {
        await write('android/app/src/main/res/${e.key}/ic_launcher.png', e.value);
      }
      for (final e in _ios.entries) {
        await write('ios/Runner/Assets.xcassets/AppIcon.appiconset/${e.key}', e.value);
      }
      await Directory('build/preview').create(recursive: true);
      await write('build/preview/00_app_icon.png', 512);
    });
  });
}
