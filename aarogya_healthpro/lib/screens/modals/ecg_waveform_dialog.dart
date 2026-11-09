import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/ecg_waveform_painter.dart';

class EcgWaveformDialog extends StatelessWidget {
  final String patientName;
  final double bpm;

  const EcgWaveformDialog({
    super.key,
    required this.patientName,
    this.bpm = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E1B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.show_chart, color: Color(0xFF6BD8CB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('12-Lead Continuous ECG Telemetry', style: AppTypography.headlineSm),
                        Text('$patientName • Live Ambulatory Channel', style: AppTypography.bodySm),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Waveform Monitor Box
            EcgWaveformView(bpm: bpm, height: 180),
            const SizedBox(height: 14),
            // Telemetry Metric Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('HEART RATE', '${bpm.toInt()} BPM', 'Normal Sinus', AppColors.stableGreen),
                      _buildMetric('PR INTERVAL', '162 ms', 'Normal (120-200)', AppColors.primary),
                      _buildMetric('QRS DURATION', '88 ms', 'Normal (<120)', AppColors.primary),
                      _buildMetric('QT / QTc', '398 / 418 ms', 'Normal Bazett', AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 16, color: AppColors.stableGreen),
                      const SizedBox(width: 6),
                      Text(
                        'ST Segment: Isoelectric. No acute ischemia or pathological Q-waves observed.',
                        style: AppTypography.bodySm.copyWith(color: AppColors.onSurface, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ECG Strip PDF generated and exported to downloads.')),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export ECG Strip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Close Monitor'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, String sub, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 1),
        Text(sub, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}
