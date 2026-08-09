import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _brandPurple = Color(0xFF9B5CFF);
  static const _deepPurple = Color(0xFF6D39F2);
  static const _black = Color(0xFF050508);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _brandPurple).copyWith(
      primary: _deepPurple,
      secondary: const Color(0xFF7A4CE0),
      surface: const Color(0xFFFBF9FF),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8F6FC),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _brandPurple,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _brandPurple,
      secondary: const Color(0xFFC7A7FF),
      surface: const Color(0xFF101016),
      onSurface: const Color(0xFFF2ECFF),
    );

    return _base(scheme).copyWith(
      scaffoldBackgroundColor: _black,
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final cardColor = Color.alphaBlend(
      scheme.primary.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.04),
      scheme.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor:
            scheme.brightness == Brightness.dark ? _black : scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minLeadingWidth: 40,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            scheme.brightness == Brightness.dark ? _black : scheme.surface,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            scheme.brightness == Brightness.dark ? _black : scheme.surface,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
