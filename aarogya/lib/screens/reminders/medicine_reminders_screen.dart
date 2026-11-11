import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/medicine_reminder_model.dart';
import '../../services/medicine_reminder_service.dart';

class MedicineRemindersScreen extends StatefulWidget {
  final MedicineReminderService? reminderService;
  final String? prefillName;
  final String? prefillDosage;

  const MedicineRemindersScreen({
    super.key,
    this.reminderService,
    this.prefillName,
    this.prefillDosage,
  });

  @override
  State<MedicineRemindersScreen> createState() => _MedicineRemindersScreenState();
}

class _MedicineRemindersScreenState extends State<MedicineRemindersScreen> {
  late final MedicineReminderService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.reminderService ?? MedicineReminderService();
    _service.init();

    if (widget.prefillName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openAddReminderDialog(
          initialName: widget.prefillName,
          initialDosage: widget.prefillDosage,
        );
      });
    }
  }

  void _openAddReminderDialog({String? initialName, String? initialDosage}) {
    final nameController = TextEditingController(text: initialName ?? '');
    final dosageController = TextEditingController(text: initialDosage ?? '1 Tablet');
    MedicineDoseTime doseTime = MedicineDoseTime.morning;
    MealTiming mealTiming = MealTiming.afterFood;
    String timeString = '08:00 AM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Medicine Reminder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  hintText: 'e.g. Telmisartan or Metformin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g. 40mg • 1 Tablet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Time of Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: MedicineDoseTime.values.map((time) {
                  final isSel = doseTime == time;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ChoiceChip(
                        label: Text(
                          time.name.toUpperCase().substring(0, 3),
                          style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                        ),
                        selected: isSel,
                        onSelected: (_) {
                          setModalState(() {
                            doseTime = time;
                            if (time == MedicineDoseTime.morning) timeString = '08:00 AM';
                            if (time == MedicineDoseTime.afternoon) timeString = '01:30 PM';
                            if (time == MedicineDoseTime.evening) timeString = '06:30 PM';
                            if (time == MedicineDoseTime.night) timeString = '09:00 PM';
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              const Text('Meal Relation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: MealTiming.values.map((meal) {
                  final isSel = mealTiming == meal;
                  String label = 'After';
                  if (meal == MealTiming.beforeFood) label = 'Before';
                  if (meal == MealTiming.withFood) label = 'With';
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ChoiceChip(
                        label: Text(label, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        onSelected: (_) => setModalState(() => mealTiming = meal),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      await _service.addReminder(
                        medicineName: nameController.text.trim(),
                        dosage: dosageController.text.trim(),
                        doseTime: doseTime,
                        mealTiming: mealTiming,
                        timeString: timeString,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Smart Medicine Reminders',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alarm_rounded, color: AppColors.primaryTeal),
            onPressed: () => _openAddReminderDialog(),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<MedicineReminder>>(
        valueListenable: _service.remindersNotifier,
        builder: (context, reminders, _) {
          final stats = _service.getAdherenceStats();

          final lowStockItems = reminders.where((r) => r.remainingPills <= r.refillThreshold).toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAdherenceCard(stats),
                if (lowStockItems.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Low Medicine Stock Alert',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lowStockItems.map((m) => "${m.medicineName} (${m.remainingPills} left)").join(", ")} running low. Refill soon!',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Medication Schedule',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${reminders.length} Active',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (reminders.isEmpty)
                  _buildEmptyState()
                else
                  ...reminders.map((rem) => _buildReminderCard(rem)),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddReminderDialog(),
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
    );
  }

  Widget _buildAdherenceCard(Map<String, dynamic> stats) {
    final streak = stats['streakDays'] as int? ?? 0;
    final percent = stats['adherencePercent'] as int? ?? 100;
    final taken = stats['takenCount'] as int? ?? 0;
    final total = stats['totalDoses'] as int? ?? 0;

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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$streak Day Adherence Streak!',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  '$percent% Compliance',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Today: $taken of $total doses logged on schedule.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? taken / total : 0.0,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(MedicineReminder rem) {
    final isTaken = rem.status == DoseStatus.taken;
    final isSkipped = rem.status == DoseStatus.skipped;
    final isSnoozed = rem.status == DoseStatus.snoozed;

    Color badgeBg = const Color(0xFFF1F5F9);
    Color badgeColor = const Color(0xFF475569);
    String statusText = 'Pending';

    if (isTaken) {
      badgeBg = const Color(0xFFECFDF5);
      badgeColor = const Color(0xFF047857);
      statusText = 'Taken';
    } else if (isSkipped) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeColor = const Color(0xFFDC2626);
      statusText = 'Skipped';
    } else if (isSnoozed) {
      badgeBg = const Color(0xFFFFFBEB);
      badgeColor = const Color(0xFFD97706);
      statusText = 'Snoozed +15m';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rem.medicineName,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${rem.dosage} • ${rem.timeString} (${rem.mealTimingLabel})',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rem.remainingPills <= rem.refillThreshold
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Supply: ${rem.remainingPills} pills left',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: rem.remainingPills <= rem.refillThreshold
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _service.refillPills(rem.id, 30),
                          child: const Text(
                            '+ Refill 30',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          if (rem.instructions != null) ...[
            const SizedBox(height: 8),
            Text(
              rem.instructions!,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isTaken) ...[
                TextButton(
                  onPressed: () => _service.snoozeDose(rem.id),
                  child: const Text('Snooze', style: TextStyle(fontSize: 11.5, color: Color(0xFFD97706))),
                ),
                TextButton(
                  onPressed: () => _service.markDoseSkipped(rem.id),
                  child: const Text('Skip', style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626))),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () => _service.markDoseTaken(rem.id),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Take Now', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ] else ...[
                Row(
                  children: const [
                    Icon(Icons.check_circle, size: 15, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('Logged on time', style: TextStyle(fontSize: 11.5, color: Color(0xFF047857))),
                  ],
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textSecondary),
                onPressed: () => _service.deleteReminder(rem.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: const [
          Icon(Icons.alarm_off_outlined, color: AppColors.textSecondary, size: 36),
          SizedBox(height: 8),
          Text(
            'No Medication Reminders Scheduled',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Tap "+ Add Medicine" or scan a medicine strip to set automated reminders.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
