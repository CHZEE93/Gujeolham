// 화면 미리보기 PNG 생성기(디자인 확인용).
//   flutter test tool/screens_preview_test.dart
// 결과: build/preview/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gujeolham/core/ocr_region.dart';
import 'package:gujeolham/core/router.dart';
import 'package:gujeolham/core/theme.dart';
import 'package:gujeolham/core/widgets/seal.dart';
import 'package:gujeolham/data/app_settings.dart';
import 'package:gujeolham/data/database.dart';
import 'package:gujeolham/data/providers.dart';
import 'package:gujeolham/features/capture/capture_session.dart';
import 'package:gujeolham/features/share/share_card.dart';
import 'package:gujeolham/features/share/share_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;

const _out = 'build/preview';

final _quotes = [
  ('무엇을 아끼는지가 곧 그 사람이다. 소유는 사물을 붙드는 일이고 존재는 삶을 살아내는 일이다.', '소유냐 존재냐', '에리히 프롬', 112),
  ('죽는 날까지 하늘을 우러러 한 점 부끄럼이 없기를.', '하늘과 바람과 별과 시', '윤동주', 9),
  ('어른이 되는 것은 외로움을 견디는 일이 아니라, 외로움과 함께 사는 법을 익히는 일이다.', '밤의 문장들', null, null),
  ('천천히 가도 괜찮다. 멈추지만 않는다면.', null, '공자', null),
];

Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(await File(path).readAsBytes())));
    await loader.load();
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? r'C:\src\flutter';
  await load(
    'MaterialIcons',
    p.join(flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts', 'materialicons-regular.otf'),
  );
}

Future<AppDatabase> _seed({bool empty = false, bool cherished = false}) async {
  final db = AppDatabase(NativeDatabase.memory());
  // 실제 비동기 구간에서 DB를 열어 둔다(가짜 시간 안에서 열면 멈춘다).
  await db.customSelect('SELECT 1').get();
  if (empty) return db;
  var t = DateTime.utc(2026, 10, 20, 9);
  for (final (i, q) in _quotes.indexed) {
    final iso = t.add(Duration(days: i)).toIso8601String();
    await db.quotesDao.insertQuote(
      QuotesCompanion.insert(
        id: 'q$i',
        content: q.$1,
        bookTitle: Value(q.$2),
        author: Value(q.$3),
        page: Value(q.$4),
        memo: Value(i == 0 ? '다시 읽고 싶은 대목. 밑줄 그어 둘 것.' : null),
        cherishedAt: Value(cherished && i.isEven ? iso : null),
        createdAt: iso,
        updatedAt: iso,
      ),
    );
  }
  return db;
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('ko_KR');
    await Directory(_out).create(recursive: true);
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    String location, {
    bool empty = false,
    bool cherished = false,
    AppPalette palette = AppPalette.hanji,
    void Function(ProviderContainer c)? prepare,
    Future<void> Function(WidgetTester t)? act,
    Duration settle = const Duration(milliseconds: 300),
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    late AppDatabase db;
    await tester.runAsync(() async {
      await _loadFonts();
      db = await _seed(empty: empty, cherished: cherished);
    });
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        initialPaletteProvider.overrideWithValue(palette),
      ],
    );
    addTearDown(container.dispose);
    prepare?.call(container);

    final key = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(palette),
            routerConfig: buildRouter(initialLocation: location),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() async {
        await GoogleFonts.pendingFonts();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (act != null) await act(tester);
    await tester.pump(settle);

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$_out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
    // 메모리 DB는 닫지 않는다(가짜 시간 안에서 스트림 정리를 기다리다 멈춘다).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  }

  const pageLines = [
    '그는 오래도록 창밖을 바라보았다.',
    '무엇을 아끼는지가 곧 그 사람이다.',
    '소유는 사물을 붙드는 일이고 존재는 삶을 살아내는 일이다.',
    '우리는 대개 그 둘을 헷갈린 채 산다.',
    '그날 밤, 나는 책장을 덮지 못했다.',
  ];

  // 가짜 책 쪽(900x1200): 단어마다 회색 막대를 그리고 같은 위치를 OCR 결과로 쓴다.
  final pageWords = <OcrLine>[
    for (final (i, line) in pageLines.indexed)
      OcrLine([
        for (final (j, w) in line.split(' ').indexed)
          OcrWord(w, Rect.fromLTWH(90.0 + j * 150, 160.0 + i * 160, 130, 56)),
      ]),
  ];

  Future<String> pageImage() async {
    final path = '$_out/_page.png';
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)
      ..drawRect(const Rect.fromLTWH(0, 0, 900, 1200), Paint()..color = const Color(0xFFF3ECDD));
    for (final w in pageWords.expand((l) => l.words)) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(w.box.deflate(10), const Radius.circular(6)),
        Paint()..color = const Color(0xFF8A7A68),
      );
    }
    final img = await rec.endRecording().toImage(900, 1200);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    return path;
  }

  void selectSession(ProviderContainer c) {
    c.read(captureSessionProvider.notifier)
      ..start('none.jpg', [for (final l in pageLines) OcrLine([OcrWord(l, Rect.zero)])])
      ..toggle(1)
      ..toggle(2);
  }

  testWidgets('splash', (t) => shoot(t, '01_splash', Routes.splash, settle: const Duration(milliseconds: 1200)));
  testWidgets('home', (t) => shoot(t, '02_home', Routes.home));
  testWidgets('home_empty', (t) => shoot(t, '03_home_empty', Routes.home, empty: true));
  testWidgets('capture', (t) => shoot(t, '04_capture', Routes.capture));
  testWidgets('select', (t) => shoot(t, '05_select', Routes.select, prepare: selectSession));
  testWidgets('save', (t) => shoot(t, '06_save', Routes.save, prepare: selectSession));
  testWidgets('detail', (t) => shoot(t, '07_detail', Routes.detail('q0')));
  testWidgets('settings', (t) => shoot(t, '08_settings', Routes.settings));
  testWidgets('region', (t) async {
    late String path;
    await t.runAsync(() async => path = await pageImage());
    await shoot(
      t,
      '10_region',
      Routes.region,
      prepare: (c) => c.read(captureSessionProvider.notifier).start(path, pageWords),
      act: (t) async {
        // 이미지 로딩을 기다린 뒤 2~3번째 줄을 감싸도록 끈다.
        for (var i = 0; i < 4; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
          await t.pump();
        }
        final box = t.getRect(find.byType(CustomPaint).last);
        final s = box.width / 900;
        final start = box.topLeft + Offset(70 * s, 300 * s);
        await t.dragFrom(start, Offset(760 * s, 300 * s));
        await t.pump();
      },
    );
  });
  for (final p in AppPalette.values.skip(1)) {
    testWidgets('theme_${p.name}', (t) => shoot(t, '20_theme_${p.name}', Routes.home, palette: p, cherished: true));
  }
  testWidgets('settings_theme', (t) => shoot(t, '21_settings_pink', Routes.settings, palette: AppPalette.pink));
  testWidgets('sentence_edit', (t) => shoot(t, '14_sentence_edit', Routes.select,
      prepare: selectSession,
      act: (t) async {
        await t.tap(find.byIcon(Icons.edit_rounded).at(1));
        await t.pump(const Duration(milliseconds: 600));
      }));
  testWidgets('home_cherished', (t) => shoot(t, '11_home_cherished', Routes.home, cherished: true));
  testWidgets('detail_cherished', (t) => shoot(t, '12_detail_cherished', Routes.detail('q0'), cherished: true));
  testWidgets('share', (t) => shoot(t, '13_share', Routes.detail('q0'),
      act: (t) async {
        await t.tap(find.text('보내기'));
        await t.pump(const Duration(milliseconds: 600));
      }));
  testWidgets('share_prestige', (t) => shoot(t, '15_share_geumbak', Routes.share('q0'),
      prepare: (c) => c.read(shareCardStyleProvider.notifier).select(ShareCardStyle.geumbak)));
  testWidgets('share_text', (t) => shoot(t, '16_share_text', Routes.share('q0'),
      act: (t) async {
        await t.tap(find.text('글'));
        await t.pump(const Duration(milliseconds: 300));
      }));

  // 보내기 카드 모음: 모든 모양을 실제 크기(320x400)로 5장씩 두 줄.
  testWidgets('share_cards', (t) async {
    const gap = 16.0;
    t.view.physicalSize = Size(kShareCardSize.width * 5 + gap * 6, kShareCardSize.height * 2 + gap * 3);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(_loadFonts);
    final q = _quotes[0];
    final quote = Quote(
      id: 'q0',
      content: q.$1,
      bookTitle: q.$2,
      author: q.$3,
      page: q.$4,
      createdAt: '2026-10-20T09:00:00Z',
      updatedAt: '2026-10-20T09:00:00Z',
    );
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(gap),
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in ShareCardStyle.values) ShareCard(quote: quote, style: s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await t.runAsync(() async {
        await GoogleFonts.pendingFonts();
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await t.pump(const Duration(milliseconds: 16));
    }
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1.5);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await File('$_out/17_share_cards.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  });

  // 저장 완료 연출: 함이가 웃고 낙관이 찍힌 직후
  testWidgets('celebration', (t) async {
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: Scaffold(body: SaveCelebration(onDone: () {})),
        ),
      ),
    );
    await t.runAsync(GoogleFonts.pendingFonts);
    await t.pump(const Duration(milliseconds: 700));
    await t.pump(const Duration(milliseconds: 450));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await File('$_out/09_celebration.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  });
}
