import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RapidBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showBadge;
  final String? subtitle;

  const RapidBrandLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.showBadge = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Glowing Emergency Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: SanctuaryColors.emergencyRed.withValues(alpha: 0.35),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [SanctuaryColors.emergencyRed, Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.airport_shuttle_rounded,
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Aarogya',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: ' Rapid EMS',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: SanctuaryColors.emergencyRed,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle ?? 'Emergency Dispatch & Rapid Response Fleet',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SanctuaryColors.textMuted,
              letterSpacing: 0.2,
            ),
          ),
        ],
        if (showBadge) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SanctuaryColors.emergencyRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SanctuaryColors.emergencyRed.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.emergency_rounded,
                  size: 13,
                  color: SanctuaryColors.emergencyRed,
                ),
                SizedBox(width: 5),
                Text(
                  '108 / Emergency Response Integrated',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: SanctuaryColors.emergencyRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
