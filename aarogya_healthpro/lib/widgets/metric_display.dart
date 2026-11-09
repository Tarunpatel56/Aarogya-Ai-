import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'status_badge.dart';

class VitalMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String? statusPillText;
  final BadgeVariant statusPillVariant;
  final IconData? headerIcon;
  final Color? headerIconColor;
  final String? contextSubtitle;
  final Color? valueColor;
  final Widget? bottomWidget;

  const VitalMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.statusPillText,
    this.statusPillVariant = BadgeVariant.stable,
    this.headerIcon,
    this.headerIconColor,
    this.contextSubtitle,
    this.valueColor,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderHairline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (headerIcon != null)
                Icon(
                  headerIcon,
                  size: 14,
                  color: headerIconColor ?? AppColors.mintAccent,
                )
              else if (statusPillText != null)
                StatusBadge(
                  label: statusPillText!,
                  variant: statusPillVariant,
                  height: 18,
                  horizontalPadding: 6,
                  customTextStyle: AppTypography.labelSm.copyWith(
                    fontSize: 9.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.metricDisplay.copyWith(
                  color: valueColor ?? AppColors.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (headerIcon != null && statusPillText != null) ...[
                const Spacer(),
                StatusBadge(
                  label: statusPillText!,
                  variant: statusPillVariant,
                  height: 18,
                  horizontalPadding: 6,
                  customTextStyle: AppTypography.labelSm.copyWith(
                    fontSize: 9.5,
                  ),
                ),
              ],
            ],
          ),
          if (contextSubtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              contextSubtitle!,
              style: AppTypography.bodySm.copyWith(
                fontSize: 10.5,
                color: AppColors.onSurfaceVariant,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (bottomWidget != null) ...[
            const SizedBox(height: 6),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}
