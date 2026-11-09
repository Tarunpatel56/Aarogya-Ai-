import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/clinical_sanctuary_theme.dart';

class SparklineChart extends StatelessWidget {
  final List<double> dataPoints;
  final double thresholdValue;
  final double minValue;
  final double maxValue;
  final double height;

  const SparklineChart({
    super.key,
    required this.dataPoints,
    this.thresholdValue = 100.0,
    this.minValue = 50.0,
    this.maxValue = 135.0,
    this.height = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(
              dataPoints: dataPoints,
              thresholdValue: thresholdValue,
              minValue: minValue,
              maxValue: maxValue,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _timeLabel('00:00', 'Midnight'),
            _timeLabel('06:00', 'Sleep Dip'),
            _timeLabel('12:00', 'Clinic'),
            _timeLabel('18:00', 'Peak Walk'),
            _timeLabel('23:59', 'Rest'),
          ],
        ),
      ],
    );
  }

  Widget _timeLabel(String time, String sub) {
    return Column(
      children: [
        Text(
          time,
          style: ClinicalTypography.labelSm(color: ClinicalColors.deepSlateNavy),
        ),
        Text(
          sub,
          style: ClinicalTypography.labelSm(color: ClinicalColors.textSubtle)
              .copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final double thresholdValue;
  final double minValue;
  final double maxValue;

  _SparklinePainter({
    required this.dataPoints,
    required this.thresholdValue,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final range = maxValue - minValue;
    final points = <Offset>[];
    final stepX = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final normalizedY = (dataPoints[i] - minValue) / range;
      final y = size.height - (normalizedY * size.height);
      points.add(Offset(i * stepX, y.clamp(8.0, size.height - 8.0)));
    }

    // 1. Draw threshold line (100 BPM)
    final thresholdNormalized = (thresholdValue - minValue) / range;
    final thresholdY = size.height - (thresholdNormalized * size.height);

    final dashPaint = Paint()
      ..color = ClinicalColors.crimsonRose.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    double curX = 0;
    const dashW = 5.0;
    const spaceW = 4.0;
    while (curX < size.width) {
      canvas.drawLine(
        Offset(curX, thresholdY),
        Offset(curX + dashW, thresholdY),
        dashPaint,
      );
      curX += dashW + spaceW;
    }

    // Threshold text badge
    final textPainter = TextPainter(
      text: TextSpan(
        text: '100 BPM TACHYCARDIA LIMIT',
        style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
            .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 4, thresholdY - 14),
    );

    // 2. Build smooth Bezier path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;
      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // 3. Fill gradient under the path
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [
          ClinicalColors.primaryTeal.withOpacity(0.28),
          ClinicalColors.primaryTeal.withOpacity(0.02),
        ],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw continuous line
    final linePaint = Paint()
      ..color = ClinicalColors.primaryTeal
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 5. Highlight Peak Point (>100 BPM peak)
    int peakIndex = 0;
    double maxVal = dataPoints[0];
    for (int i = 1; i < dataPoints.length; i++) {
      if (dataPoints[i] > maxVal) {
        maxVal = dataPoints[i];
        peakIndex = i;
      }
    }

    final peakPoint = points[peakIndex];
    // Outer glow ring
    final glowPaint = Paint()
      ..color = ClinicalColors.crimsonRose.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(peakPoint, 9, glowPaint);

    // Inner point
    final peakPaint = Paint()
      ..color = ClinicalColors.crimsonRose
      ..style = PaintingStyle.fill;
    canvas.drawCircle(peakPoint, 4.5, peakPaint);

    final whiteCenterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(peakPoint, 2, whiteCenterPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.thresholdValue != thresholdValue;
  }
}
