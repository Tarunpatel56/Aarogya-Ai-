import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Teals
  static const Color primaryTeal = Color(0xFF005E54);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFF0A7E70);
  static const Color activeTeal = Color(0xFF00665B);

  // Mint / Light Teals
  static const Color mintBg = Color(0xFFEBF6F3);
  static const Color mintBorder = Color(0xFFCEEAE2);
  static const Color mintAccent = Color(0xFF26A69A);
  static const Color mintText = Color(0xFF00695C);

  // Backgrounds & Surfaces
  static const Color scaffoldBg = Color(0xFFF7FAF9);
  static const Color cardBg = Colors.white;
  static const Color subCardBg = Color(0xFFF4F7F6);
  static const Color cardBorder = Color(0xFFE6ECE9);

  // Text Colors
  static const Color textPrimary = Color(0xFF1B282A);
  static const Color textSecondary = Color(0xFF6A7B82);
  static const Color textMuted = Color(0xFF90A4AE);

  // Status & Vitals Colors
  static const Color sosRed = Color(0xFFBA1A1A);
  static const Color sosLightBg = Color(0xFFFDECEB);
  static const Color sosRedBorder = Color(0xFFFFCDD2);

  static const Color heartRateRed = Color(0xFFE53935);
  static const Color heartRateBg = Color(0xFFFFEBEE);

  static const Color oxygenTeal = Color(0xFF00897B);
  static const Color oxygenBg = Color(0xFFE0F2F1);

  static const Color stepsGreen = Color(0xFF00796B);
  static const Color stepsBg = Color(0xFFE8F5E9);

  static const Color glucoseBlue = Color(0xFF0288D1);
  static const Color glucoseBg = Color(0xFFE1F5FE);

  static const Color warningOrange = Color(0xFFE65100);
  static const Color warningOrangeBg = Color(0xFFFFF3E0);

  // Sleep Architecture
  static const Color sleepDeep = Color(0xFF005E54);
  static const Color sleepRem = Color(0xFF26A69A);
  static const Color sleepLight = Color(0xFFD3E7E4);

  // Shadows
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        const BoxShadow(
          color: Color(0x12000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
}

class AppTheme {
  static ThemeData get lightTheme {
    final fontName = GoogleFonts.plusJakartaSans().fontFamily;

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontName,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        primary: AppColors.primaryTeal,
        secondary: AppColors.mintAccent,
        surface: AppColors.cardBg,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
