import 'package:flutter/material.dart';

class BksColors {
  static const bg0 = Color(0xFF080810);
  static const bg1 = Color(0xFF0F0F1C);
  static const bg2 = Color(0xFF171727);
  static const bg3 = Color(0xFF1C1C30);
  static const border = Color(0xFF232338);
  static const borderBright = Color(0xFF363660);
  static const gold = Color(0xFFE8A020);
  static const goldDim = Color(0xFF6A4A10);
  static const goldGlow = Color(0x33E8A020);
  static const vocals = Color(0xFFFF6B8A);
  static const drums = Color(0xFFFFD93D);
  static const bass = Color(0xFF4ECDC4);
  static const instr = Color(0xFF7B9CFF);
  static const accent = Color(0xFF9B59B6);
  static const success = Color(0xFF27AE60);
  static const error = Color(0xFFE74C3C);
  static const textPrimary = Color(0xFFEEEAFF);
  static const textSecondary = Color(0xFF9090B8);
  static const textMuted = Color(0xFF40405A);
  static const textInverse = Color(0xFF080810);
}

class BksTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BksColors.bg0,
    colorScheme: const ColorScheme.dark(
      primary: BksColors.gold,
      secondary: BksColors.accent,
      surface: BksColors.bg1,
      onPrimary: BksColors.textInverse,
      onSurface: BksColors.textPrimary,
      error: BksColors.error,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: BksColors.textPrimary),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: BksColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 15, color: BksColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 13, color: BksColors.textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BksColors.bg1,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
          color: BksColors.textPrimary, letterSpacing: 2),
    ),
    cardTheme: CardThemeData(
      color: BksColors.bg1,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: BksColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BksColors.gold,
        foregroundColor: BksColors.textInverse,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: BksColors.gold,
      inactiveTrackColor: BksColors.bg3,
      thumbColor: BksColors.gold,
      overlayColor: BksColors.goldGlow,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BksColors.bg1,
      indicatorColor: Colors.transparent,
    ),
  );
}
