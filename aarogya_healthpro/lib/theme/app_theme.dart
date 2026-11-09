import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final plusJakarta = GoogleFonts.plusJakartaSans().fontFamily;

    return ThemeData(
      useMaterial3: true,
      fontFamily: plusJakarta,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
        surface: AppColors.surfaceContainerLowest,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSm,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.radiusLg,
          side: const BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textPlaceholder),
        border: OutlineInputBorder(
          borderRadius: AppRadii.radiusBase,
          borderSide: const BorderSide(color: AppColors.borderHairline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusBase,
          borderSide: const BorderSide(color: AppColors.borderHairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusBase,
          borderSide: const BorderSide(color: AppColors.mintAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.radiusBase,
          borderSide: const BorderSide(color: AppColors.criticalRed, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mintAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusBase),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkSlate,
          backgroundColor: AppColors.surfaceContainerLowest,
          side: const BorderSide(color: AppColors.borderHairline, width: 1),
          textStyle: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.radiusBase),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderHairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
