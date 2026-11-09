import 'dart:math' as math;
import '../models/pose_landmark_model.dart';
import '../models/joint_angle_model.dart';

class JointAngleCalculator {
  // Exponential Moving Average (EMA) smoothing factors (0.0 = static, 1.0 = raw)
  static const double _smoothingAlpha = 0.65;

  double? _smoothLeftElbow;
  double? _smoothRightElbow;
  double? _smoothLeftShoulder;
  double? _smoothRightShoulder;
  double? _smoothLeftKnee;
  double? _smoothRightKnee;
  double? _smoothLeftHip;
  double? _smoothRightHip;
  double? _smoothTrunk;
  double? _smoothNeck;

  /// Resets smoothing filter between sessions
  void resetSmoothing() {
    _smoothLeftElbow = null;
    _smoothRightElbow = null;
    _smoothLeftShoulder = null;
    _smoothRightShoulder = null;
    _smoothLeftKnee = null;
    _smoothRightKnee = null;
    _smoothLeftHip = null;
    _smoothRightHip = null;
    _smoothTrunk = null;
    _smoothNeck = null;
  }

  /// Calculates bilateral joint angles from a 33-landmark pose frame
  JointAngleSnapshot calculateAngles(PoseDetectionFrame frame) {
    if (!frame.isPersonDetected) {
      return JointAngleSnapshot.empty();
    }

    // 1. Left Elbow (Shoulder -> Elbow -> Wrist)
    final rawLeftElbow = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.leftShoulder),
      frame.getLandmark(PoseLandmarkType.leftElbow),
      frame.getLandmark(PoseLandmarkType.leftWrist),
    );
    _smoothLeftElbow = _applyEMA(rawLeftElbow, _smoothLeftElbow);

    // 2. Right Elbow
    final rawRightElbow = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.rightShoulder),
      frame.getLandmark(PoseLandmarkType.rightElbow),
      frame.getLandmark(PoseLandmarkType.rightWrist),
    );
    _smoothRightElbow = _applyEMA(rawRightElbow, _smoothRightElbow);

    // 3. Left Shoulder (Hip -> Shoulder -> Elbow)
    final rawLeftShoulder = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.leftHip),
      frame.getLandmark(PoseLandmarkType.leftShoulder),
      frame.getLandmark(PoseLandmarkType.leftElbow),
    );
    _smoothLeftShoulder = _applyEMA(rawLeftShoulder, _smoothLeftShoulder);

    // 4. Right Shoulder
    final rawRightShoulder = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.rightHip),
      frame.getLandmark(PoseLandmarkType.rightShoulder),
      frame.getLandmark(PoseLandmarkType.rightElbow),
    );
    _smoothRightShoulder = _applyEMA(rawRightShoulder, _smoothRightShoulder);

    // 5. Left Knee (Hip -> Knee -> Ankle)
    final rawLeftKnee = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.leftHip),
      frame.getLandmark(PoseLandmarkType.leftKnee),
      frame.getLandmark(PoseLandmarkType.leftAnkle),
    );
    _smoothLeftKnee = _applyEMA(rawLeftKnee, _smoothLeftKnee);

    // 6. Right Knee
    final rawRightKnee = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.rightHip),
      frame.getLandmark(PoseLandmarkType.rightKnee),
      frame.getLandmark(PoseLandmarkType.rightAnkle),
    );
    _smoothRightKnee = _applyEMA(rawRightKnee, _smoothRightKnee);

    // 7. Left Hip (Shoulder -> Hip -> Knee)
    final rawLeftHip = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.leftShoulder),
      frame.getLandmark(PoseLandmarkType.leftHip),
      frame.getLandmark(PoseLandmarkType.leftKnee),
    );
    _smoothLeftHip = _applyEMA(rawLeftHip, _smoothLeftHip);

    // 8. Right Hip
    final rawRightHip = _calculateAngle(
      frame.getLandmark(PoseLandmarkType.rightShoulder),
      frame.getLandmark(PoseLandmarkType.rightHip),
      frame.getLandmark(PoseLandmarkType.rightKnee),
    );
    _smoothRightHip = _applyEMA(rawRightHip, _smoothRightHip);

    // 9. Trunk Inclination (Torso vector vs vertical)
    final rawTrunk = _calculateTrunkInclination(frame);
    _smoothTrunk = _applyEMA(rawTrunk, _smoothTrunk);

    // 10. Neck / Cervical Alignment (Ear to Shoulder vs vertical)
    final rawNeck = _calculateNeckAngle(frame);
    _smoothNeck = _applyEMA(rawNeck, _smoothNeck);

    return JointAngleSnapshot(
      leftElbowAngle: _smoothLeftElbow,
      rightElbowAngle: _smoothRightElbow,
      leftShoulderAngle: _smoothLeftShoulder,
      rightShoulderAngle: _smoothRightShoulder,
      leftKneeAngle: _smoothLeftKnee,
      rightKneeAngle: _smoothRightKnee,
      leftHipAngle: _smoothLeftHip,
      rightHipAngle: _smoothRightHip,
      trunkInclinationAngle: _smoothTrunk,
      neckTiltAngle: _smoothNeck,
      timestamp: frame.timestamp,
    );
  }

  /// Calculates angle ABC in degrees with B as vertex
  /// Returns null if any landmark has visibility < 0.50 (No hallucination!)
  double? _calculateAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
    if (a == null || b == null || c == null) return null;
    if (!a.isReliable || !b.isReliable || !c.isReliable) return null;

    final uX = a.x - b.x;
    final uY = a.y - b.y;
    final vX = c.x - b.x;
    final vY = c.y - b.y;

    final dotProduct = (uX * vX) + (uY * vY);
    final magU = math.sqrt((uX * uX) + (uY * uY));
    final magV = math.sqrt((vX * vX) + (vY * vY));

    if (magU == 0 || magV == 0) return null;

    double cosTheta = dotProduct / (magU * magV);
    cosTheta = cosTheta.clamp(-1.0, 1.0); // Numerical precision guard

    final radians = math.acos(cosTheta);
    return (radians * 180.0) / math.pi;
  }

  double? _calculateTrunkInclination(PoseDetectionFrame frame) {
    final ls = frame.getLandmark(PoseLandmarkType.leftShoulder);
    final rs = frame.getLandmark(PoseLandmarkType.rightShoulder);
    final lh = frame.getLandmark(PoseLandmarkType.leftHip);
    final rh = frame.getLandmark(PoseLandmarkType.rightHip);

    if (ls == null || rs == null || lh == null || rh == null) return null;
    if (!ls.isReliable || !rs.isReliable || !lh.isReliable || !rh.isReliable) return null;

    final shoulderMidX = (ls.x + rs.x) / 2.0;
    final shoulderMidY = (ls.y + rs.y) / 2.0;
    final hipMidX = (lh.x + rh.x) / 2.0;
    final hipMidY = (lh.y + rh.y) / 2.0;

    final dX = shoulderMidX - hipMidX;
    final dY = shoulderMidY - hipMidY; // Screen Y increases downwards

    // Angle relative to straight vertical
    final rad = math.atan2(dX.abs(), dY.abs());
    return (rad * 180.0) / math.pi;
  }

  double? _calculateNeckAngle(PoseDetectionFrame frame) {
    final nose = frame.getLandmark(PoseLandmarkType.nose);
    final ls = frame.getLandmark(PoseLandmarkType.leftShoulder);
    final rs = frame.getLandmark(PoseLandmarkType.rightShoulder);

    if (nose == null || ls == null || rs == null) return null;
    if (!nose.isReliable || !ls.isReliable || !rs.isReliable) return null;

    final midShoulderX = (ls.x + rs.x) / 2.0;
    final midShoulderY = (ls.y + rs.y) / 2.0;

    final dX = nose.x - midShoulderX;
    final dY = nose.y - midShoulderY;

    final rad = math.atan2(dX.abs(), dY.abs());
    return (rad * 180.0) / math.pi;
  }

  double? _applyEMA(double? current, double? previous) {
    if (current == null) return previous;
    if (previous == null) return current;
    return (_smoothingAlpha * current) + ((1.0 - _smoothingAlpha) * previous);
  }
}

