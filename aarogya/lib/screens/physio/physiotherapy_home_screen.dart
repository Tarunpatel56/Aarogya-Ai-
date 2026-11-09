import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/physiotherapy_model.dart';
import '../../services/physiotherapy_service.dart';
import '../../features/physiotherapy/models/exercise_biomechanics_config.dart';
import '../../features/physiotherapy/screens/live_pose_exercise_screen.dart';

class PhysiotherapyHomeScreen extends StatefulWidget {
  final PhysiotherapyService? physioService;

  const PhysiotherapyHomeScreen({super.key, this.physioService});

  @override
  State<PhysiotherapyHomeScreen> createState() =>
      _PhysiotherapyHomeScreenState();
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

  ExerciseType _mapToExerciseType(PhysioExercise ex) {
    final id = ex.id.toLowerCase();
    if (id.contains('squat')) {
      return ExerciseType.squats;
    }
    if (id.contains('knee') || id.contains('quad')) {
      return ExerciseType.kneeExtensions;
    }
    if (id.contains('shoulder') || id.contains('scapular') || id.contains('pendulum')) {
      return ExerciseType.shoulderRaises;
    }
    if (id.contains('curl') || id.contains('bicep') || id.contains('arm')) {
      return ExerciseType.armCurls;
    }
    if (id.contains('leg_raise') || id.contains('side')) {
      return ExerciseType.sideLegRaises;
    }
    if (id.contains('high_knee') || id.contains('standing')) {
      return ExerciseType.standingKneeRaises;
    }
    if (id.contains('wall') || id.contains('push')) {
      return ExerciseType.wallPushUps;
    }
    if (id.contains('cervical') || id.contains('trapezius') || id.contains('neck')) {
      return ExerciseType.neckMovement;
    }
    return ExerciseType.squats;
  }

  void _startLiveAiExercise(ExerciseType type, {int reps = 10}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivePoseExerciseScreen(
          exerciseType: type,
          targetReps: reps,
        ),
      ),
    );
  }

  void _startExercise(PhysioExercise ex) {
    final type = _mapToExerciseType(ex);
    _startLiveAiExercise(type, reps: ex.targetReps);
  }

  @override
  Widget build(BuildContext context) {
    final exercises = _service.getExercises(
      area: _selectedArea,
      goal: _selectedGoal,
    );
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
                _buildMediaPipeStudioCard(),
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
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.primaryTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '7-Day Rehabilitation Activity',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                '$sessionsCount',
                'Sessions',
                Icons.check_circle_outline,
              ),
              Container(width: 1, height: 30, color: AppColors.cardBorder),
              _buildMetricItem(
                '$totalMins min',
                'Total Time',
                Icons.timer_outlined,
              ),
              Container(width: 1, height: 30, color: AppColors.cardBorder),
              _buildMetricItem(
                '$avgPain / 10',
                'Avg Pain',
                Icons.healing_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPipeStudioCard() {
    final liveExercises = [
      {
        'type': ExerciseType.squats,
        'label': 'Squats',
        'icon': Icons.accessibility_new_rounded,
      },
      {
        'type': ExerciseType.kneeExtensions,
        'label': 'Knee Ext.',
        'icon': Icons.airline_seat_recline_normal_rounded,
      },
      {
        'type': ExerciseType.shoulderRaises,
        'label': 'Shoulder Raises',
        'icon': Icons.pan_tool_rounded,
      },
      {
        'type': ExerciseType.armCurls,
        'label': 'Arm Curls',
        'icon': Icons.fitness_center_rounded,
      },
      {
        'type': ExerciseType.sideLegRaises,
        'label': 'Side Leg Raises',
        'icon': Icons.directions_run_rounded,
      },
      {
        'type': ExerciseType.standingKneeRaises,
        'label': 'High Knees',
        'icon': Icons.hiking_rounded,
      },
      {
        'type': ExerciseType.wallPushUps,
        'label': 'Wall Push-Ups',
        'icon': Icons.view_sidebar_rounded,
      },
      {
        'type': ExerciseType.neckMovement,
        'label': 'Chin Tucks',
        'icon': Icons.person_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF00E5FF),
                    child: Icon(Icons.bolt, color: Color(0xFF0F172A), size: 18),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'AI Motion Tracking Studio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF00E676),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'MediaPipe Lite 30 FPS',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'On-device 33 landmark skeleton tracking, automatic rep counting & live voice biomechanics coaching.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: liveExercises.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final item = liveExercises[idx];
                final type = item['type'] as ExerciseType;
                final label = item['label'] as String;
                final icon = item['icon'] as IconData;

                return InkWell(
                  onTap: () => _startLiveAiExercise(type),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: const Color(0xFF00E5FF), size: 22),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${plan.estimatedDurationMinutes} mins',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            Text(
                              '${plan.exercises.length} Exercises',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          plan.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          plan.subtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Routine',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                color: isSelected
                    ? AppColors.primaryTeal
                    : AppColors.textPrimary,
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${exercises.length} Exercises',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
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
                    child: const Icon(
                      Icons.accessibility_new_rounded,
                      color: AppColors.primaryTeal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${ex.bodyAreaLabel} • ${ex.targetReps} reps • ${ex.durationSeconds}s',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _startExercise(ex),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildSessionHistorySection(List<PhysioSessionLog> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Completed Session History',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
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
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Duration: ${log.durationSeconds}s • ${log.completedReps} reps • VAS Pain: ${log.painRating}/10',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      log.difficultyLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF475569),
                      ),
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
