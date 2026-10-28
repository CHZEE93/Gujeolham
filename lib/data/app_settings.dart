import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/theme.dart';

/// 기기 로컬 앱 설정(색 테마, 마지막에 고른 보내기 카드). 동기화하지 않는다.
/// 값마다 키 하나를 쓰고, 저장할 때는 다른 키를 지우지 않도록 합쳐서 쓴다.
class AppSettingsStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'app_settings.json'));
  }

  Future<Map<String, Object?>> _readAll() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final j = jsonDecode(await f.readAsString());
      return j is Map ? j.cast<String, Object?>() : {};
    } catch (_) {
      return {};
    }
  }

  Future<String?> read(String key) async {
    final value = (await _readAll())[key];
    return value is String ? value : null;
  }

  Future<void> write(String key, String value) async {
    try {
      final all = await _readAll();
      all[key] = value;
      final f = await _file();
      await f.parent.create(recursive: true);
      await f.writeAsString(jsonEncode(all));
    } catch (_) {
      // 저장 실패는 이번 실행에서만 바뀐 채로 둔다.
    }
  }

  Future<AppPalette> loadPalette() async =>
      AppPalette.byName(await read('palette'));

  Future<void> savePalette(AppPalette palette) =>
      write('palette', palette.name);
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
