import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/telemetry.dart';

class HeartRateTrendChart extends StatefulWidget {
  final List<HeartRatePoint> points;
  final double tachycardiaLimit;
  final VoidCallback? onEcgTap;

  const HeartRateTrendChart({
    super.key,
    required this.points,
    this.tachycardiaLimit = 100.0,
    this.onEcgTap,
  });

  @override
  State<HeartRateTrendChart> createState() => _HeartRateTrendChartState();
}

class _HeartRateTrendChartState extends State<HeartRateTrendChart> {
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(
            painter: _HeartRateTrendPainter(
              points: widget.points,
              tachycardiaLimit: widget.tachycardiaLimit,
              hoveredIndex: hoveredIndex,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // X-Axis time indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('00:00\n(Midnight)', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            Text('06:00\n(Deep Sleep)', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            Text('12:00\n(Morning)', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            Text('18:00\n(Exertion)', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
            Text('22:30\n(124 BPM)', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: AppColors.criticalRed, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.stableGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Synchronized telemetry stream (Interval: 1x / 15m)',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onEcgTap != null)
              InkWell(
                onTap: widget.onEcgTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'View Full ECG Waveform',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.open_in_new,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeartRateTrendPainter extends CustomPainter {
  final List<HeartRatePoint> points;
  final double tachycardiaLimit;
  final int? hoveredIndex;

  _HeartRateTrendPainter({
    required this.points,
    required this.tachycardiaLimit,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double minBpm = 45.0;
    final double maxBpm = 135.0;

    double getY(double bpm) {
      final normalized = (bpm - minBpm) / (maxBpm - minBpm);
      return size.height - (normalized * size.height * 0.85) - 10;
    }

    double getX(int index) {
      if (points.length <= 1) return 0;
      return (index / (points.length - 1)) * size.width;
    }

    // Draw background subtle grid lines
    final gridPaint = Paint()
      ..color = AppColors.borderHairline.withAlpha(128)
      ..strokeWidth = 0.8;

    for (int bpm = 60; bpm <= 120; bpm += 20) {
      final y = getY(bpm.toDouble());
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw 100 BPM Tachycardia Limit line (dashed red)
    final limitY = getY(tachycardiaLimit);
    final limitPaint = Paint()
      ..color = AppColors.criticalRed.withAlpha(180)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, limitY),
        Offset(startX + dashWidth, limitY),
        limitPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Text label for Tachycardia Limit
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '100 BPM TACHYCARDIA LIMIT',
        style: TextStyle(
          color: AppColors.criticalRed,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 4, limitY - 14),
    );

    // Build smooth curve path
    final path = Path();
    final fillPath = Path();

    path.moveTo(getX(0), getY(points[0].bpm));
    fillPath.moveTo(getX(0), size.height);
    fillPath.lineTo(getX(0), getY(points[0].bpm));

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = Offset(getX(i), getY(points[i].bpm));
      final p1 = Offset(getX(i + 1), getY(points[i + 1].bpm));

      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill gradient under curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.mintAccent.withAlpha(64),
          AppColors.mintAccent.withAlpha(3),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = AppColors.mintAccent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Highlight critical and peak points
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = getX(i);
      final y = getY(p.bpm);

      if (p.isExertion || p.bpm >= 120) {
        // Red spike marker
        final dotPaint = Paint()..color = AppColors.criticalRed;
        canvas.drawCircle(Offset(x, y), 5.5, dotPaint);

        final whitePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(x, y), 2.5, whitePaint);

        // Callout text
        final callout = TextPainter(
          text: TextSpan(
            text: '${p.bpm.toInt()} BPM',
            style: const TextStyle(
              color: AppColors.criticalRed,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        callout.paint(canvas, Offset(x - callout.width / 2, y - 18));
      } else if (p.bpm <= 60 && i == 2) {
        // Minimum sleep point
        final dotPaint = Paint()..color = AppColors.primary;
        canvas.drawCircle(Offset(x, y), 4.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeartRateTrendPainter oldDelegate) => true;
}
