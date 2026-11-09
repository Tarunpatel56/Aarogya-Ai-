import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/telemetry.dart';

class PrescriptionTrackerRow extends StatefulWidget {
  final MedicationItem item;
  final ValueChanged<bool>? onToggleLogged;
  final VoidCallback? onMoreOptions;

  const PrescriptionTrackerRow({
    super.key,
    required this.item,
    this.onToggleLogged,
    this.onMoreOptions,
  });

  @override
  State<PrescriptionTrackerRow> createState() => _PrescriptionTrackerRowState();
}

class _PrescriptionTrackerRowState extends State<PrescriptionTrackerRow> {
  late bool isLogged;

  @override
  void initState() {
    super.initState();
    isLogged = widget.item.isLogged;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderHairline, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular completion toggle
          GestureDetector(
            onTap: () {
              setState(() {
                isLogged = !isLogged;
                widget.item.isLogged = isLogged;
              });
              widget.onToggleLogged?.call(isLogged);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isLogged ? AppColors.stableGreenWash : AppColors.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLogged ? AppColors.stableGreen : AppColors.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Icon(
                isLogged ? Icons.check : Icons.medication_outlined,
                size: 16,
                color: isLogged ? AppColors.stableGreen : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Medicine info & timing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.item.name,
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.item.dosage,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.item.timingCategory,
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 9.5,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.item.statusSubtitle,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: isLogged ? AppColors.stableGreen : AppColors.textMuted,
                    fontWeight: isLogged ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onMoreOptions != null)
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
              onPressed: widget.onMoreOptions,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
