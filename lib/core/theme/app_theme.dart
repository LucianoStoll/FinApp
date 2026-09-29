import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14171B),
        canvasColor: const Color(0xFF14171B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA6C8F2), brightness: Brightness.dark,
          surface: const Color(0xFF20242A),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF14171B),
          centerTitle: false),
        cardTheme: CardThemeData(color: const Color(0xFF22262C),
          elevation: 0, margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF22262C),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      );
}
