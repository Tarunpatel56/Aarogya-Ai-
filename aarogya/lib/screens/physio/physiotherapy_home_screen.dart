import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/physiotherapy_model.dart';
import '../../services/physiotherapy_service.dart';
import 'exercise_session_screen.dart';

class PhysiotherapyHomeScreen extends StatefulWidget {
  final PhysiotherapyService? physioService;

  const PhysiotherapyHomeScreen({super.key, this.physioService});

  @override
  State<PhysiotherapyHomeScreen> createState() => _PhysiotherapyHomeScreenState();
}

class _PhysiotherapyHomeScreenState extends State<PhysiotherapyHomeScreen> {
  late final PhysiotherapyService _service;
  BodyArea? _selectedArea;
  ExerciseGoal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _service = widget.physioService ?? PhysiotherapyService();
    _service.init();
  }

  void _startExercise(PhysioExercise ex) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSessionScreen(
          exercise: ex,
          physioService: _service,
        ),
      ),
    );

    if (completed == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Physiotherapy session recorded in your medical health log!'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _service.getExercises(area: _selectedArea, goal: _selectedGoal);
    final plans = _service.getDailyPlans();
    final progress = _service.getWeeklyProgress();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Physiotherapy & Rehab',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<PhysioSessionLog>>(
        valueListenable: _service.sessionHistoryNotifier,
        builder: (context, history, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressHeader(progress),
                const SizedBox(height: 18),
                _buildDailyPlansSection(plans),
                const SizedBox(height: 18),
                _buildFilterChips(),
                const SizedBox(height: 14),
                _buildExerciseLibrary(exercises),
                const SizedBox(height: 20),
                if (history.isNotEmpty) _buildSessionHistorySection(history),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader(Map<String, dynamic> progress) {
    final sessionsCount = progress['completedSessionsCount'] as int? ?? 0;
    final totalMins = progress['totalMinutes'] as int? ?? 0;
    final avgPain = progress['averagePainScore'] as double? ?? 0.0;

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
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center_rounded, color: AppColors.primaryTeal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '7-Day Rehabilitation Activity',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('$sessionsCount', 'Sessions', Icons.check_circle_outline),
              Container(width: 1, height: 30, color: AppColors.cardBorder),
              _buildMetricItem('$totalMins min', 'Total Time', Icons.timer_outlined),
              Container(width: 1, height: 30, color: AppColors.cardBorder),
              _buildMetricItem('$avgPain / 10', 'Avg Pain', Icons.healing_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryTeal),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDailyPlansSection(List<PhysioPlan> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Guided Rehabilitation Plans',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: plans.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final plan = plans[idx];
              return Container(
                width: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${plan.estimatedDurationMinutes} mins',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                              ),
                            ),
                            Text(
                              '${plan.exercises.length} Exercises',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          plan.subtitle,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: () {
                          if (plan.exercises.isNotEmpty) {
                            _startExercise(plan.exercises.first);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Start Routine', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final areas = [
      {'label': 'All Areas', 'area': null},
      {'label': 'Neck', 'area': BodyArea.neck},
      {'label': 'Lower Back', 'area': BodyArea.lowerBack},
      {'label': 'Shoulder', 'area': BodyArea.shoulder},
      {'label': 'Knee', 'area': BodyArea.knee},
      {'label': 'Posture', 'area': BodyArea.posture},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: areas.map((item) {
          final isSelected = _selectedArea == item['area'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(item['label'] as String),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedArea = item['area'] as BodyArea?);
              },
              selectedColor: const Color(0xFFE0F2F1),
              checkmarkColor: AppColors.primaryTeal,
              labelStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseLibrary(List<PhysioExercise> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Exercise Library',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              '${exercises.length} Exercises',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: exercises.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, idx) {
            final ex = exercises[idx];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.accessibility_new_rounded, color: AppColors.primaryTeal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${ex.bodyAreaLabel} • ${ex.targetReps} reps • ${ex.durationSeconds}s',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _startExercise(ex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionHistorySection(List<PhysioSessionLog> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Completed Session History',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.take(4).length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final log = history[idx];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
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
                          log.exerciseTitle,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Duration: ${log.durationSeconds}s • ${log.completedReps} reps • VAS Pain: ${log.painRating}/10',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      log.difficultyLabel,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
