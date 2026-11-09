import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EcgSparklineWidget extends StatefulWidget {
  final Color lineColor;
  final double height;
  final bool animate;
  final bool isTachycardia;

  const EcgSparklineWidget({
    super.key,
    this.lineColor = SanctuaryColors.primaryTeal,
    this.height = 42,
    this.animate = true,
    this.isTachycardia = true,
  });

  @override
  State<EcgSparklineWidget> createState() => _EcgSparklineWidgetState();
}

class _EcgSparklineWidgetState extends State<EcgSparklineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isTachycardia ? 1100 : 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _EcgPainter(
            lineColor: widget.lineColor,
            phase: widget.animate ? _controller.value : 0.0,
          ),
        );
      },
    );
  }
}

class _EcgPainter extends CustomPainter {
  final Color lineColor;
  final double phase;

  _EcgPainter({required this.lineColor, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.2)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final midY = size.height * 0.55;
    final amp = size.height * 0.42;

    const cycleWidth = 80.0;
    final totalCycles = (width / cycleWidth).ceil() + 2;
    final offsetX = -phase * cycleWidth;

    bool isFirst = true;

    for (int c = 0; c < totalCycles; c++) {
      final startX = c * cycleWidth + offsetX;

      final points = [
        Offset(startX + 0, midY),
        Offset(startX + 14, midY),
        // P-wave
        Offset(startX + 20, midY - amp * 0.22),
        Offset(startX + 26, midY),
        Offset(startX + 30, midY),
        // Q-drop
        Offset(startX + 33, midY + amp * 0.15),
        // R-peak
        Offset(startX + 38, midY - amp * 0.95),
        // S-drop
        Offset(startX + 43, midY + amp * 0.4),
        Offset(startX + 46, midY),
        // ST segment
        Offset(startX + 52, midY),
        // T-wave
        Offset(startX + 60, midY - amp * 0.35),
        Offset(startX + 68, midY),
        Offset(startX + cycleWidth, midY),
      ];

      for (var pt in points) {
        if (pt.dx < -10 || pt.dx > width + 10) continue;
        if (isFirst) {
          path.moveTo(pt.dx.clamp(0.0, width), pt.dy);
          isFirst = false;
        } else {
          path.lineTo(pt.dx.clamp(0.0, width), pt.dy);
        }
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw scanning live pulse head
    final headX = ((phase * width * 1.5) % width);
    final pulsePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(headX, midY), 3.0, pulsePaint);

    final pulseRing = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(headX, midY), 6.5, pulseRing);
  }

  @override
  bool shouldRepaint(covariant _EcgPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.lineColor != lineColor;
  }
}
