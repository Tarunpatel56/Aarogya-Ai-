import 'package:flutter/material.dart';
import '../models/exercise_biomechanics_config.dart';

class RepCounterWheel extends StatelessWidget {
  final int completedReps;
  final int targetReps;
  final ExercisePhase phase;
  final int elapsedSeconds;

  const RepCounterWheel({
    super.key,
    required this.completedReps,
    required this.targetReps,
    required this.phase,
    required this.elapsedSeconds,
  });

  String _formatElapsed(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _getPhaseLabel(ExercisePhase p) {
    switch (p) {
      case ExercisePhase.startingPosition:
        return 'READY';
      case ExercisePhase.inMotion:
        return 'MOVING';
      case ExercisePhase.targetReached:
        return 'PEAK';
      case ExercisePhase.returningToStart:
        return 'RETURN';
      case ExercisePhase.restPhase:
        return 'REST';
    }
  }

  Color _getPhaseColor(ExercisePhase p) {
    switch (p) {
      case ExercisePhase.targetReached:
        return const Color(0xFF10B981); // Emerald Green
      case ExercisePhase.inMotion:
        return const Color(0xFF3B82F6); // Blue
      case ExercisePhase.returningToStart:
        return const Color(0xFFF59E0B); // Amber
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = targetReps > 0 ? (completedReps / targetReps).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Progress Rep Dial
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4.5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                ),
                Text(
                  '$completedReps',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Rep Details & Phase Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TARGET: $targetReps REPS',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _getPhaseColor(phase).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _getPhaseColor(phase)),
                    ),
                    child: Text(
                      _getPhaseLabel(phase),
                      style: TextStyle(
                        color: _getPhaseColor(phase),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text(
                          _formatElapsed(elapsedSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

