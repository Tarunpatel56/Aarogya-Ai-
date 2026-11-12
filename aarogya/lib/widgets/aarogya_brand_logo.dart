import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AarogyaBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showBadge;
  final String? subtitle;

  const AarogyaBrandLogo({
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
        // Glowing Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.30),
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
                    colors: [AppColors.primaryTeal, Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
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
                  text: ' AI',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryTeal,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle ?? 'Smart Personal Healthcare Ecosystem',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
        if (showBadge) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.verified_user_rounded,
                  size: 13,
                  color: AppColors.primaryTeal,
                ),
                SizedBox(width: 5),
                Text(
                  'ABDM Aligned - Ayushman Bharat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
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
