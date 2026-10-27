import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 설정에서 고르는 앱 색 테마. 기본은 스타일 가이드의 한지(포근한 갈색)다.
/// 위젯에서는 이 값을 직접 쓰지 말고 `context.hanji`로 접근한다.
///
/// 필드 이름은 기본 테마 기준이고, 다른 테마에서는 같은 역할의 색을 담는다.
/// (hanji 바탕 · paper 카드 · sand 칩 · galmuk 글자 · yeongal 장식선 ·
///  dahong 주요 버튼·낙관 · ok/chija 보조 낙관)
enum AppPalette {
  hanji(
    '한지',
    HanjiColors(
      hanji: Color(0xFFF6F0E4), // 한지 미색
      paper: Color(0xFFFBF7EE), // 종이 백색
      sand: Color(0xFFEFE3CF), // 연한 모래
      galmuk: Color(0xFF5A3F2B), // 갈먹
      yeongal: Color(0xFFB59A7C), // 연갈
      dahong: Color(0xFFC9594C), // 다홍
      ok: Color(0xFF8FB8A5), // 옥색
      chija: Color(0xFFE0B457), // 치자
    ),
  ),
  pink(
    '벚꽃',
    HanjiColors(
      hanji: Color(0xFFF9EEF0),
      paper: Color(0xFFFFF8F9),
      sand: Color(0xFFF4DCE2),
      galmuk: Color(0xFF5E3A45),
      yeongal: Color(0xFFC79CA8),
      dahong: Color(0xFFD5607C),
      ok: Color(0xFF94C2AE),
      chija: Color(0xFFE8B86A),
    ),
  ),
  green(
    '연두',
    HanjiColors(
      hanji: Color(0xFFF0F4E3),
      paper: Color(0xFFFAFCF3),
      sand: Color(0xFFE1EACA),
      galmuk: Color(0xFF3F4A2C),
      yeongal: Color(0xFFA5B587),
      dahong: Color(0xFF6E9A3A),
      ok: Color(0xFFE58A6B),
      chija: Color(0xFFE0B457),
    ),
  ),
  sky(
    '하늘',
    HanjiColors(
      hanji: Color(0xFFEBF3F8),
      paper: Color(0xFFF7FBFD),
      sand: Color(0xFFD7E7F1),
      galmuk: Color(0xFF2F4559),
      yeongal: Color(0xFF93B0C6),
      dahong: Color(0xFF4A8BC0),
      ok: Color(0xFFE5898A),
      chija: Color(0xFFE8C26A),
    ),
  ),
  lavender(
    '라일락',
    HanjiColors(
      hanji: Color(0xFFF2EFF8),
      paper: Color(0xFFFBF9FE),
      sand: Color(0xFFE4DEF1),
      galmuk: Color(0xFF453A5F),
      yeongal: Color(0xFFA99DC6),
      dahong: Color(0xFF8A6BC6),
      ok: Color(0xFFE58AA6),
      chija: Color(0xFF8FC1B5),
    ),
  ),
  citron(
    '유자',
    HanjiColors(
      hanji: Color(0xFFFAF4DF),
      paper: Color(0xFFFFFBEE),
      sand: Color(0xFFF3E6BC),
      galmuk: Color(0xFF51441F),
      yeongal: Color(0xFFC6B27A),
      dahong: Color(0xFFD9962B),
      ok: Color(0xFF8FB8A5),
      chija: Color(0xFFC9594C),
    ),
  );

  const AppPalette(this.label, this.colors);

  /// 설정 화면에 보이는 이름.
  final String label;
  final HanjiColors colors;

  static AppPalette byName(String? name) => AppPalette.values.firstWhere(
    (p) => p.name == name,
    orElse: () => AppPalette.hanji,
  );
}

/// 카드 모서리.
const double kCardRadius = 20;

/// 낙관 모서리(7–12px 사이).
const double kSealRadius = 10;

/// 그림자 대신 쓰는 아래쪽 단색 그림자 높이.
const double kDrop = 3;

@immutable
class HanjiColors extends ThemeExtension<HanjiColors> {
  const HanjiColors({
    required this.hanji,
    required this.paper,
    required this.sand,
    required this.galmuk,
    required this.yeongal,
    required this.dahong,
    required this.ok,
    required this.chija,
  });

  final Color hanji;
  final Color paper;
  final Color sand;
  final Color galmuk;
  final Color yeongal;
  final Color dahong;
  final Color ok;
  final Color chija;

  /// 보조 글자(갈먹을 흐리게).
  Color get galmukSub => galmuk.withValues(alpha: 0.62);

  /// 카드·입력의 얇은 테두리.
  Color get line => yeongal.withValues(alpha: 0.35);

  /// 카드 아래 단색 그림자.
  Color get cardDrop => yeongal.withValues(alpha: 0.28);

  /// 다홍 버튼 아래 단색 그림자.
  Color get dahongDrop => Color.lerp(dahong, galmuk, 0.35)!;

  /// 갈먹 버튼 아래 단색 그림자.
  Color get galmukDrop => Color.lerp(galmuk, Colors.black, 0.35)!;

  /// 카드마다 번갈아 쓰는 낙관 색.
  List<Color> get sealColors => [dahong, ok, chija];

  @override
  HanjiColors copyWith({
    Color? hanji,
    Color? paper,
    Color? sand,
    Color? galmuk,
    Color? yeongal,
    Color? dahong,
    Color? ok,
    Color? chija,
  }) {
    return HanjiColors(
      hanji: hanji ?? this.hanji,
      paper: paper ?? this.paper,
      sand: sand ?? this.sand,
      galmuk: galmuk ?? this.galmuk,
      yeongal: yeongal ?? this.yeongal,
      dahong: dahong ?? this.dahong,
      ok: ok ?? this.ok,
      chija: chija ?? this.chija,
    );
  }

  @override
  HanjiColors lerp(HanjiColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return HanjiColors(
      hanji: l(hanji, other.hanji),
      paper: l(paper, other.paper),
      sand: l(sand, other.sand),
      galmuk: l(galmuk, other.galmuk),
      yeongal: l(yeongal, other.yeongal),
      dahong: l(dahong, other.dahong),
      ok: l(ok, other.ok),
      chija: l(chija, other.chija),
    );
  }
}

extension HanjiThemeX on BuildContext {
  HanjiColors get hanji => Theme.of(this).extension<HanjiColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Jua(주아): 제목·화면명·상세 구절·버튼·낙관 글자.
TextStyle juaStyle([TextStyle? base]) => GoogleFonts.jua(textStyle: base);

/// 고운돋움: 목록·입력·메모·보조 정보.
TextStyle dodumStyle([TextStyle? base]) =>
    GoogleFonts.gowunDodum(textStyle: base);

ThemeData buildAppTheme([AppPalette palette = AppPalette.hanji]) {
  final colors = palette.colors;
  final p = colors;
  final sub = colors.galmukSub;
  final line = colors.line;

  final scheme = ColorScheme(
    brightness: Brightness.light,
    primary: p.dahong,
    onPrimary: p.paper,
    secondary: p.galmuk,
    onSecondary: p.paper,
    tertiary: p.ok,
    onTertiary: p.paper,
    error: p.dahong,
    onError: p.paper,
    surface: p.paper,
    onSurface: p.galmuk,
    onSurfaceVariant: p.yeongal,
    surfaceContainerLowest: p.hanji,
    surfaceContainerLow: p.paper,
    surfaceContainer: p.paper,
    surfaceContainerHigh: p.paper,
    surfaceContainerHighest: p.sand,
    secondaryContainer: p.sand,
    onSecondaryContainer: p.galmuk,
    outline: p.yeongal,
    outlineVariant: p.sand,
    shadow: Colors.transparent,
    surfaceTint: Colors.transparent,
  );

  final base = GoogleFonts.gowunDodumTextTheme(
    ThemeData.light().textTheme,
  ).apply(bodyColor: p.galmuk, displayColor: p.galmuk);

  TextStyle? jua(TextStyle? s) => s == null ? null : juaStyle(s);

  final textTheme = base.copyWith(
    displayLarge: jua(base.displayLarge),
    displayMedium: jua(base.displayMedium),
    displaySmall: jua(base.displaySmall),
    headlineLarge: jua(base.headlineLarge),
    headlineMedium: jua(base.headlineMedium),
    headlineSmall: jua(base.headlineSmall),
    titleLarge: jua(base.titleLarge?.copyWith(fontSize: 24)),
    titleMedium: jua(base.titleMedium?.copyWith(fontSize: 18)),
    titleSmall: jua(base.titleSmall?.copyWith(fontSize: 15)),
    labelLarge: jua(base.labelLarge?.copyWith(fontSize: 17)),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.75),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 14.5, height: 1.65),
    bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, color: sub),
    labelMedium: base.labelMedium?.copyWith(color: sub),
    labelSmall: base.labelSmall?.copyWith(color: sub),
  );

  const pill = StadiumBorder();
  final cardShape = RoundedRectangleBorder(
    borderRadius: const BorderRadius.all(Radius.circular(kCardRadius)),
    side: BorderSide(color: line),
  );

  InputBorder pillBorder(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(999)),
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.hanji,
    canvasColor: p.hanji,
    textTheme: textTheme,
    extensions: [colors],
    splashFactory: NoSplash.splashFactory,
    highlightColor: p.sand.withValues(alpha: 0.5),
    dividerColor: p.sand,
    dividerTheme: DividerThemeData(
      color: p.sand,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.galmuk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: p.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.dahong,
        foregroundColor: p.paper,
        disabledBackgroundColor: p.sand,
        disabledForegroundColor: p.yeongal,
        shape: pill,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.galmuk,
        backgroundColor: p.paper,
        side: BorderSide(color: line),
        shape: pill,
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.galmuk,
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: p.galmuk),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.paper,
      border: pillBorder(line),
      enabledBorder: pillBorder(line),
      focusedBorder: pillBorder(p.yeongal, 1.5),
      errorBorder: pillBorder(p.dahong),
      focusedErrorBorder: pillBorder(p.dahong, 1.5),
      labelStyle: textTheme.bodyMedium?.copyWith(color: sub),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: p.galmuk,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: p.yeongal),
      errorStyle: textTheme.bodySmall?.copyWith(color: p.dahong),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.paper,
      elevation: 0,
      shape: cardShape,
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.galmuk,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.paper),
      shape: pill,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? p.paper
            : p.yeongal,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? p.dahong
            : p.sand,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.dahong,
      linearTrackColor: p.sand,
      circularTrackColor: Colors.transparent,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.yeongal,
      textColor: p.galmuk,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.dahong,
      selectionColor: p.dahong.withValues(alpha: 0.2),
      selectionHandleColor: p.dahong,
    ),
    iconTheme: IconThemeData(color: p.galmuk),
  );
}
