import 'package:flutter/material.dart';
import '../../theme/clinical_sanctuary_theme.dart';

class PhysioPrescribeDialog extends StatefulWidget {
  final String patientName;
  final Function(String planTitle, String details)? onPrescribed;

  const PhysioPrescribeDialog({
    super.key,
    required this.patientName,
    this.onPrescribed,
  });

  @override
  State<PhysioPrescribeDialog> createState() => _PhysioPrescribeDialogState();
}

class _PhysioPrescribeDialogState extends State<PhysioPrescribeDialog> {
  String _selectedPlan = 'Desk Worker Cervical Relief Routine';
  String _selectedFrequency = 'Once Daily (15 mins)';
  String _selectedDuration = '2 Weeks';
  final TextEditingController _notesController = TextEditingController(
    text: 'Maintain neutral spine. Perform reps gently; stop if sharp pain exceeds VAS 4.',
  );
  bool _isSaving = false;

  final List<Map<String, String>> _curatedProtocols = [
    {
      'title': 'Desk Worker Cervical Relief Routine',
      'target': 'Neck & Cervical Spine (C4-C7)',
      'exercises': 'Chin Tucks, Upper Trapezius Stretch, Levator Scapulae Relief',
    },
    {
      'title': 'Lumbar Spine Core & Mobility Protocol',
      'target': 'Lower Back & Core Stabilizers',
      'exercises': 'Cat-Cow Decompression, Bird-Dog Stabilizers, Glute Bridges',
    },
    {
      'title': 'Knee Joint Strength & OA Relief',
      'target': 'Patellofemoral & Quadriceps',
      'exercises': 'Isometric Quad Sets, Straight Leg Raises, Seated Hamstring Stretch',
    },
    {
      'title': 'Thoracic Extension & Posture Alignment',
      'target': 'Mid-Back & Scapular Retractors',
      'exercises': 'Scapular Wall Slides, Doorway Pectoral Stretch, Prone Cobras',
    },
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _isSaving = true);
    final summary = '$_selectedPlan ($_selectedFrequency, $_selectedDuration)';
    final notes = _notesController.text.trim();

    if (widget.onPrescribed != null) {
      widget.onPrescribed!(_selectedPlan, '$summary. Notes: $notes');
    }

    Navigator.of(context).pop({
      'plan': _selectedPlan,
      'frequency': _selectedFrequency,
      'duration': _selectedDuration,
      'notes': notes,
      'summary': summary,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: ClinicalRadii.roundedLg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
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
                    color: ClinicalColors.optimalWash,
                    borderRadius: ClinicalRadii.roundedSm,
                  ),
                  child: const Icon(Icons.fitness_center_rounded, color: ClinicalColors.primaryTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prescribe Physiotherapy Plan',
                        style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                            .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Patient: ${widget.patientName}',
                        style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: ClinicalColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: ClinicalColors.hairlineBorder, height: 24),

            // Protocols List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT EVIDENCE-BASED PROTOCOL',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 11, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    ..._curatedProtocols.map((protocol) {
                      final isSelected = _selectedPlan == protocol['title'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isSelected ? ClinicalColors.optimalWash.withOpacity(0.5) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: ClinicalRadii.roundedMd,
                            side: BorderSide(
                              color: isSelected ? ClinicalColors.primaryTeal : ClinicalColors.hairlineBorder,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: RadioListTile<String>(
                            value: protocol['title']!,
                            groupValue: _selectedPlan,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPlan = val);
                            },
                            activeColor: ClinicalColors.primaryTeal,
                            title: Text(
                              protocol['title']!,
                              style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                                  .copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${protocol['target']}',
                                  style: ClinicalTypography.bodySm(color: ClinicalColors.primaryTeal)
                                      .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  protocol['exercises']!,
                                  style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted).copyWith(fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),

                    // Frequency & Duration
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FREQUENCY', style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted).copyWith(fontSize: 11)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedFrequency,
                                isDense: true,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: ClinicalRadii.roundedSm),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Once Daily (15 mins)', child: Text('Once Daily (15 mins)', style: TextStyle(fontSize: 11.5))),
                                  DropdownMenuItem(value: 'Twice Daily (10 mins)', child: Text('Twice Daily (10 mins)', style: TextStyle(fontSize: 11.5))),
                                  DropdownMenuItem(value: '3x Weekly (25 mins)', child: Text('3x Weekly (25 mins)', style: TextStyle(fontSize: 11.5))),
                                ],
                                onChanged: (val) => setState(() => _selectedFrequency = val ?? _selectedFrequency),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DURATION', style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted).copyWith(fontSize: 11)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedDuration,
                                isDense: true,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: ClinicalRadii.roundedSm),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '1 Week', child: Text('1 Week', style: TextStyle(fontSize: 11.5))),
                                  DropdownMenuItem(value: '2 Weeks', child: Text('2 Weeks', style: TextStyle(fontSize: 11.5))),
                                  DropdownMenuItem(value: '4 Weeks', child: Text('4 Weeks', style: TextStyle(fontSize: 11.5))),
                                  DropdownMenuItem(value: 'Ongoing Rehabilitation', child: Text('Ongoing Rehabilitation', style: TextStyle(fontSize: 11.5))),
                                ],
                                onChanged: (val) => setState(() => _selectedDuration = val ?? _selectedDuration),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Instructions
                    Text(
                      'CLINICAL PRECAUTIONS & NOTES FOR PATIENT',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted).copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'e.g. Stop if pain increases beyond VAS 4. Ice application 10m after...',
                        border: OutlineInputBorder(borderRadius: ClinicalRadii.roundedSm),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(color: ClinicalColors.hairlineBorder, height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClinicalColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: ClinicalRadii.roundedMd),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  _isSaving ? 'Prescribing Protocol...' : 'Prescribe Protocol to Patient',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
