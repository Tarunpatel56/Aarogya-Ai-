import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum BadgeVariant {
  stable,
  warning,
  critical,
  info,
  mint,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;
  final IconData? icon;
  final bool showDot;
  final double height;
  final double horizontalPadding;
  final TextStyle? customTextStyle;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = BadgeVariant.stable,
    this.icon,
    this.showDot = false,
    this.height = 24.0,
    this.horizontalPadding = 10.0,
    this.customTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color borderColor;

    switch (variant) {
      case BadgeVariant.stable:
        bg = AppColors.stableGreenWash;
        textColor = AppColors.stableGreen;
        borderColor = AppColors.stableGreenBorder;
        break;
      case BadgeVariant.warning:
        bg = AppColors.warningAmberWash;
        textColor = AppColors.warningAmber;
        borderColor = AppColors.warningAmberBorder;
        break;
      case BadgeVariant.critical:
        bg = AppColors.criticalRedWash;
        textColor = AppColors.criticalRed;
        borderColor = AppColors.criticalRedBorder;
        break;
      case BadgeVariant.info:
        bg = AppColors.infoCobaltWash;
        textColor = AppColors.infoCobalt;
        borderColor = AppColors.infoCobaltBorder;
        break;
      case BadgeVariant.mint:
        bg = AppColors.mintChipBg;
        textColor = AppColors.mintChipText;
        borderColor = const Color(0xFFCEEAE2);
        break;
      case BadgeVariant.neutral:
        bg = AppColors.surfaceContainer;
        textColor = AppColors.onSurfaceVariant;
        borderColor = AppColors.borderHairline;
        break;
    }

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: customTextStyle ??
                AppTypography.labelSm.copyWith(
                  color: textColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class ClinicalFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? activeTextColor;
  final Color? customTextColor;
  final Color? customBorderColor;
  final String? prefixDotColor;

  const ClinicalFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
    this.activeTextColor,
    this.customTextColor,
    this.customBorderColor,
    this.prefixDotColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? (activeColor ?? AppColors.darkSlate)
        : AppColors.surfaceContainerLowest;
    final txtColor = isSelected
        ? (activeTextColor ?? Colors.white)
        : (customTextColor ?? AppColors.onSurface);
    final borderColor = isSelected
        ? Colors.transparent
        : (customBorderColor ?? AppColors.borderHairline);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isSelected ? AppColors.floatingElevation : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: txtColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
