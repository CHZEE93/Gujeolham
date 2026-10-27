import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/theme.dart';

/// 기기 로컬 앱 설정(색 테마). 동기화하지 않는다.
class AppSettingsStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'app_settings.json'));
  }

  Future<AppPalette> loadPalette() async {
    try {
      final f = await _file();
      if (!await f.exists()) return AppPalette.hanji;
      final j = jsonDecode(await f.readAsString());
      return AppPalette.byName(j is Map ? j['palette'] as String? : null);
    } catch (_) {
      return AppPalette.hanji;
    }
  }

  Future<void> savePalette(AppPalette palette) async {
    try {
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode({'palette': palette.name}));
    } catch (_) {
      // 저장 실패는 이번 실행의 테마만 바뀐 채로 둔다.
    }
  }
}

final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => AppSettingsStore(),
);

/// 앱 시작 전에 읽어 둔 테마. main에서 덮어쓴다(첫 화면부터 고른 색으로).
final initialPaletteProvider = Provider<AppPalette>((ref) => AppPalette.hanji);

class PaletteController extends Notifier<AppPalette> {
  @override
  AppPalette build() => ref.read(initialPaletteProvider);

  Future<void> select(AppPalette palette) async {
    state = palette;
    await ref.read(appSettingsStoreProvider).savePalette(palette);
  }
}

final paletteProvider = NotifierProvider<PaletteController, AppPalette>(
  PaletteController.new,
);
