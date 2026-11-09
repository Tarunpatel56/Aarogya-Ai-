import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/physiotherapy_model.dart';
import '../../services/physiotherapy_service.dart';
import 'session_feedback_dialog.dart';

class ExerciseSessionScreen extends StatefulWidget {
  final PhysioExercise exercise;
  final PhysiotherapyService? physioService;

  const ExerciseSessionScreen({
    super.key,
    required this.exercise,
    this.physioService,
  });

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen> {
  late final PhysiotherapyService _service;
  Timer? _timer;
  int _secondsRemaining = 60;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  int _currentReps = 0;
  int _currentStepIndex = 0;
  bool _audioCuesEnabled = false;

  @override
  void initState() {
    super.initState();
    _service = widget.physioService ?? PhysiotherapyService();
    _secondsRemaining = widget.exercise.durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
            _elapsedSeconds++;
          });
        } else {
          timer.cancel();
          setState(() => _isRunning = false);
          _finishSession();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = widget.exercise.durationSeconds;
      _elapsedSeconds = 0;
      _currentReps = 0;
    });
  }

  void _incrementReps() {
    setState(() {
      _currentReps++;
    });
  }

  void _decrementReps() {
    if (_currentReps > 0) {
      setState(() {
        _currentReps--;
      });
    }
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    final duration = _elapsedSeconds > 0 ? _elapsedSeconds : 1;

    final feedback = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionFeedbackDialog(
        exercise: widget.exercise,
        durationSeconds: duration,
        completedReps: _currentReps > 0 ? _currentReps : widget.exercise.targetReps,
      ),
    );

    if (feedback != null && mounted) {
      await _service.logCompletedSession(
        exercise: widget.exercise,
        durationSeconds: duration,
        completedReps: _currentReps > 0 ? _currentReps : widget.exercise.targetReps,
        painRating: feedback['painRating'] as int? ?? 0,
        difficulty: feedback['difficulty'] as SessionDifficulty? ?? SessionDifficulty.justRight,
        userNotes: feedback['notes'] as String?,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final progress = ex.durationSeconds > 0
        ? (ex.durationSeconds - _secondsRemaining) / ex.durationSeconds
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          ex.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Audio Cues',
            icon: Icon(
              _audioCuesEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _audioCuesEnabled ? AppColors.primaryTeal : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _audioCuesEnabled = !_audioCuesEnabled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_audioCuesEnabled
                      ? 'Audio pace cues enabled (chime & voice prompts).'
                      : 'Audio cues muted.'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer and Circular Counter Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ex.bodyAreaLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ex.goalLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Circular / Linear Progress Timer
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 10,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_secondsRemaining}s',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Remaining',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Timer Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.replay_rounded),
                        tooltip: 'Reset Timer',
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton.icon(
                        onPressed: _toggleTimer,
                        icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: Text(_isRunning ? 'Pause' : 'Start Timer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton.filledTonal(
                        onPressed: _finishSession,
                        icon: const Icon(Icons.check_rounded, color: Color(0xFF047857)),
                        tooltip: 'Finish Session',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Repetition Counter Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Repetitions Completed',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Target: ${ex.targetReps} reps • Tap to count',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                        onPressed: _decrementReps,
                      ),
                      Text(
                        '$_currentReps',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primaryTeal),
                        onPressed: _incrementReps,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Guided Step-by-Step Instructions
            Container(
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
                      const Text(
                        'Step-by-Step Execution',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Step ${_currentStepIndex + 1} of ${ex.instructions.length}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Current highlighted step
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      ex.instructions.isNotEmpty ? ex.instructions[_currentStepIndex] : 'Perform controlled reps.',
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.45, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Carousel navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _currentStepIndex > 0
                            ? () => setState(() => _currentStepIndex--)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Previous Step'),
                      ),
                      TextButton.icon(
                        onPressed: _currentStepIndex < ex.instructions.length - 1
                            ? () => setState(() => _currentStepIndex++)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Next Step'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Breathing & Posture Guidance Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.air_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Breathing & Alignment Cadence',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ex.breathingNotes,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF14532D), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Clinical Safety & Honest Tracking Disclosure
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Rehabilitation Safety Notice',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ex.safetyGuidance,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F), height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Notice: This exercise session provides guided timers and clinical cues. It does not measure camera-based joint angles. Follow your physical therapist\'s specific precautions.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
