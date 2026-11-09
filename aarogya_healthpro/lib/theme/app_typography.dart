import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get headlineXl => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.56,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.36,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: -0.2,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineSm => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        letterSpacing: -0.08,
        color: AppColors.onSurface,
      );

  static TextStyle get metricDisplay => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 32 / 28,
        letterSpacing: -0.56,
        color: AppColors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get metricDisplayLg => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 36 / 32,
        letterSpacing: -0.96,
        color: AppColors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        letterSpacing: 0,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        letterSpacing: 0,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0.06,
        color: AppColors.textMuted,
      );

  static TextStyle get labelMd => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.24,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 0.44,
        color: AppColors.textMuted,
      );

  static TextStyle get clinicalCode => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.secondary,
      );
}

class AppRadii {
  static const double sm = 4.0;
  static const double base = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;

  static BorderRadius get radiusSm => BorderRadius.circular(sm);
  static BorderRadius get radiusBase => BorderRadius.circular(base);
  static BorderRadius get radiusMd => BorderRadius.circular(md);
  static BorderRadius get radiusLg => BorderRadius.circular(lg);
  static BorderRadius get radiusXl => BorderRadius.circular(xl);
  static BorderRadius get radiusFull => BorderRadius.circular(full);
}

class AppSpacing {
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2Xl = 48.0;

  static const double margin = 16.0;
  static const double gutter = 16.0;
}
