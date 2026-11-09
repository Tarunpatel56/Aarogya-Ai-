import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clinical Sanctuary Design System Colors
class ClinicalColors {
  // Brand & Architecture
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF00685F);
  static const Color deepSlateNavy = Color(0xFF0F172A);
  static const Color deepMarineTeal = Color(0xFF0F766E);
  static const Color sanctuaryBaseNeutral = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceInset = Color(0xFFF1F5F9);

  // Surface ink & text
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);

  // Borders & Dividers
  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);
  static const Color hairlineBorder = Color(0xFFE2E8F0);
  static const Color subtleDivider = Color(0xFFF1F5F9);
  static const Color focusedBorder = Color(0xFFCBD5E1);

  // Primary palette tokens
  static const Color primary = Color(0xFF00685F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008378);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color inversePrimary = Color(0xFF6BD8CB);
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005049);

  // Secondary palette tokens
  static const Color secondary = Color(0xFF565E74);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondaryContainer = Color(0xFF5C647A);
  static const Color secondaryFixed = Color(0xFFDAE2FD);
  static const Color secondaryFixedDim = Color(0xFFBEC6E0);
  static const Color onSecondaryFixed = Color(0xFF131B2E);
  static const Color onSecondaryFixedVariant = Color(0xFF3F465C);

  // Tertiary palette tokens
  static const Color tertiary = Color(0xFF006860);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF248279);
  static const Color onTertiaryContainer = Color(0xFFF3FFFC);
  static const Color tertiaryFixed = Color(0xFF9CF2E8);
  static const Color tertiaryFixedDim = Color(0xFF80D5CB);
  static const Color onTertiaryFixed = Color(0xFF00201D);
  static const Color onTertiaryFixedVariant = Color(0xFF00504A);

  // Error & Critical Emergency Tokens
  static const Color error = Color(0xFFBA1A1A);
  static const Color crimsonRose = Color(0xFFE11D48);
  static const Color darkRedCta = Color(0xFF991B1B);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color criticalWash = Color(0xFFFFF1F2);
  static const Color criticalBorder = Color(0xFFFECDD3);

  // Semantic Triage Accents
  // Optimal / Synced / Stable (Emerald)
  static const Color optimalEmerald = Color(0xFF059669);
  static const Color optimalWash = Color(0xFFECFDF5);
  static const Color optimalBorder = Color(0xFFA7F3D0);

  // Attention / Pending / Review (Amber)
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningWash = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  // Informative Telemetry (Sky Cobalt)
  static const Color infoCobalt = Color(0xFF0284C7);
  static const Color infoWash = Color(0xFFF0F9FF);
  static const Color infoBorder = Color(0xFFBAE6FD);
}

/// Elevation & Shadow definitions per Clinical Sanctuary Design System
class ClinicalElevations {
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.04),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.03),
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.05),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.03),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.08),
      blurRadius: 25,
      offset: Offset(0, 20),
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color.fromRGBO(15, 23, 42, 0.04),
      blurRadius: 10,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
  ];
}

/// Border Radii
class ClinicalRadii {
  static const double sm = 4.0;
  static const double standard = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;

  static BorderRadius get roundedSm => BorderRadius.circular(sm);
  static BorderRadius get rounded => BorderRadius.circular(standard);
  static BorderRadius get roundedMd => BorderRadius.circular(md);
  static BorderRadius get roundedLg => BorderRadius.circular(lg);
  static BorderRadius get roundedXl => BorderRadius.circular(xl);
  static BorderRadius get roundedFull => BorderRadius.circular(full);
}

/// Spacing tokens
class ClinicalSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double gutter = 16.0;
  static const double margin = 16.0;
}

/// Clinical Sanctuary Typography Standards
class ClinicalTypography {
  static TextStyle headlineXl({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.025 * 36,
        color: color,
      );

  static TextStyle headlineXlMobile({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.02 * 28,
        color: color,
      );

  static TextStyle headlineLg({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 38 / 30,
        letterSpacing: -0.02 * 30,
        color: color,
      );

  static TextStyle headlineLgMobile({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.015 * 24,
        color: color,
      );

  static TextStyle headlineMd({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: -0.01 * 20,
        color: color,
      );

  static TextStyle headlineSm({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 26 / 18,
        letterSpacing: -0.005 * 18,
        color: color,
      );

  static TextStyle bodyLg({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 26 / 16,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodyMd({Color color = ClinicalColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 22 / 14,
        letterSpacing: 0,
        color: color,
      );

  static TextStyle bodySm({Color color = ClinicalColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        letterSpacing: 0.005 * 13,
        color: color,
      );

  static TextStyle metricDisplay({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 36 / 32,
        letterSpacing: -0.03 * 32,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle metricDisplayMobile({Color color = ClinicalColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 32 / 28,
        letterSpacing: -0.02 * 28,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle labelMd({Color color = ClinicalColors.textMuted}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.02 * 12,
        color: color,
      );

  static TextStyle labelSm({Color color = ClinicalColors.textMuted}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 0.04 * 11,
        color: color,
      );
}

/// Clinical Sanctuary Material Theme
class ClinicalSanctuaryTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ClinicalColors.primaryTeal,
        onPrimary: ClinicalColors.onPrimary,
        primaryContainer: ClinicalColors.primaryContainer,
        onPrimaryContainer: ClinicalColors.onPrimaryContainer,
        secondary: ClinicalColors.secondary,
        onSecondary: ClinicalColors.onSecondary,
        secondaryContainer: ClinicalColors.secondaryContainer,
        onSecondaryContainer: ClinicalColors.onSecondaryContainer,
        tertiary: ClinicalColors.tertiary,
        onTertiary: ClinicalColors.onTertiary,
        error: ClinicalColors.error,
        onError: ClinicalColors.onError,
        surface: ClinicalColors.surfaceElevated,
        onSurface: ClinicalColors.onSurface,
        outline: ClinicalColors.outline,
        outlineVariant: ClinicalColors.outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ClinicalColors.surfaceElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: ClinicalColors.deepSlateNavy),
      ),
      dividerTheme: const DividerThemeData(
        color: ClinicalColors.hairlineBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: ClinicalColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ClinicalRadii.roundedLg,
          side: const BorderSide(color: ClinicalColors.hairlineBorder),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
