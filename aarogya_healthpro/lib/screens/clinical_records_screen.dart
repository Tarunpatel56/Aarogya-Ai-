import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/status_badge.dart';

class ClinicalRecordsScreen extends StatelessWidget {
  const ClinicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('FHIR Clinical Records & Labs', style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Synchronizing latest FHIR R4 Bundles with ABDM Health Repository')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ABDM Gateway Sync Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mintBg,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: const Color(0xFFCEEAE2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ABDM Gateway Active • M3 Compliant', style: AppTypography.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        Text('Connected to National Health Claims Exchange (NHCX) & Apollo HIU/HIP Bridge', style: AppTypography.bodySm.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('RECENT DIAGNOSTIC & LAB BUNDLES', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 10),
            _buildRecordCard(
              title: 'Comprehensive Lipid Profile & Apolipoprotein B',
              patient: 'Rahul Sharma (ABHA: 91-4828-1182-3941)',
              date: 'Yesterday, 14:20 IST',
              status: 'Normal / Target Achieved',
              badgeVariant: BadgeVariant.stable,
              loinc: 'LOINC 24331-1',
              highlights: 'LDL: 58 mg/dL (< 70 Target) • Total Chol: 132 mg/dL • Triglycerides: 118 mg/dL',
            ),
            const SizedBox(height: 12),
            _buildRecordCard(
              title: 'Cardiac Troponin I (High Sensitivity)',
              patient: 'Sunita Devi (ABHA: 14-9921-4481-2892)',
              date: 'Today, 09:40 IST',
              status: 'Borderline Elevation',
              badgeVariant: BadgeVariant.warning,
              loinc: 'LOINC 49563-0',
              highlights: 'hs-cTnI: 0.042 ng/mL (Reference limit: 0.034 ng/mL). Repeat at 4 hours ordered.',
            ),
            const SizedBox(height: 12),
            _buildRecordCard(
              title: 'Glycated Hemoglobin (HbA1c) & eAG',
              patient: 'Sunita Devi (ABHA: 14-9921-4481-2892)',
              date: '24 Oct 2024',
              status: 'Sub-Optimal Control',
              badgeVariant: BadgeVariant.critical,
              loinc: 'LOINC 4548-4',
              highlights: 'HbA1c: 8.4% • Estimated Average Glucose (eAG): 194 mg/dL',
            ),
            const SizedBox(height: 12),
            _buildRecordCard(
              title: 'Transthoracic Echocardiogram 2D Doppler',
              patient: 'Rahul Sharma (ABHA: 91-4828-1182-3941)',
              date: '18 Oct 2024',
              status: 'Preserved LVEF',
              badgeVariant: BadgeVariant.stable,
              loinc: 'LOINC 18053-9',
              highlights: 'LVEF: 55%. Normal left ventricular chamber dimensions. No hemodynamically significant valvular lesion.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard({
    required String title,
    required String patient,
    required String date,
    required String status,
    required BadgeVariant badgeVariant,
    required String loinc,
    required String highlights,
  }) {
    return Container(
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
                  style: AppTypography.headlineSm.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
              StatusBadge(
                label: status,
                variant: badgeVariant,
                height: 20,
                horizontalPadding: 6,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(patient, style: AppTypography.bodySm.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11)),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: AppTypography.bodySm.copyWith(fontSize: 10.5)),
              Text(loinc, style: AppTypography.clinicalCode.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(highlights, style: AppTypography.bodySm.copyWith(fontSize: 11, color: AppColors.onSurface)),
          ),
        ],
      ),
    );
  }
}
