import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Clean status pill / badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final Color? iconColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: iconColor ?? textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini ECG Sparkline for Heart Rate Card
class EcgSparklinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  EcgSparklinePainter({
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h * 0.55;

    // Heartbeat ECG pulse wave pattern
    path.moveTo(0, mid);
    path.lineTo(w * 0.25, mid);
    path.lineTo(w * 0.32, mid - 2);
    path.lineTo(w * 0.38, mid + 3);
    path.lineTo(w * 0.44, mid - 14); // R peak
    path.lineTo(w * 0.52, mid + 8);  // S dip
    path.lineTo(w * 0.58, mid - 4);  // T wave
    path.lineTo(w * 0.65, mid);
    path.lineTo(w * 0.75, mid);
    path.lineTo(w * 0.82, mid - 1);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// SpO2 Flat gentle wave
class Spo2WavePainter extends CustomPainter {
  final Color color;

  Spo2WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height * 0.6;

    path.moveTo(0, h);
    path.quadraticBezierTo(w * 0.3, h - 2, w * 0.6, h + 1);
    path.quadraticBezierTo(w * 0.85, h - 1, w, h);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Continuous Telemetry High-Res Chart with Area Gradient & Peak Tooltip
class ContinuousTelemetryChart extends StatelessWidget {
  final double height;

  const ContinuousTelemetryChart({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _TelemetryChartPainter(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('00:00', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('06:00', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('12:00', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('18:00', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('Now', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class _TelemetryChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Wave points matching screenshot 2:
    // Starts low around 0.7h, gentle rise, small dip, sharp peak at midday walk,
    // valley at 18:00, then high sinus wave towards 'Now'.
    final path = Path();
    path.moveTo(0, h * 0.68);
    path.cubicTo(w * 0.15, h * 0.68, w * 0.25, h * 0.70, w * 0.35, h * 0.65);
    // Peak at ~ 0.48w (Walk peak 108 BPM)
    final peakX = w * 0.48;
    final peakY = h * 0.38;
    path.cubicTo(w * 0.40, h * 0.60, w * 0.44, peakY, peakX, peakY);
    // Downwards after walk
    path.cubicTo(w * 0.52, peakY, w * 0.58, h * 0.85, w * 0.65, h * 0.82);
    // Upwards to high wave at evening
    path.cubicTo(w * 0.72, h * 0.80, w * 0.76, h * 0.22, w * 0.82, h * 0.24);
    path.cubicTo(w * 0.88, h * 0.26, w * 0.94, h * 0.58, w, h * 0.65);

    // Gradient area fill
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryLight.withValues(alpha: 0.35),
          AppColors.primaryLight.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Peak dot at peakX, peakY
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(peakX, peakY), 4.5, dotPaint);
    canvas.drawCircle(Offset(peakX, peakY), 4.5, dotBorderPaint);

    // Tooltip pill "108 BPM (Walk)"
    final tooltipText = '108 BPM (Walk)';
    final textSpan = TextSpan(
      text: tooltipText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillW = textPainter.width + 12;
    final pillH = textPainter.height + 6;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(peakX - 10, peakY - 18),
        width: pillW,
        height: pillH,
      ),
      const Radius.circular(10),
    );

    final pillBgPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(pillRect, pillBgPaint);
    textPainter.paint(
      canvas,
      Offset(pillRect.left + 6, pillRect.top + 3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Steps Circular Progress Ring
class StepsProgressRing extends StatelessWidget {
  final double percentage; // 0.0 to 1.0

  const StepsProgressRing({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(48, 48),
            painter: _StepsRingPainter(percentage: percentage),
          ),
          const Icon(
            Icons.bolt_rounded,
            size: 20,
            color: AppColors.primaryTeal,
          ),
        ],
      ),
    );
  }
}

class _StepsRingPainter extends CustomPainter {
  final double percentage;

  _StepsRingPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track circle
    final trackPaint = Paint()
      ..color = const Color(0xFFE0F2EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    final progressPaint = Paint()
      ..color = AppColors.primaryTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Sleep Architecture Segmented Bar
class SleepArchitectureBar extends StatelessWidget {
  final double deepRatio;
  final double remRatio;
  final double lightRatio;

  const SleepArchitectureBar({
    super.key,
    this.deepRatio = 0.28,
    this.remRatio = 0.23,
    this.lightRatio = 0.49,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
              flex: (deepRatio * 100).toInt(),
              child: Container(color: AppColors.sleepDeep),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: (remRatio * 100).toInt(),
              child: Container(color: AppColors.sleepRem),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: (lightRatio * 100).toInt(),
              child: Container(color: AppColors.sleepLight),
            ),
          ],
        ),
      ),
    );
  }
}
