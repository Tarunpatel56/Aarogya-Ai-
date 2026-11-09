import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/medicine_reminder_model.dart';
import '../../services/medicine_reminder_service.dart';

class HomeRemindersCard extends StatelessWidget {
  final MedicineReminderService reminderService;
  final VoidCallback onOpenReminders;

  const HomeRemindersCard({
    super.key,
    required this.reminderService,
    required this.onOpenReminders,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MedicineReminder>>(
      valueListenable: reminderService.remindersNotifier,
      builder: (context, reminders, _) {
        final pending = reminders.where((r) => r.status == DoseStatus.pending).toList();
        final stats = reminderService.getAdherenceStats();
        final streak = stats['streakDays'] as int? ?? 0;

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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.alarm_on_rounded, color: Color(0xFFD97706), size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Medicine Reminders',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onOpenReminders,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (pending.isNotEmpty) ...[
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
                              pending.first.medicineName,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${pending.first.dosage} • ${pending.first.timeString} (${pending.first.mealTimingLabel})',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => reminderService.markDoseTaken(pending.first.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Take', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Streak: $streak days • ${pending.length} dose(s) pending today',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ] else ...[
                Row(
                  children: const [
                    Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'All scheduled doses taken for today!',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
