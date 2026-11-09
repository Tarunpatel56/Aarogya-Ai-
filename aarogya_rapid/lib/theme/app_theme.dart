import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clinical Sanctuary Design System Tokens & Color Palette
class SanctuaryColors {
  // Base Canvas & Surfaces
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceInset = Color(0xFFF1F5F9);

  // Inks & Typography
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);

  // Borders & Delimiters
  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);
  static const Color hairlineBorder = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFFCBD5E1);

  // Primary Clinical Teals
  static const Color primary = Color(0xFF00685F);
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryDeepMarine = Color(0xFF0F766E);
  static const Color primaryContainer = Color(0xFF008378);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryWash = Color(0xFFF0FDFA);
  static const Color primaryMintBorder = Color(0xFF99F6E4);

  // Secondary Navy & Slate
  static const Color deepSlateNavy = Color(0xFF0F172A);
  static const Color secondary = Color(0xFF565E74);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondaryContainer = Color(0xFF5C647A);

  // Tertiary
  static const Color tertiary = Color(0xFF006860);
  static const Color tertiaryContainer = Color(0xFF248279);
  static const Color onTertiaryContainer = Color(0xFFF3FFFC);

  // Semantic Triage: Critical / Emergency Crimson
  static const Color error = Color(0xFFBA1A1A);
  static const Color crimsonRose = Color(0xFFE11D48);
  static const Color emergencyRed = Color(0xFFB71C1C);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color errorWash = Color(0xFFFFF1F2);
  static const Color errorBorder = Color(0xFFFECDD3);

  // Semantic Triage: Optimal / Synced / Stable (Emerald)
  static const Color optimalGreen = Color(0xFF059669);
  static const Color optimalGreenBg = Color(0xFFECFDF5);
  static const Color optimalGreenBorder = Color(0xFFA7F3D0);

  // Semantic Triage: Attention / Pending (Amber)
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberBg = Color(0xFFFFFBEB);
  static const Color warningAmberBorder = Color(0xFFFDE68A);

  // Semantic Triage: Telemetry / Info (Sky Blue)
  static const Color infoSky = Color(0xFF0284C7);
  static const Color infoSkyBg = Color(0xFFF0F9FF);
  static const Color infoSkyBorder = Color(0xFFBAE6FD);

  // Depth & Elevation Shadows
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
        const BoxShadow(
          color: Color(0x060F172A),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        const BoxShadow(
          color: Color(0x0D0F172A),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
        const BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        const BoxShadow(
          color: Color(0x140F172A),
          blurRadius: 25,
          offset: Offset(0, 20),
        ),
        const BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 10,
          offset: Offset(0, 8),
        ),
      ];
}

/// Clinical Sanctuary Radius Standards
class SanctuaryRadius {
  static const double sm = 4.0;
  static const double base = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;

  static BorderRadius get rSm => BorderRadius.circular(sm);
  static BorderRadius get rBase => BorderRadius.circular(base);
  static BorderRadius get rMd => BorderRadius.circular(md);
  static BorderRadius get rLg => BorderRadius.circular(lg);
  static BorderRadius get rXl => BorderRadius.circular(xl);
  static BorderRadius get rFull => BorderRadius.circular(full);
}

/// Clinical Sanctuary Typography Standards
class SanctuaryTypography {
  static TextStyle headlineXl({Color color = SanctuaryColors.deepSlateNavy}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.22,
      letterSpacing: -0.025,
      color: color,
    );
  }

  static TextStyle headlineLg({Color color = SanctuaryColors.deepSlateNavy}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.26,
      letterSpacing: -0.02,
      color: color,
    );
  }

  static TextStyle headlineMd({Color color = SanctuaryColors.deepSlateNavy}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.35,
      letterSpacing: -0.01,
      color: color,
    );
  }

  static TextStyle headlineSm({Color color = SanctuaryColors.deepSlateNavy}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: -0.005,
      color: color,
    );
  }

  static TextStyle metricDisplay({Color color = SanctuaryColors.deepSlateNavy}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.03,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle bodyLg({Color color = SanctuaryColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle bodyMd({Color color = SanctuaryColors.onSurface}) {
    return GoogleFonts.inter(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle bodySm({Color color = SanctuaryColors.textSecondary}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle labelMd({Color color = SanctuaryColors.onSurfaceVariant}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.02,
      color: color,
    );
  }

  static TextStyle labelSm({Color color = SanctuaryColors.textSecondary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.06,
      color: color,
    );
  }
}

/// AppTheme configuration
class SanctuaryTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: SanctuaryColors.surface,
      primaryColor: SanctuaryColors.primaryTeal,
      colorScheme: const ColorScheme.light(
        primary: SanctuaryColors.primaryTeal,
        onPrimary: SanctuaryColors.onPrimary,
        secondary: SanctuaryColors.secondary,
        surface: SanctuaryColors.surfaceContainerLowest,
        error: SanctuaryColors.crimsonRose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SanctuaryColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: SanctuaryColors.deepSlateNavy),
      ),
      cardTheme: CardThemeData(
        color: SanctuaryColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: SanctuaryRadius.rLg,
          side: const BorderSide(color: SanctuaryColors.hairlineBorder),
        ),
      ),
    );
  }
}
