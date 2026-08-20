import 'package:file_explorer/features/settings/domain/entities/app_settings.dart';
import 'package:flutter/material.dart';

/// Maps each theme accent to its seed color (Material seed for the scheme).
/// CRED-style deep premium palette — rich saturated tones for neon-glow
/// gradients on dark surfaces.
Color appThemeSeed(AppThemeAccent accent) {
  return switch (accent) {
    AppThemeAccent.purple => const Color(0xFF7C3AED),
    AppThemeAccent.green => const Color(0xFF059669),
    AppThemeAccent.pink => const Color(0xFFDB2777),
    AppThemeAccent.red => const Color(0xFFDC2626),
    AppThemeAccent.royalBlue => const Color(0xFF2563EB),
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

  static Color _neumorphicLight(bool isDark, Color base) {
    return isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.06), base)
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.8), base);
  }

  static Color _neumorphicDark(bool isDark, Color base) {
    return isDark
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.6), base)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.18), base);
  }

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
    final containerColor =
        isDark ? scheme.surfaceContainer : _lightSurfaceContainer;

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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? scheme.surface : _lightSurfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: containerColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.onPrimary;
          }
          return _neumorphicLight(isDark, containerColor);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return containerColor;
        }),
        trackOutlineColor:
            WidgetStatePropertyAll(_neumorphicDark(isDark, containerColor)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(
          color: scheme.onSurfaceVariant,
          width: 1.6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primaryContainer;
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimaryContainer;
            }
            return scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
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
