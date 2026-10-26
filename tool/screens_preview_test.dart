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
import 'package:gujeolham/core/router.dart';
import 'package:gujeolham/core/theme.dart';
import 'package:gujeolham/core/widgets/seal.dart';
import 'package:gujeolham/data/database.dart';
import 'package:gujeolham/data/providers.dart';
import 'package:gujeolham/features/capture/capture_session.dart';
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

Future<AppDatabase> _seed({bool empty = false}) async {
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
      db = await _seed(empty: empty);
    });
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
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
            theme: buildAppTheme(),
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

  void selectSession(ProviderContainer c) {
    c.read(captureSessionProvider.notifier)
      ..start('none.jpg', [
        '그는 오래도록 창밖을 바라보았다.',
        '무엇을 아끼는지가 곧 그 사람이다.',
        '소유는 사물을 붙드는 일이고 존재는 삶을 살아내는 일이다.',
        '우리는 대개 그 둘을 헷갈린 채 산다.',
        '그날 밤, 나는 책장을 덮지 못했다.',
      ])
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
