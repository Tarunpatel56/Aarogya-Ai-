import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ClinicalCoPilotBanner extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback? onTap;

  const ClinicalCoPilotBanner({
    super.key,
    this.title = 'Aarogya Clinical Co-Pilot:',
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F8F5), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: const Color(0xFFCEEAE2), width: 1),
          boxShadow: AppColors.cardElevation,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3.5,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.mintAccent,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: '$title ',
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: text,
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 12.5,
                        color: AppColors.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
