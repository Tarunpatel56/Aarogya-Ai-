import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MiniNavigationMapView extends StatefulWidget {
  final double height;
  final VoidCallback? onExpand;
  final String? vehicleNumber;
  final double speedKmh;
  final double? latitude;
  final double? longitude;

  const MiniNavigationMapView({
    super.key,
    this.height = 240,
    this.onExpand,
    this.vehicleNumber,
    this.speedKmh = 42.0,
    this.latitude,
    this.longitude,
  });

  @override
  State<MiniNavigationMapView> createState() => _MiniNavigationMapViewState();
}

class _MiniNavigationMapViewState extends State<MiniNavigationMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: SanctuaryColors.elevatedShadow,
      ),
      child: ClipRRect(
        borderRadius: SanctuaryRadius.rLg,
        child: Stack(
          children: [
            // Custom Painted Map with Bellandur Lake, roads and animated route
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(double.infinity, widget.height),
                  painter: _MapCanvasPainter(pulse: _pulseController.value),
                );
              },
            ),

            // Top Telemetry Header Bar
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  // Speed Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC090D16),
                      borderRadius: SanctuaryRadius.rBase,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, color: Color(0xFF6BD8CB), size: 14),
                        const SizedBox(width: 5),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${widget.speedKmh.toStringAsFixed(0)} ',
                                style: SanctuaryTypography.labelSm(color: Colors.white).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: 'km/h',
                                style: SanctuaryTypography.labelSm(color: Colors.white70).copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Green Corridor Active Badge
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xCC06251E),
                        borderRadius: SanctuaryRadius.rBase,
                        border: Border.all(color: const Color(0x4010B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.traffic, color: Color(0xFF34D399), size: 13),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Green Corridor Active',
                              overflow: TextOverflow.ellipsis,
                              style: SanctuaryTypography.labelSm(color: const Color(0xFF34D399)).copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Toggle/Center Button
                  InkWell(
                    onTap: widget.onExpand,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: SanctuaryColors.primaryTeal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SanctuaryColors.primaryTeal.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Patient Pickup Marker Pin
            Positioned(
              top: 55,
              right: 48,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xEB0A1120),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1),
                    ),
                    child: Text(
                      'PATIENT PICKUP',
                      style: SanctuaryTypography.labelSm(color: Colors.white).copyWith(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 22),
                ],
              ),
            ),

            // Ambulance Vehicle Marker
            Positioned(
              bottom: 48,
              left: 20,
              child: Row(
                children: [
                  // Pulsing Red Ambulance Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return Container(
                            width: 38 + (_pulseController.value * 14),
                            height: 38 + (_pulseController.value * 14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE11D48).withValues(alpha: (0.3 * (1 - _pulseController.value)).clamp(0.0, 1.0)),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.emergency, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xEB0A1120),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      widget.vehicleNumber ?? 'DL-01-AMB-108',
                      style: SanctuaryTypography.labelSm(color: Colors.white).copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Telemetry & Strobe Bar (Combined & Overflow Safe)
            Positioned(
              bottom: 8,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Live GPS Coordinates Pill
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xEB0A1120),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x5038BDF8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.satellite_alt_rounded, color: Color(0xFF38BDF8), size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'GPS: ${(widget.latitude ?? 28.5672).toStringAsFixed(4)}°, ${(widget.longitude ?? 77.2100).toStringAsFixed(4)}°',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Strobe Beacon Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xEB0A1120),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x4010B981)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Strobe Active',
                          style: SanctuaryTypography.labelSm(color: const Color(0xFF34D399)).copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final double pulse;

  _MapCanvasPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Map Water Body (Bellandur Lake)
    final lakePaint = Paint()
      ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final lakePath = Path();
    lakePath.moveTo(size.width * 0.35, size.height * 0.20);
    lakePath.quadraticBezierTo(size.width * 0.55, size.height * 0.15, size.width * 0.65, size.height * 0.35);
    lakePath.quadraticBezierTo(size.width * 0.70, size.height * 0.65, size.width * 0.50, size.height * 0.75);
    lakePath.quadraticBezierTo(size.width * 0.30, size.height * 0.70, size.width * 0.28, size.height * 0.45);
    lakePath.close();
    canvas.drawPath(lakePath, lakePaint);

    // Lake text label
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Bellandur Lake',
        style: TextStyle(color: Color(0x5594A3B8), fontSize: 9, fontStyle: FontStyle.italic),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width * 0.42, size.height * 0.44));

    // 2. Draw Secondary Road Grid
    final gridRoadPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    canvas.drawLine(Offset(0, size.height * 0.28), Offset(size.width, size.height * 0.31), gridRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.68), Offset(size.width, size.height * 0.65), gridRoadPaint);
    canvas.drawLine(Offset(0, size.height * 0.88), Offset(size.width, size.height * 0.85), gridRoadPaint);

    // Vertical roads
    canvas.drawLine(Offset(size.width * 0.22, 0), Offset(size.width * 0.25, size.height), gridRoadPaint);
    canvas.drawLine(Offset(size.width * 0.78, 0), Offset(size.width * 0.76, size.height), gridRoadPaint);

    // 3. Draw Active Emergency Route Polyline with Cyan Glow
    final routeGlowPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.35)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final routeMainPaint = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final routePath = Path();
    // Start at ambulance position
    routePath.moveTo(size.width * 0.16, size.height * 0.76);
    routePath.quadraticBezierTo(size.width * 0.32, size.height * 0.74, size.width * 0.48, size.height * 0.65);
    routePath.quadraticBezierTo(size.width * 0.66, size.height * 0.54, size.width * 0.63, size.height * 0.38);
    routePath.quadraticBezierTo(size.width * 0.62, size.height * 0.30, size.width * 0.78, size.height * 0.25);

    canvas.drawPath(routePath, routeGlowPaint);
    canvas.drawPath(routePath, routeMainPaint);
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}
