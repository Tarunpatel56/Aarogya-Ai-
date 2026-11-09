import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/doctor_appointment_model.dart';

class DoctorMetricsGrid extends StatelessWidget {
  final List<DoctorAppointmentModel> appointments;
  final bool isLoading;
  final VoidCallback? onPendingTap;
  final VoidCallback? onConfirmedTap;
  final VoidCallback? onAllTap;

  const DoctorMetricsGrid({
    super.key,
    required this.appointments,
    required this.isLoading,
    this.onPendingTap,
    this.onConfirmedTap,
    this.onAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = appointments.where((a) => a.isRequested).length;
    final confirmedCount = appointments.where((a) => a.isConfirmed).length;
    final completedCount = appointments.where((a) => a.isCompleted).length;
    final totalCount = appointments.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'PENDING REQUESTS',
                icon: Icons.hourglass_top_rounded,
                mainValue: isLoading ? '...' : '$pendingCount',
                mainUnit: 'Action req.',
                badgeText: pendingCount > 0 ? '• Needs confirmation' : 'Queue clear',
                badgeColor: pendingCount > 0 ? AppColors.warningAmber : AppColors.stableGreen,
                onTap: onPendingTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'CONFIRMED SLOTS',
                icon: Icons.event_available_rounded,
                mainValue: isLoading ? '...' : '$confirmedCount',
                mainUnit: 'Scheduled',
                badgeText: confirmedCount > 0 ? '• Ready for consult' : 'No upcoming',
                badgeColor: AppColors.primary,
                onTap: onConfirmedTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'COMPLETED REVIEWS',
                icon: Icons.task_alt_rounded,
                mainValue: isLoading ? '...' : '$completedCount',
                mainUnit: 'Finished',
                badgeText: '✓ Consultations done',
                badgeColor: AppColors.stableGreen,
                onTap: onAllTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL APPOINTMENTS',
                icon: Icons.calendar_today_outlined,
                mainValue: isLoading ? '...' : '$totalCount',
                mainUnit: 'All records',
                badgeText: 'Live ABHA OPD Queue',
                badgeColor: AppColors.secondary,
                onTap: onAllTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required IconData icon,
    required String mainValue,
    required String mainUnit,
    required String badgeText,
    required Color badgeColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderHairline),
          boxShadow: AppColors.cardElevation,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  mainValue,
                  style: AppTypography.metricDisplay.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    mainUnit,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              badgeText,
              style: AppTypography.bodySm.copyWith(
                fontSize: 11,
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
