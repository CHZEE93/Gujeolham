import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'data/app_settings.dart';
import 'data/providers.dart';
import 'sync/sync_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(S.locale);
  // 서체는 assets/google_fonts/에 포함되어 있으므로 내려받지 않는다.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final name in ['Jua', 'GowunDodum']) {
      final text = await rootBundle.loadString('assets/google_fonts/OFL-$name.txt');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });

  final palette = await AppSettingsStore().loadPalette();
  final container = ProviderContainer(
    overrides: [
      initialPaletteProvider.overrideWithValue(palette),
      // 저장·수정·삭제 직후 동기화(미연동이면 아무것도 하지 않음).
      quoteChangedHookProvider.overrideWith(
        (ref) => () => ref.read(syncControllerProvider.notifier).syncSilently(),
      ),
    ],
  );
  // 앱 시작 시 연동 상태 복원 및 동기화.
  container.read(syncControllerProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GujeolhamApp(),
    ),
  );
}

class GujeolhamApp extends ConsumerWidget {
  const GujeolhamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: S.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(ref.watch(paletteProvider)),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
