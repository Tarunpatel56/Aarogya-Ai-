import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/alert.dart';

class RapidDispatchDialog extends StatefulWidget {
  final TriageAlert alert;
  final VoidCallback? onDispatched;

  const RapidDispatchDialog({
    super.key,
    required this.alert,
    this.onDispatched,
  });

  @override
  State<RapidDispatchDialog> createState() => _RapidDispatchDialogState();
}

class _RapidDispatchDialogState extends State<RapidDispatchDialog> {
  bool _isDispatching = false;
  String selectedAmbulance = 'Aarogya Rapid Ambulance #KA-02-HA-1102 (ICU Setup)';
  String primaryCardiologist = 'Dr. Aarav Mehta (Attending On-Call)';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 580),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.criticalRedWash,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emergency, color: AppColors.criticalRed, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Rapid Response', style: AppTypography.headlineSm.copyWith(color: AppColors.criticalRed)),
                      Text('Tier 1 Hospital Escalation & Dispatch Protocol', style: AppTypography.bodySm),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Patient details card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.alert.patientName} (${widget.alert.patientGender}, ${widget.alert.patientAge})',
                        style: AppTypography.headlineSm.copyWith(fontSize: 15),
                      ),
                      Text(widget.alert.roomOrLocation, style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Primary Dx: ${widget.alert.primaryDiagnosis}', style: AppTypography.bodySm),
                  const SizedBox(height: 4),
                  Text(
                    'Trigger: ${widget.alert.headline}',
                    style: AppTypography.bodySm.copyWith(color: AppColors.criticalRed, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Emergency Mobile Unit', style: AppTypography.labelMd),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedAmbulance,
                      items: [
                        'Aarogya Rapid Ambulance #KA-02-HA-1102 (ICU Setup)',
                        'Apollo City Critical Transport #KA-01-CR-9041',
                        'Rapid Response Paramedic Bike #KA-02-PB-03',
                      ].map((u) => DropdownMenuItem(value: u, child: Text(u, style: AppTypography.bodySm, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedAmbulance = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.all(10)),
                    ),
                    const SizedBox(height: 14),
                    Text('Senior Clinician On Duty', style: AppTypography.labelMd),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: primaryCardiologist,
                      items: [
                        'Dr. Aarav Mehta (Attending On-Call)',
                        'Dr. Priya Nambiar (Senior Interventional Cardiologist)',
                        'Dr. Sameer Khan (ICU Rapid Triage Head)',
                      ].map((d) => DropdownMenuItem(value: d, child: Text(d, style: AppTypography.bodySm, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => primaryCardiologist = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.all(10)),
                    ),
                    const SizedBox(height: 16),
                    // Live Telemetry Lock Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCEEAE2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Live GPS & Telemetry Bridge will be activated immediately to the paramedic tablet and hospital central control room.',
                              style: AppTypography.bodySm.copyWith(color: AppColors.primary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed),
                    onPressed: _isDispatching
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isDispatching = true);
                            await Future.delayed(const Duration(milliseconds: 700));
                            if (mounted) {
                              widget.onDispatched?.call();
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Rapid Response Team dispatched! ETA: 6 mins. Real-time GPS stream connected.'),
                                  backgroundColor: AppColors.criticalRed,
                                ),
                              );
                            }
                          },
                    child: _isDispatching
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm & Dispatch Unit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
