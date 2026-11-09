import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/physiotherapy_service.dart';

class HomePhysioCard extends StatelessWidget {
  final PhysiotherapyService physioService;
  final VoidCallback onOpenPhysio;

  const HomePhysioCard({
    super.key,
    required this.physioService,
    required this.onOpenPhysio,
  });

  @override
  Widget build(BuildContext context) {
    final plans = physioService.getDailyPlans();
    final todayPlan = plans.isNotEmpty ? plans.first : null;
    final progress = physioService.getWeeklyProgress();
    final sessionsCount = progress['completedSessionsCount'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF16A34A), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Rehabilitation & Physio',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onOpenPhysio,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Exercises', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (todayPlan != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayPlan.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${todayPlan.estimatedDurationMinutes} mins • ${todayPlan.exercises.length} Exercises',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onOpenPhysio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Start', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$sessionsCount session(s) completed this week • Evidence-based non-compressive routines',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
