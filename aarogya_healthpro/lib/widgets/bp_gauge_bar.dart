import 'package:flutter/material.dart';
import '../theme/clinical_sanctuary_theme.dart';

class BpGaugeBar extends StatelessWidget {
  final int systolic;
  final int diastolic;

  const BpGaugeBar({
    super.key,
    required this.systolic,
    required this.diastolic,
  });

  @override
  Widget build(BuildContext context) {
    // 5 zones: Optimal (<120), Normal (120-129), Elevated (130-139), Stage 1 (140-159), Stage 2 (>=160)
    // Indicator position between 0.0 and 1.0 based on systolic 90..180
    final normalized = ((systolic - 90) / 90).clamp(0.05, 0.95);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Protocol strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ClinicalColors.surfaceInset,
            borderRadius: ClinicalRadii.roundedSm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TARGET PROTOCOL',
                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted),
              ),
              Text(
                '< 130/80 mmHg',
                style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Multi-segment color gauge bar
        SizedBox(
          height: 14,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: const [
                        Expanded(
                          flex: 2,
                          child: ColoredBox(color: ClinicalColors.optimalEmerald),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 2,
                          child: ColoredBox(color: ClinicalColors.primaryTeal),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 2,
                          child: ColoredBox(color: ClinicalColors.warningAmber),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 2,
                          child: ColoredBox(color: Color(0xFFEA580C)),
                        ),
                        SizedBox(width: 2),
                        Expanded(
                          flex: 2,
                          child: ColoredBox(color: ClinicalColors.crimsonRose),
                        ),
                      ],
                    ),
                  ),

                  // Indicator needle
                  Positioned(
                    left: (width * normalized) - 5,
                    top: -4,
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 22,
                          decoration: BoxDecoration(
                            color: ClinicalColors.deepSlateNavy,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Footnote
        Text(
          'Clinical Target Window: Optimal Controlled Range',
          style: ClinicalTypography.bodySm(color: ClinicalColors.optimalEmerald)
              .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
