import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/doctor_profile_model.dart';
import '../../widgets/status_badge.dart';

class DoctorHeader extends StatelessWidget {
  final DoctorProfileModel? profile;
  final VoidCallback onNotificationTap;

  const DoctorHeader({
    super.key,
    required this.profile,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final doctorName = profile?.fullName ?? 'Doctor';
    final specialization = profile?.specialization ?? 'General Physician';
    final hospital = profile?.hospitalAffiliation ?? 'Aarogya Partner Hospital';
    final license = profile?.medicalLicenseNumber ?? profile?.nmcRegistrationNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top App Bar Row
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.mintBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCEEAE2), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.add_box_rounded, color: AppColors.primary, size: 24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aarogya HealthPro',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_outlined, size: 22, color: AppColors.darkSlate),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.surfaceContainerHigh,
              child: Text(
                doctorName.length > 3 && doctorName.startsWith('Dr.')
                    ? doctorName.substring(3).trim().substring(0, 1).toUpperCase()
                    : (doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Doctor Sub-Header Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$hospital • $specialization',
                      style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      license != null ? '$doctorName ($license)' : doctorName,
                      style: AppTypography.bodySm.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const StatusBadge(
                label: 'Duty Active',
                variant: BadgeVariant.mint,
                showDot: true,
                height: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
