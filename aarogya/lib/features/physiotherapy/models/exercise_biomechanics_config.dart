enum ExercisePhase {
  startingPosition,
  inMotion,
  targetReached,
  returningToStart,
  restPhase,
}

enum ExerciseType {
  squats('squats', 'Bodyweight Squats', 'Knee & Quadriceps Strengthening'),
  kneeExtensions('knee_extensions', 'Seated Knee Extensions', 'Quadriceps & Patella Rehab'),
  shoulderRaises('shoulder_raises', 'Shoulder Lateral Raises', 'Rotator Cuff & Deltoid Mobility'),
  armCurls('arm_curls', 'Bicep Arm Curls', 'Elbow Flexor Strengthening'),
  sideLegRaises('side_leg_raises', 'Standing Side Leg Raises', 'Hip Abductor & Balance'),
  standingKneeRaises('standing_knee_raises', 'Standing High Knee Raises', 'Hip Flexor & Core Mobility'),
  wallPushUps('wall_push_ups', 'Wall Push-Ups', 'Thoracic & Upper Body Decompression'),
  neckMovement('neck_movement', 'Cervical Retraction (Chin Tucks)', 'Deep Cervical Spine Relief');

  final String id;
  final String title;
  final String targetArea;
  const ExerciseType(this.id, this.title, this.targetArea);
}

class ExerciseBiomechanicsConfig {
  final ExerciseType exerciseType;
  final double startThresholdAngle;
  final double targetPeakAngle;
  final double returnThresholdAngle;
  final double? maxPermissibleTrunkLean; // Posture error if exceeded
  final String primaryJointName;
  final List<String> postureAlertRules;

  const ExerciseBiomechanicsConfig({
    required this.exerciseType,
    required this.startThresholdAngle,
    required this.targetPeakAngle,
    required this.returnThresholdAngle,
    this.maxPermissibleTrunkLean,
    required this.primaryJointName,
    required this.postureAlertRules,
  });

  static ExerciseBiomechanicsConfig getConfig(ExerciseType type) {
    switch (type) {
      case ExerciseType.squats:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.squats,
          startThresholdAngle: 160.0, // Standing straight
          targetPeakAngle: 95.0,      // Deep squat flexion <= 95 deg
          returnThresholdAngle: 150.0,
          maxPermissibleTrunkLean: 45.0,
          primaryJointName: 'Knee Angle',
          postureAlertRules: [
            'Keep your back straight and chest lifted.',
            'Do not let your knees cave inward.',
            'Sink your hips back as if sitting in a chair.',
          ],
        );

      case ExerciseType.kneeExtensions:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.kneeExtensions,
          startThresholdAngle: 90.0,  // Seated 90 deg
          targetPeakAngle: 160.0,     // Full extension >= 160 deg
          returnThresholdAngle: 105.0,
          primaryJointName: 'Knee Extension',
          postureAlertRules: [
            'Straighten your knee fully at the top.',
            'Hold the contraction for 1 second.',
            'Lower your leg smoothly without dropping.',
          ],
        );

      case ExerciseType.shoulderRaises:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.shoulderRaises,
          startThresholdAngle: 25.0,  // Arms resting down
          targetPeakAngle: 85.0,      // Raised parallel to floor (85 - 95 deg)
          returnThresholdAngle: 35.0,
          primaryJointName: 'Shoulder Angle',
          postureAlertRules: [
            'Do not shrug your neck or shoulders.',
            'Raise your arms slowly to shoulder height.',
            'Avoid swinging your torso.',
          ],
        );

      case ExerciseType.armCurls:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.armCurls,
          startThresholdAngle: 145.0, // Fully extended arm
          targetPeakAngle: 55.0,      // Fully curled arm <= 55 deg
          returnThresholdAngle: 135.0,
          primaryJointName: 'Elbow Angle',
          postureAlertRules: [
            'Keep your elbows pinned to your sides.',
            'Do not swing your body to lift.',
            'Lower all the way down under control.',
          ],
        );

      case ExerciseType.sideLegRaises:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.sideLegRaises,
          startThresholdAngle: 15.0,  // Neutral standing
          targetPeakAngle: 38.0,      // Abduction >= 38 deg
          returnThresholdAngle: 20.0,
          maxPermissibleTrunkLean: 20.0,
          primaryJointName: 'Hip Abduction',
          postureAlertRules: [
            'Keep your torso upright; avoid leaning to the side.',
            'Keep toes pointed forward, not outward.',
            'Engage your outer hip muscle.',
          ],
        );

      case ExerciseType.standingKneeRaises:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.standingKneeRaises,
          startThresholdAngle: 165.0, // Standing straight
          targetPeakAngle: 95.0,      // Knee up (hip flexed <= 95 deg)
          returnThresholdAngle: 150.0,
          primaryJointName: 'Hip Flexion',
          postureAlertRules: [
            'Lift your knee smoothly to hip height.',
            'Maintain your upright balance.',
            'Do not slouch your lower back.',
          ],
        );

      case ExerciseType.wallPushUps:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.wallPushUps,
          startThresholdAngle: 155.0, // Arms extended
          targetPeakAngle: 90.0,      // Chest toward wall (elbow <= 90 deg)
          returnThresholdAngle: 145.0,
          maxPermissibleTrunkLean: 25.0,
          primaryJointName: 'Elbow Flexion',
          postureAlertRules: [
            'Keep your body in a straight plank line.',
            'Do not sag your lower back.',
            'Lower your chest smoothly toward the wall.',
          ],
        );

      case ExerciseType.neckMovement:
        return const ExerciseBiomechanicsConfig(
          exerciseType: ExerciseType.neckMovement,
          startThresholdAngle: 175.0, // Neutral neck
          targetPeakAngle: 155.0,     // Chin retracted
          returnThresholdAngle: 170.0,
          primaryJointName: 'Cervical Retraction',
          postureAlertRules: [
            'Glide your chin straight backward horizontally.',
            'Do not look down or tilt your head.',
            'Breathe steadily while holding.',
          ],
        );
    }
  }
}

