import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/patient.dart';

class SoapNoteDialog extends StatefulWidget {
  final Patient patient;
  final Function(String summary)? onSaved;

  const SoapNoteDialog({
    super.key,
    required this.patient,
    this.onSaved,
  });

  @override
  State<SoapNoteDialog> createState() => _SoapNoteDialogState();
}

class _SoapNoteDialogState extends State<SoapNoteDialog> {
  final _subjectiveController = TextEditingController(
    text: 'Patient reports mild evening dizziness during exertion. Denies chest pain, orthopnea, or syncope.',
  );
  final _objectiveController = TextEditingController(
    text: 'BP: 120/80 mmHg. SpO2: 98% (Optimal). HR: 72 BPM (Resting Sinus). Ambulatory telemetry verified.',
  );
  final _assessmentController = TextEditingController(
    text: 'Post-MI status post-PCI (LAD stent) convalescence. Well compensated. Orthostatic component addressed.',
  );
  final _planController = TextEditingController(
    text: 'Maintain Telmisartan 40mg OD, Metformin 500mg BD. Hydration counselling provided. Continue continuous telemetry watch.',
  );

  bool _isSyncing = false;

  @override
  void dispose() {
    _subjectiveController.dispose();
    _objectiveController.dispose();
    _assessmentController.dispose();
    _planController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mintChipBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Clinical Progress Note', style: AppTypography.headlineSm, overflow: TextOverflow.ellipsis),
                            Text('SOAP Format • FHIR R4 Compliant', style: AppTypography.bodySm, overflow: TextOverflow.ellipsis),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('Patient: ', style: AppTypography.labelMd),
                  Expanded(
                    child: Text(
                      '${widget.patient.name} (${widget.patient.gender}, ${widget.patient.age})',
                      style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('ABHA: ${widget.patient.abhaId}', style: AppTypography.clinicalCode),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('S • Subjective (Symptoms & History)', _subjectiveController, 3),
                    const SizedBox(height: 12),
                    _buildSection('O • Objective (Vitals & Clinical Data)', _objectiveController, 3),
                    const SizedBox(height: 12),
                    _buildSection('A • Assessment (Diagnosis & Evaluation)', _assessmentController, 2),
                    const SizedBox(height: 12),
                    _buildSection('P • Plan (Prescription & Next Steps)', _planController, 3),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.mintAccent),
                    onPressed: _isSyncing
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isSyncing = true);
                            await Future.delayed(const Duration(milliseconds: 600));
                            if (mounted) {
                              widget.onSaved?.call(_assessmentController.text);
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('SOAP Progress Note saved and synchronized to Apollo EMR'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                      child: _isSyncing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save & Sign to EMR'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, TextEditingController controller, int lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: lines,
          style: AppTypography.bodyMd,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
      ],
    );
  }
}
