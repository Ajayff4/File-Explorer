import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';

/// Maps each theme accent to its seed color (Material seed for the scheme).
Color appThemeSeed(AppThemeAccent accent) {
  return switch (accent) {
    AppThemeAccent.purple => const Color(0xFF9B5CFF),
    AppThemeAccent.green => const Color(0xFF00C853),
    AppThemeAccent.pink => const Color(0xFFFF4081),
    AppThemeAccent.red => const Color(0xFFFF5252),
    AppThemeAccent.royalBlue => const Color(0xFF2979FF),
  };
}

/// Picks black or white for text/icons placed on top of [color], using the
/// framework's standard luminance threshold (WCAG-aware).
Color onAccent(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

class AppTheme {
  const AppTheme._();

  static const _lightSurface = Color(0xFFF2F2F2);
  static const _lightSurfaceContainer = Color(0xFFECECEC);

  static ThemeData light([AppThemeAccent accent = AppThemeAccent.purple]) {
    final seed = appThemeSeed(accent);
    final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
      primary: seed,
      onPrimary: onAccent(seed),
      surface: const Color(0xFFFFFFFF),
    );
    return _base(scheme);
  }

  static ThemeData dark([AppThemeAccent accent = AppThemeAccent.purple]) {
    final seed = appThemeSeed(accent);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: seed,
      onPrimary: onAccent(seed),
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final surfaceColor = isDark ? scheme.surface : _lightSurface;
    final containerColor = isDark ? scheme.surfaceContainer : _lightSurfaceContainer;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceColor,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: surfaceColor,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainerLow : Colors.white,
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minLeadingWidth: 40,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: scheme.primary,
        checkmarkColor: scheme.onPrimary,
        labelStyle: TextStyle(color: scheme.onSurface),
        secondarySelectedColor: scheme.primary,
        secondaryLabelStyle: TextStyle(color: scheme.onPrimary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: containerColor,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: containerColor,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
