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
    AppThemeAccent.mint => const Color(0xFF00B887),
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
    // Scaffolds stay transparent so the ambient glass backdrop (mounted in
    // AppShell) shows through on every route.
    const transparent = Colors.transparent;
    final sheetColor = isDark
        ? const Color(0xFF14141C).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.9);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: transparent,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheetColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.6),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF1E1E28).withValues(alpha: 0.95)
            : const Color(0xFF1E1E28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.2),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.7),
          ),
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
        fillColor: Colors.white.withValues(alpha: isDark ? 0.07 : 0.6),
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
          return isDark
              ? Colors.white.withValues(alpha: 0.7)
              : scheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return Colors.white.withValues(alpha: isDark ? 0.12 : 0.5);
        }),
        trackOutlineColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
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
        backgroundColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return TextStyle(color: scheme.onSurfaceVariant, fontSize: 12);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
