import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class EcgWaveformView extends StatefulWidget {
  final double bpm;
  final bool isAnimated;
  final String leadName;
  final double height;

  const EcgWaveformView({
    super.key,
    this.bpm = 72,
    this.isAnimated = true,
    this.leadName = 'LEAD II (Standard Calibration: 25mm/s • 10mm/mV)',
    this.height = 160,
  });

  @override
  State<EcgWaveformView> createState() => _EcgWaveformViewState();
}

class _EcgWaveformViewState extends State<EcgWaveformView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E1B), // Clinical dark monitor green/slate
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFF1E3832), width: 1.5),
        boxShadow: AppColors.floatingElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ECG Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: _EcgGridPainter(),
            ),
          ),
          // Waveform
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _EcgTracePainter(
                    progress: _controller.value,
                    bpm: widget.bpm,
                  ),
                );
              },
            ),
          ),
          // Lead Label & Telemetry Header
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.mintAccent.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.mintAccent, width: 1),
                      ),
                      child: Text(
                        'LEAD II',
                        style: AppTypography.clinicalCode.copyWith(
                          color: const Color(0xFF6BD8CB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '25 mm/s • 10 mm/mV',
                      style: AppTypography.clinicalCode.copyWith(
                        color: Colors.white60,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6BD8CB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.bpm.toInt()} BPM (Normal Sinus)',
                      style: AppTypography.clinicalCode.copyWith(
                        color: const Color(0xFF6BD8CB),
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final smallGridPaint = Paint()
      ..color = const Color(0x1A0D9488)
      ..strokeWidth = 0.5;

    final largeGridPaint = Paint()
      ..color = const Color(0x330D9488)
      ..strokeWidth = 1.0;

    const double smallStep = 8.0;
    const double largeStep = 40.0;

    for (double x = 0; x <= size.width; x += smallStep) {
      final isLarge = (x % largeStep) < 1.0;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isLarge ? largeGridPaint : smallGridPaint);
    }

    for (double y = 0; y <= size.height; y += smallStep) {
      final isLarge = (y % largeStep) < 1.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isLarge ? largeGridPaint : smallGridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EcgTracePainter extends CustomPainter {
  final double progress;
  final double bpm;

  _EcgTracePainter({required this.progress, required this.bpm});

  @override
  void paint(Canvas canvas, Size size) {
    final tracePaint = Paint()
      ..color = const Color(0xFF6BD8CB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF008378).withAlpha(128)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final baselineY = size.height * 0.58;
    final path = Path();

    const double period = 140.0; // Cycle length in pixels
    final double offset = progress * period;

    bool isFirst = true;

    for (double x = 0; x <= size.width + 20; x += 2.0) {
      final cyclePos = (x + offset) % period;

      double y = baselineY;

      // P wave
      if (cyclePos >= 15 && cyclePos < 35) {
        final p = (cyclePos - 15) / 20;
        y -= sin(p * pi) * 8.0;
      }
      // PR segment is flat
      // Q wave
      else if (cyclePos >= 45 && cyclePos < 50) {
        y += 4.0;
      }
      // R wave spike
      else if (cyclePos >= 50 && cyclePos < 57) {
        final r = (cyclePos - 50) / 7;
        y -= sin(r * pi) * 58.0;
      }
      // S wave dip
      else if (cyclePos >= 57 && cyclePos < 65) {
        final s = (cyclePos - 57) / 8;
        y += sin(s * pi) * 14.0;
      }
      // ST segment flat
      // T wave
      else if (cyclePos >= 80 && cyclePos < 110) {
        final t = (cyclePos - 80) / 30;
        y -= sin(t * pi) * 14.0;
      }

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, tracePaint);
  }

  @override
  bool shouldRepaint(covariant _EcgTracePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
