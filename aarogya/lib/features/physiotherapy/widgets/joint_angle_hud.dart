import 'package:flutter/material.dart';

class JointAngleHud extends StatelessWidget {
  final String primaryJointName;
  final double currentAngle;
  final double formAccuracy;
  final int latencyMs;
  final int fps;
  final String delegate;

  const JointAngleHud({
    super.key,
    required this.primaryJointName,
    required this.currentAngle,
    required this.formAccuracy,
    required this.latencyMs,
    required this.fps,
    required this.delegate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.straighten_rounded, color: Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 6),
              Text(
                '$primaryJointName: ${currentAngle > 0 ? "${currentAngle.round()}°" : "--"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Form: ${formAccuracy.round()}%',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '${latencyMs}ms • $fps FPS ($delegate)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

