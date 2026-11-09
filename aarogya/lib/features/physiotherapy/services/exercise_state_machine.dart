import '../models/exercise_biomechanics_config.dart';
import '../models/joint_angle_model.dart';
import '../models/pose_landmark_model.dart';

class ExerciseRepetitionEvent {
  final int completedReps;
  final double currentAngle;
  final double peakAngleReached;
  final ExercisePhase phase;
  final bool isGoodForm;
  final String? feedbackMessage;

  const ExerciseRepetitionEvent({
    required this.completedReps,
    required this.currentAngle,
    required this.peakAngleReached,
    required this.phase,
    required this.isGoodForm,
    this.feedbackMessage,
  });
}

class ExerciseStateMachine {
  final ExerciseType exerciseType;
  final ExerciseBiomechanicsConfig config;

  int _repsCount = 0;
  ExercisePhase _currentPhase = ExercisePhase.startingPosition;
  double _peakAngleInCurrentRep = 0.0;
  final List<String> _currentRepErrors = [];
  final List<String> _allSessionErrors = [];
  final List<double> _repAccuracies = [];

  int get repsCount => _repsCount;
  ExercisePhase get currentPhase => _currentPhase;
  List<String> get allSessionErrors => List.unmodifiable(_allSessionErrors);
  List<String> get currentRepErrors => List.unmodifiable(_currentRepErrors);
  bool get hasActivePostureError => _currentRepErrors.isNotEmpty;

  ExerciseStateMachine({required this.exerciseType})
      : config = ExerciseBiomechanicsConfig.getConfig(exerciseType);

  void reset() {
    _repsCount = 0;
    _currentPhase = ExercisePhase.startingPosition;
    _peakAngleInCurrentRep = 0.0;
    _currentRepErrors.clear();
    _allSessionErrors.clear();
    _repAccuracies.clear();
  }

  /// Calculates overall form accuracy percentage for session
  double get overallAccuracyScore {
    if (_repAccuracies.isEmpty) return 92.0;
    final sum = _repAccuracies.reduce((a, b) => a + b);
    return (sum / _repAccuracies.length).clamp(50.0, 100.0);
  }

  /// Processes each incoming frame angles and updates repetition counter
  ExerciseRepetitionEvent processFrame({
    required JointAngleSnapshot angles,
    required PoseDetectionFrame frame,
  }) {
    final double? monitoredAngle = _getMonitoredAngle(angles);

    if (monitoredAngle == null) {
      return ExerciseRepetitionEvent(
        completedReps: _repsCount,
        currentAngle: 0.0,
        peakAngleReached: _peakAngleInCurrentRep,
        phase: _currentPhase,
        isGoodForm: false,
        feedbackMessage: 'Please adjust your position; keep key joints in frame.',
      );
    }

    // Posture Error Audit
    _auditPosture(angles, frame);

    String? feedback;
    bool isGoodRep = _currentRepErrors.isEmpty;

    switch (exerciseType) {
      case ExerciseType.squats:
        feedback = _handleDecreasingAngleExercise(
          currentAngle: monitoredAngle,
          startAngle: config.startThresholdAngle,
          targetAngle: config.targetPeakAngle,
          returnAngle: config.returnThresholdAngle,
          targetReachedCue: 'Great depth! Now push back up.',
          returnStartCue: 'Standing tall. Get ready for next rep.',
        );
        break;

      case ExerciseType.kneeExtensions:
      case ExerciseType.shoulderRaises:
      case ExerciseType.sideLegRaises:
        feedback = _handleIncreasingAngleExercise(
          currentAngle: monitoredAngle,
          startAngle: config.startThresholdAngle,
          targetAngle: config.targetPeakAngle,
          returnAngle: config.returnThresholdAngle,
          targetReachedCue: 'Hold at top! Lower down slowly.',
          returnStartCue: 'Starting position reset. Next rep.',
        );
        break;

      case ExerciseType.armCurls:
      case ExerciseType.wallPushUps:
      case ExerciseType.neckMovement:
        feedback = _handleDecreasingAngleExercise(
          currentAngle: monitoredAngle,
          startAngle: config.startThresholdAngle,
          targetAngle: config.targetPeakAngle,
          returnAngle: config.returnThresholdAngle,
          targetReachedCue: 'Good peak contraction! Extend back slowly.',
          returnStartCue: 'Arm extended. Good control.',
        );
        break;

      case ExerciseType.standingKneeRaises:
        feedback = _handleDecreasingAngleExercise(
          currentAngle: monitoredAngle,
          startAngle: config.startThresholdAngle,
          targetAngle: config.targetPeakAngle,
          returnAngle: config.returnThresholdAngle,
          targetReachedCue: 'High knee reached! Lower smoothly.',
          returnStartCue: 'Foot planted. Lift again.',
        );
        break;
    }

    final activeCue = feedback ?? (_currentRepErrors.isNotEmpty ? _currentRepErrors.last : null);

    return ExerciseRepetitionEvent(
      completedReps: _repsCount,
      currentAngle: monitoredAngle,
      peakAngleReached: _peakAngleInCurrentRep,
      phase: _currentPhase,
      isGoodForm: isGoodRep,
      feedbackMessage: activeCue,
    );
  }

  /// State machine for flexion/decreasing angles (e.g. Squat 170 deg down to 90 deg)
  String? _handleDecreasingAngleExercise({
    required double currentAngle,
    required double startAngle,
    required double targetAngle,
    required double returnAngle,
    required String targetReachedCue,
    required String returnStartCue,
  }) {
    String? cue;

    switch (_currentPhase) {
      case ExercisePhase.startingPosition:
        if (currentAngle >= startAngle - 10) {
          _currentPhase = ExercisePhase.inMotion;
          _peakAngleInCurrentRep = currentAngle;
          _currentRepErrors.clear();
        }
        break;

      case ExercisePhase.inMotion:
        if (currentAngle < _peakAngleInCurrentRep) {
          _peakAngleInCurrentRep = currentAngle;
        }

        if (currentAngle <= targetAngle) {
          _currentPhase = ExercisePhase.targetReached;
          cue = targetReachedCue;
        }
        break;

      case ExercisePhase.targetReached:
        if (currentAngle > targetAngle + 15) {
          _currentPhase = ExercisePhase.returningToStart;
        }
        break;

      case ExercisePhase.returningToStart:
        if (currentAngle >= returnAngle) {
          if (_currentRepErrors.isEmpty) {
            // Clean repetition completed
            _repsCount++;
            _repAccuracies.add(100.0);
            cue = 'Good repetition! Rep $_repsCount completed. $returnStartCue';
          } else {
            // Posture was poor, do not count fake rep!
            final err = _currentRepErrors.last;
            cue = 'Posture error: $err. Rep not counted.';
            _repAccuracies.add(60.0);
          }
          _currentPhase = ExercisePhase.startingPosition;
          _currentRepErrors.clear();
        }
        break;

      case ExercisePhase.restPhase:
        if (currentAngle >= startAngle - 10) {
          _currentPhase = ExercisePhase.startingPosition;
        }
        break;
    }

    return cue;
  }

  /// State machine for extension/increasing angles (e.g. Shoulder Raise 20 deg up to 90 deg)
  String? _handleIncreasingAngleExercise({
    required double currentAngle,
    required double startAngle,
    required double targetAngle,
    required double returnAngle,
    required String targetReachedCue,
    required String returnStartCue,
  }) {
    String? cue;

    switch (_currentPhase) {
      case ExercisePhase.startingPosition:
        if (currentAngle <= startAngle + 10) {
          _currentPhase = ExercisePhase.inMotion;
          _peakAngleInCurrentRep = currentAngle;
          _currentRepErrors.clear();
        }
        break;

      case ExercisePhase.inMotion:
        if (currentAngle > _peakAngleInCurrentRep) {
          _peakAngleInCurrentRep = currentAngle;
        }

        if (currentAngle >= targetAngle) {
          _currentPhase = ExercisePhase.targetReached;
          cue = targetReachedCue;
        }
        break;

      case ExercisePhase.targetReached:
        if (currentAngle < targetAngle - 15) {
          _currentPhase = ExercisePhase.returningToStart;
        }
        break;

      case ExercisePhase.returningToStart:
        if (currentAngle <= returnAngle) {
          if (_currentRepErrors.isEmpty) {
            // Clean repetition completed
            _repsCount++;
            _repAccuracies.add(100.0);
            cue = 'Good repetition! Rep $_repsCount completed. $returnStartCue';
          } else {
            // Posture was poor, do not count fake rep!
            final err = _currentRepErrors.last;
            cue = 'Posture error: $err. Rep not counted.';
            _repAccuracies.add(60.0);
          }
          _currentPhase = ExercisePhase.startingPosition;
          _currentRepErrors.clear();
        }
        break;

      case ExercisePhase.restPhase:
        if (currentAngle <= startAngle + 10) {
          _currentPhase = ExercisePhase.startingPosition;
        }
        break;
    }

    return cue;
  }

  double? _getMonitoredAngle(JointAngleSnapshot angles) {
    switch (exerciseType) {
      case ExerciseType.squats:
        // Use average of both knees or whichever is most clearly visible
        final lk = angles.leftKneeAngle;
        final rk = angles.rightKneeAngle;
        if (lk != null && rk != null) return (lk + rk) / 2.0;
        return lk ?? rk;

      case ExerciseType.kneeExtensions:
        return angles.rightKneeAngle ?? angles.leftKneeAngle;

      case ExerciseType.shoulderRaises:
        final ls = angles.leftShoulderAngle;
        final rs = angles.rightShoulderAngle;
        if (ls != null && rs != null) return (ls + rs) / 2.0;
        return rs ?? ls;

      case ExerciseType.armCurls:
        return angles.rightElbowAngle ?? angles.leftElbowAngle;

      case ExerciseType.sideLegRaises:
        // Hip abduction (Leg angle relative to torso vertical)
        return angles.rightHipAngle != null
            ? (180.0 - angles.rightHipAngle!).abs()
            : (angles.leftHipAngle != null ? (180.0 - angles.leftHipAngle!).abs() : null);

      case ExerciseType.standingKneeRaises:
        return angles.rightHipAngle ?? angles.leftHipAngle;

      case ExerciseType.wallPushUps:
        final le = angles.leftElbowAngle;
        final re = angles.rightElbowAngle;
        if (le != null && re != null) return (le + re) / 2.0;
        return re ?? le;

      case ExerciseType.neckMovement:
        return angles.neckTiltAngle;
    }
  }

  void _auditPosture(JointAngleSnapshot angles, PoseDetectionFrame frame) {
    // 1. Trunk Excessive Forward Lean Check (55 deg threshold for clinical natural movement)
    if (config.maxPermissibleTrunkLean != null && angles.trunkInclinationAngle != null) {
      final double maxLean = config.maxPermissibleTrunkLean! + 10.0;
      if (angles.trunkInclinationAngle! > maxLean) {
        const err = 'Keep your back straight; avoid excessive forward lean.';
        if (!_currentRepErrors.contains(err)) {
          _currentRepErrors.add(err);
          if (!_allSessionErrors.contains(err)) _allSessionErrors.add(err);
        }
      }
    }

    // 2. Head Tilt Check in Standing Exercises (Permits natural gaze toward smartphone preview)
    if (angles.neckTiltAngle != null && angles.neckTiltAngle! > 55.0 && exerciseType != ExerciseType.neckMovement) {
      const err = 'Keep your neck aligned and chin tucked.';
      if (!_currentRepErrors.contains(err)) {
        _currentRepErrors.add(err);
        if (!_allSessionErrors.contains(err)) _allSessionErrors.add(err);
      }
    }
  }
}

