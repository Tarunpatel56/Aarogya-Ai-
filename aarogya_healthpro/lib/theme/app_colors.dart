import 'package:flutter/material.dart';

/// Clinical Sanctuary Design System Color Palette
/// Designed for high diagnostic legibility, strict WCAG 2.2 AAA adherence,
/// and clear cognitive anchoring in clinical remote patient monitoring (RPM).
class AppColors {
  // Canvas & Surfaces
  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceDim = Color(0xFFD8DADC);
  static const Color surfaceBright = Color(0xFFF7F9FB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerHigh = Color(0xFFE6E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E5);
  static const Color surfaceVariant = Color(0xFFE0E3E5);

  // Text & Ink
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color inverseSurface = Color(0xFF2D3133);
  static const Color inverseOnSurface = Color(0xFFEFF1F3);
  static const Color textMuted = Color(0xFF6D7A77);
  static const Color textPlaceholder = Color(0xFF94A3B8);

  // Outlines & Borders
  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);
  static const Color borderHairline = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFFCBD5E1);

  // Primary Brand Teal (Clinical Restoration & Telemetry)
  static const Color primary = Color(0xFF00685F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008378);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color inversePrimary = Color(0xFF6BD8CB);
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005049);
  static const Color surfaceTint = Color(0xFF006A61);

  // Secondary Slate Navy (Structural Anchors)
  static const Color secondary = Color(0xFF565E74);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDAE2FD);
  static const Color onSecondaryContainer = Color(0xFF5C647A);
  static const Color secondaryFixed = Color(0xFFDAE2FD);
  static const Color secondaryFixedDim = Color(0xFFBEC6E0);
  static const Color onSecondaryFixed = Color(0xFF131B2E);
  static const Color onSecondaryFixedVariant = Color(0xFF3F465C);
  static const Color darkSlate = Color(0xFF0F172A);

  // Tertiary Marine Teal
  static const Color tertiary = Color(0xFF006860);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF248279);
  static const Color onTertiaryContainer = Color(0xFFF3FFFC);
  static const Color tertiaryFixed = Color(0xFF9CF2E8);
  static const Color tertiaryFixedDim = Color(0xFF80D5CB);
  static const Color onTertiaryFixed = Color(0xFF00201D);
  static const Color onTertiaryFixedVariant = Color(0xFF00504A);

  // Semantic Triage: Critical / Emergency (Rose Crimson)
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color criticalRed = Color(0xFFE11D48);
  static const Color criticalRedWash = Color(0xFFFFF1F2);
  static const Color criticalRedBorder = Color(0xFFFECDD3);

  // Semantic Triage: Optimal / Synced / Stable (Emerald)
  static const Color stableGreen = Color(0xFF059669);
  static const Color stableGreenWash = Color(0xFFECFDF5);
  static const Color stableGreenBorder = Color(0xFFA7F3D0);

  // Semantic Triage: Attention / Pending (Amber)
  static const Color warningAmber = Color(0xFFD97706);
  static const Color warningAmberWash = Color(0xFFFFFBEB);
  static const Color warningAmberBorder = Color(0xFFFDE68A);

  // Semantic Triage: Informative / Device Sync (Sky Cobalt)
  static const Color infoCobalt = Color(0xFF0284C7);
  static const Color infoCobaltWash = Color(0xFFF0F9FF);
  static const Color infoCobaltBorder = Color(0xFFBAE6FD);

  // Mint Accents & AI Co-Pilot
  static const Color mintBg = Color(0xFFF0FDFA);
  static const Color mintAccent = Color(0xFF0D9488);
  static const Color mintChipBg = Color(0xFFE6F7F5);
  static const Color mintChipText = Color(0xFF00685F);

  // Ergonomic aliases for cross-ecosystem UI
  static const Color primaryTeal = primary;
  static const Color primaryDark = darkSlate;
  static const Color cardBorder = borderHairline;
  static const Color textSecondary = textMuted;

  // Elevation Shadows
  static List<BoxShadow> get cardElevation => [
        const BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
        const BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get floatingElevation => [
        const BoxShadow(
          color: Color(0x0D0F172A),
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
        const BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get modalElevation => [
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
