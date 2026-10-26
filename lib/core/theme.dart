import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 구절함 팔레트(스타일 가이드 · 한지와 포근한 갈색).
/// 위젯에서는 이 상수를 직접 쓰지 말고 `context.hanji`로 접근한다.
abstract final class _Palette {
  static const hanji = Color(0xFFF6F0E4); // 한지 미색 · 바탕
  static const paper = Color(0xFFFBF7EE); // 종이 백색 · 카드·입력
  static const sand = Color(0xFFEFE3CF); // 연한 모래 · 칩·탭 선택
  static const galmuk = Color(0xFF5A3F2B); // 갈먹 · 글자·어두운 버튼
  static const yeongal = Color(0xFFB59A7C); // 연갈 · 코너 장식선
  static const dahong = Color(0xFFC9594C); // 다홍 · 낙관·주요 버튼
  static const ok = Color(0xFF8FB8A5); // 옥색 · 보조 낙관
  static const chija = Color(0xFFE0B457); // 치자 · 보조 낙관
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

ThemeData buildAppTheme() {
  const colors = HanjiColors(
    hanji: _Palette.hanji,
    paper: _Palette.paper,
    sand: _Palette.sand,
    galmuk: _Palette.galmuk,
    yeongal: _Palette.yeongal,
    dahong: _Palette.dahong,
    ok: _Palette.ok,
    chija: _Palette.chija,
  );
  final sub = colors.galmukSub;
  final line = colors.line;

  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: _Palette.dahong,
    onPrimary: _Palette.paper,
    secondary: _Palette.galmuk,
    onSecondary: _Palette.paper,
    tertiary: _Palette.ok,
    onTertiary: _Palette.paper,
    error: _Palette.dahong,
    onError: _Palette.paper,
    surface: _Palette.paper,
    onSurface: _Palette.galmuk,
    onSurfaceVariant: _Palette.yeongal,
    surfaceContainerLowest: _Palette.hanji,
    surfaceContainerLow: _Palette.paper,
    surfaceContainer: _Palette.paper,
    surfaceContainerHigh: _Palette.paper,
    surfaceContainerHighest: _Palette.sand,
    secondaryContainer: _Palette.sand,
    onSecondaryContainer: _Palette.galmuk,
    outline: _Palette.yeongal,
    outlineVariant: _Palette.sand,
    shadow: Colors.transparent,
    surfaceTint: Colors.transparent,
  );

  final base = GoogleFonts.gowunDodumTextTheme(
    ThemeData.light().textTheme,
  ).apply(bodyColor: _Palette.galmuk, displayColor: _Palette.galmuk);

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
    scaffoldBackgroundColor: _Palette.hanji,
    canvasColor: _Palette.hanji,
    textTheme: textTheme,
    extensions: const [colors],
    splashFactory: NoSplash.splashFactory,
    highlightColor: _Palette.sand.withValues(alpha: 0.5),
    dividerColor: _Palette.sand,
    dividerTheme: const DividerThemeData(
      color: _Palette.sand,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _Palette.galmuk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: _Palette.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _Palette.dahong,
        foregroundColor: _Palette.paper,
        disabledBackgroundColor: _Palette.sand,
        disabledForegroundColor: _Palette.yeongal,
        shape: pill,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _Palette.galmuk,
        backgroundColor: _Palette.paper,
        side: BorderSide(color: line),
        shape: pill,
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _Palette.galmuk,
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: _Palette.galmuk),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _Palette.paper,
      border: pillBorder(line),
      enabledBorder: pillBorder(line),
      focusedBorder: pillBorder(_Palette.yeongal, 1.5),
      errorBorder: pillBorder(_Palette.dahong),
      focusedErrorBorder: pillBorder(_Palette.dahong, 1.5),
      labelStyle: textTheme.bodyMedium?.copyWith(color: sub),
      floatingLabelStyle: textTheme.bodyMedium?.copyWith(
        color: _Palette.galmuk,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: _Palette.yeongal),
      errorStyle: textTheme.bodySmall?.copyWith(color: _Palette.dahong),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _Palette.paper,
      elevation: 0,
      shape: cardShape,
      titleTextStyle: textTheme.titleMedium,
      contentTextStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _Palette.galmuk,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: _Palette.paper),
      shape: pill,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? _Palette.paper
            : _Palette.yeongal,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? _Palette.dahong
            : _Palette.sand,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _Palette.dahong,
      linearTrackColor: _Palette.sand,
      circularTrackColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _Palette.yeongal,
      textColor: _Palette.galmuk,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: _Palette.dahong,
      selectionColor: _Palette.dahong.withValues(alpha: 0.2),
      selectionHandleColor: _Palette.dahong,
    ),
    iconTheme: const IconThemeData(color: _Palette.galmuk),
  );
}
