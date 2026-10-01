import 'package:flutter/material.dart';

abstract final class SomiaColors {
  static const background = Color(0xFF10161D);
  static const sidebar = Color(0xFF0D1319);
  static const surface = Color(0xFF1A242D);
  static const surfaceHigh = Color(0xFF202D38);
  static const outline = Color(0xFF293746);
  static const muted = Color(0xFF9CAEC2);
  static const blue = Color(0xFF8CB9F8);
  static const green = Color(0xFF79D9B6);
  static const red = Color(0xFFF38F90);
  static const purple = Color(0xFFB9A8EB);
  static const yellow = Color(0xFFF2CB75);
}

abstract final class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
            seedColor: SomiaColors.blue,
            brightness: Brightness.dark,
            surface: SomiaColors.surface)
        .copyWith(
      primary: SomiaColors.blue,
      onPrimary: SomiaColors.sidebar,
      onSurface: const Color(0xFFF3F6FA),
      outline: SomiaColors.outline,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: SomiaColors.background,
      canvasColor: SomiaColors.background,
      dividerColor: SomiaColors.outline,
      appBarTheme: const AppBarTheme(
          backgroundColor: SomiaColors.background,
          centerTitle: false,
          elevation: 0),
      cardTheme: CardThemeData(
          color: SomiaColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: SomiaColors.outline, width: 0.7))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SomiaColors.surfaceHigh,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SomiaColors.outline))),
      popupMenuTheme: PopupMenuThemeData(
          color: SomiaColors.surfaceHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      listTileTheme: const ListTileThemeData(
          iconColor: SomiaColors.muted,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2)),
    );
  }
}
