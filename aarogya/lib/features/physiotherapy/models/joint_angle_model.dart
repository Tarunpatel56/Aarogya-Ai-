class JointAngleSnapshot {
  final double? leftElbowAngle;
  final double? rightElbowAngle;
  final double? leftShoulderAngle;
  final double? rightShoulderAngle;
  final double? leftKneeAngle;
  final double? rightKneeAngle;
  final double? leftHipAngle;
  final double? rightHipAngle;
  final double? trunkInclinationAngle; // Torso vs Vertical
  final double? neckTiltAngle;
  final DateTime timestamp;

  const JointAngleSnapshot({
    this.leftElbowAngle,
    this.rightElbowAngle,
    this.leftShoulderAngle,
    this.rightShoulderAngle,
    this.leftKneeAngle,
    this.rightKneeAngle,
    this.leftHipAngle,
    this.rightHipAngle,
    this.trunkInclinationAngle,
    this.neckTiltAngle,
    required this.timestamp,
  });

  factory JointAngleSnapshot.empty() => JointAngleSnapshot(timestamp: DateTime.now());

  Map<String, dynamic> toJson() => {
        'leftElbow': leftElbowAngle?.round(),
        'rightElbow': rightElbowAngle?.round(),
        'leftShoulder': leftShoulderAngle?.round(),
        'rightShoulder': rightShoulderAngle?.round(),
        'leftKnee': leftKneeAngle?.round(),
        'rightKnee': rightKneeAngle?.round(),
        'leftHip': leftHipAngle?.round(),
        'rightHip': rightHipAngle?.round(),
        'trunkInclination': trunkInclinationAngle?.round(),
        'neckTilt': neckTiltAngle?.round(),
        'timestamp': timestamp.toIso8601String(),
      };
}

