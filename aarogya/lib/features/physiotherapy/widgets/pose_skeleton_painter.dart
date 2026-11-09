import 'package:flutter/material.dart';
import '../models/pose_landmark_model.dart';

class PoseSkeletonPainter extends CustomPainter {
  final PoseDetectionFrame frame;
  final bool isFrontCamera;
  final bool hasPostureError;

  // Complete anatomical 33-landmark skeleton connection pairs
  static const List<List<int>> skeletonConnections = [
    // Head / Facial Features
    [0, 1], [1, 2], [2, 3], [3, 7], // Left Eye & Ear
    [0, 4], [4, 5], [5, 6], [6, 8], // Right Eye & Ear
    [9, 10], // Mouth
    // Torso Frame
    [11, 12], // Shoulder span
    [11, 23], // Left torso (Shoulder to Hip)
    [12, 24], // Right torso (Shoulder to Hip)
    [23, 24], // Pelvis / Hip span
    // Left Arm & Hand
    [11, 13], // Left Shoulder to Left Elbow
    [13, 15], // Left Elbow to Left Wrist
    [15, 17], // Left Wrist to Pinky
    [15, 19], // Left Wrist to Index
    [15, 21], // Left Wrist to Thumb
    // Right Arm & Hand
    [12, 14], // Right Shoulder to Right Elbow
    [14, 16], // Right Elbow to Right Wrist
    [16, 18], // Right Wrist to Pinky
    [16, 20], // Right Wrist to Index
    [16, 22], // Right Wrist to Thumb
    // Left Leg & Foot
    [23, 25], // Left Hip to Left Knee
    [25, 27], // Left Knee to Left Ankle
    [27, 29], // Left Ankle to Left Heel
    [27, 31], // Left Ankle to Foot Index
    [29, 31], // Left Heel to Foot Index
    // Right Leg & Foot
    [24, 26], // Right Hip to Right Knee
    [26, 28], // Right Knee to Right Ankle
    [28, 30], // Right Ankle to Right Heel
    [28, 32], // Right Ankle to Foot Index
    [30, 32], // Right Heel to Foot Index
  ];

  PoseSkeletonPainter({
    required this.frame,
    this.isFrontCamera = true,
    this.hasPostureError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!frame.isPersonDetected || frame.landmarks.isEmpty) return;

    // Biomechanical Color Feedback:
    // Good Posture: Neon Medical Cyan (#00E5FF) + Neon Green (#00E676)
    // Posture Error: Glowing Coral Red (#FF3D00) + Warning Orange (#FFA000)
    final Color boneColor = hasPostureError
        ? const Color(0xFFFF3D00)
        : const Color(0xFF00E5FF);

    final Color jointColor = hasPostureError
        ? const Color(0xFFFF9100)
        : const Color(0xFF00E676);

    // 1. Paints for Bone Lines
    final glowBonePaint = Paint()
      ..color = boneColor.withValues(alpha: 0.35)
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final solidBonePaint = Paint()
      ..color = boneColor.withValues(alpha: 0.95)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 2. Paints for Glowing Joints (Dots)
    final jointGlowPaint = Paint()
      ..color = jointColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final jointFillPaint = Paint()
      ..color = jointColor
      ..style = PaintingStyle.fill;

    final jointCorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 3. Map landmark coordinates (X mirrored if front camera)
    final Map<int, Offset> points = {};
    for (final lm in frame.landmarks) {
      if (lm.visibility >= 0.35) {
        final double xNorm = isFrontCamera ? (1.0 - lm.x) : lm.x;
        final double yNorm = lm.y;

        final px = xNorm * size.width;
        final py = yNorm * size.height;
        points[lm.index] = Offset(px, py);
      }
    }

    // 4. Draw Connecting Bones (Lines)
    for (final connection in skeletonConnections) {
      final p1 = points[connection[0]];
      final p2 = points[connection[1]];

      if (p1 != null && p2 != null) {
        // Draw soft outer glow line
        canvas.drawLine(p1, p2, glowBonePaint);
        // Draw crisp solid inner line
        canvas.drawLine(p1, p2, solidBonePaint);
      }
    }

    // 5. Draw Glowing Joints (Dots)
    for (final entry in points.entries) {
      final pt = entry.value;
      final idx = entry.key;

      // Major kinematic joints (shoulders, elbows, wrists, hips, knees, ankles)
      final isMajorJoint = [11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28].contains(idx);
      final double radius = isMajorJoint ? 6.0 : 4.0;

      // Layer 1: Translucent Glow Halo
      canvas.drawCircle(pt, radius + 4.5, jointGlowPaint);
      // Layer 2: Solid Colored Joint Disc
      canvas.drawCircle(pt, radius, jointFillPaint);
      // Layer 3: High-contrast White Center Point
      canvas.drawCircle(pt, radius * 0.45, jointCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.hasPostureError != hasPostureError ||
        oldDelegate.isFrontCamera != isFrontCamera;
  }
}
