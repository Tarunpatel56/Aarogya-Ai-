enum PoseLandmarkType {
  nose('Nose'),
  leftEyeInner('Left Eye Inner'),
  leftEye('Left Eye'),
  leftEyeOuter('Left Eye Outer'),
  rightEyeInner('Right Eye Inner'),
  rightEye('Right Eye'),
  rightEyeOuter('Right Eye Outer'),
  leftEar('Left Ear'),
  rightEar('Right Ear'),
  mouthLeft('Mouth Left'),
  mouthRight('Mouth Right'),
  leftShoulder('Left Shoulder'),
  rightShoulder('Right Shoulder'),
  leftElbow('Left Elbow'),
  rightElbow('Right Elbow'),
  leftWrist('Left Wrist'),
  rightWrist('Right Wrist'),
  leftPinky('Left Pinky'),
  rightPinky('Right Pinky'),
  leftIndex('Left Index'),
  rightIndex('Right Index'),
  leftThumb('Left Thumb'),
  rightThumb('Right Thumb'),
  leftHip('Left Hip'),
  rightHip('Right Hip'),
  leftKnee('Left Knee'),
  rightKnee('Right Knee'),
  leftAnkle('Left Ankle'),
  rightAnkle('Right Ankle'),
  leftHeel('Left Heel'),
  rightHeel('Right Heel'),
  leftFootIndex('Left Foot Index'),
  rightFootIndex('Right Foot Index');

  final String displayName;
  const PoseLandmarkType(this.displayName);

  static PoseLandmarkType fromIndex(int idx) {
    if (idx >= 0 && idx < PoseLandmarkType.values.length) {
      return PoseLandmarkType.values[idx];
    }
    return PoseLandmarkType.nose;
  }
}

class PoseLandmark {
  final int index;
  final String name;
  final double x; // Normalized [0.0, 1.0]
  final double y; // Normalized [0.0, 1.0]
  final double z; // Depth estimate relative to hips
  final double visibility; // [0.0, 1.0]
  final double presence;

  const PoseLandmark({
    required this.index,
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    this.presence = 1.0,
  });

  bool get isReliable => visibility >= 0.50;

  factory PoseLandmark.fromJson(Map<String, dynamic> json) {
    return PoseLandmark(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      z: (json['z'] as num?)?.toDouble() ?? 0.0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 0.0,
      presence: (json['presence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'x': x,
        'y': y,
        'z': z,
        'visibility': visibility,
        'presence': presence,
      };
}

class PoseDetectionFrame {
  final List<PoseLandmark> landmarks;
  final int inferenceTimeMs;
  final String delegate; // "GPU" or "CPU"
  final DateTime timestamp;
  final bool isPersonDetected;

  const PoseDetectionFrame({
    required this.landmarks,
    required this.inferenceTimeMs,
    required this.delegate,
    required this.timestamp,
    required this.isPersonDetected,
  });

  PoseLandmark? getLandmark(PoseLandmarkType type) {
    for (final lm in landmarks) {
      if (lm.index == type.index) return lm;
    }
    return null;
  }

  bool isLandmarkVisible(PoseLandmarkType type, {double threshold = 0.50}) {
    final lm = getLandmark(type);
    return lm != null && lm.visibility >= threshold;
  }

  /// Checks if upper body is fully within camera view
  bool get isUpperBodyVisible {
    return isLandmarkVisible(PoseLandmarkType.leftShoulder) &&
        isLandmarkVisible(PoseLandmarkType.rightShoulder) &&
        isLandmarkVisible(PoseLandmarkType.leftElbow) &&
        isLandmarkVisible(PoseLandmarkType.rightElbow);
  }

  /// Checks if lower body is fully within camera view
  bool get isLowerBodyVisible {
    return isLandmarkVisible(PoseLandmarkType.leftHip) &&
        isLandmarkVisible(PoseLandmarkType.rightHip) &&
        isLandmarkVisible(PoseLandmarkType.leftKnee) &&
        isLandmarkVisible(PoseLandmarkType.rightKnee) &&
        isLandmarkVisible(PoseLandmarkType.leftAnkle) &&
        isLandmarkVisible(PoseLandmarkType.rightAnkle);
  }

  /// Checks if full body (shoulders down to ankles) is within camera view
  bool get isFullBodyVisible => isUpperBodyVisible && isLowerBodyVisible;

  factory PoseDetectionFrame.empty() {
    return PoseDetectionFrame(
      landmarks: const [],
      inferenceTimeMs: 0,
      delegate: 'NONE',
      timestamp: DateTime.now(),
      isPersonDetected: false,
    );
  }
}
