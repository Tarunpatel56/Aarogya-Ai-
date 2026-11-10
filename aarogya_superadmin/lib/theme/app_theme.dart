import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceBg = Color(0xFFF8FAFC);  // Slate 50
  static const Color cardBg = Colors.white;
  static const Color accentNavy = Color(0xFF1E293B);
  static const Color brandRed = Color(0xFFEF4444);   // Red 500
  static const Color brandBlue = Color(0xFF3B82F6);  // Blue 500
  static const Color brandTeal = Color(0xFF0D9488);  // Teal 600
  static const Color brandGreen = Color(0xFF10B981); // Green 500
  static const Color brandAmber = Color(0xFFF59E0B); // Amber 500
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandRed,
        primary: brandRed,
        surface: surfaceBg,
      ),
      scaffoldBackgroundColor: surfaceBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryDark,
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderColor),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: brandRed,
        surface: Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
      ),
    );
  }
}

typedef AdminTheme = AppTheme;
