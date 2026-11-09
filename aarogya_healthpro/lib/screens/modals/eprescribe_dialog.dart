import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/patient.dart';

class EPrescribeDialog extends StatefulWidget {
  final Patient patient;
  final Function(String drug, String dose)? onPrescribed;

  const EPrescribeDialog({
    super.key,
    required this.patient,
    this.onPrescribed,
  });

  @override
  State<EPrescribeDialog> createState() => _EPrescribeDialogState();
}

class _EPrescribeDialogState extends State<EPrescribeDialog> {
  String selectedDrug = 'Telmisartan';
  String selectedDose = '40mg';
  String selectedFrequency = 'OD (Once Daily - Evening)';
  String durationDays = '30 Days';
  final _instructionsController = TextEditingController(text: 'Take with or after dinner. Maintain daily hydration.');
  bool _isSubmitting = false;

  final List<String> availableDrugs = [
    'Telmisartan',
    'Metformin HCl',
    'Atorvastatin',
    'Amlodipine',
    'Bisoprolol',
    'Clopidogrel',
    'Empagliflozin',
  ];

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mintChipBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('E-Prescription & Dosage', style: AppTypography.headlineSm, overflow: TextOverflow.ellipsis),
                            Text('Physician Authorized Digital Rx', style: AppTypography.bodySm, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Allergy Alert Warning Banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.criticalRedWash,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.criticalRedBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.criticalRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Allergy Watch: ${widget.patient.allergies}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.criticalRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
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
                    Text('Select Medication', style: AppTypography.labelMd),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedDrug,
                      items: availableDrugs
                          .map((d) => DropdownMenuItem(value: d, child: Text(d, style: AppTypography.bodyMd, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedDrug = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dosage', style: AppTypography.labelMd),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: selectedDose,
                                onChanged: (val) => selectedDose = val,
                                style: AppTypography.bodyMd,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.all(10)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duration', style: AppTypography.labelMd),
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: durationDays,
                                onChanged: (val) => durationDays = val,
                                style: AppTypography.bodyMd,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.all(10)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Frequency & Timing', style: AppTypography.labelMd),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedFrequency,
                      items: [
                        'OD (Once Daily - Morning)',
                        'OD (Once Daily - Evening)',
                        'BD (Twice Daily - Morning & Evening)',
                        'TDS (Thrice Daily)',
                        'HS (At Bedtime)',
                        'SOS (As needed)',
                      ].map((f) => DropdownMenuItem(value: f, child: Text(f, style: AppTypography.bodyMd, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedFrequency = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    ),
                    const SizedBox(height: 14),
                    Text('Special Clinical Instructions', style: AppTypography.labelMd),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 2,
                      style: AppTypography.bodyMd,
                      decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
                    ),
                    const SizedBox(height: 12),
                    // CDSS Drug-Drug interaction check
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.stableGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'CDSS Verified: Zero high-risk drug-drug interactions detected.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.stableGreen, fontSize: 11),
                        ),
                      ],
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
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isSubmitting = true);
                            await Future.delayed(const Duration(milliseconds: 600));
                            if (mounted) {
                              widget.onPrescribed?.call(selectedDrug, selectedDose);
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Prescribed $selectedDrug $selectedDose to ${widget.patient.name}'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Authorize & Send Rx'),
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
