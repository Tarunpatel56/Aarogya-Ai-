import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';
import '../../theme/app_colors.dart';

class PrescriptionAuthoringScreen extends StatefulWidget {
  final String patientProfileId;
  final String patientName;
  final String? appointmentId;
  final String? existingAllergies;

  const PrescriptionAuthoringScreen({
    super.key,
    required this.patientProfileId,
    required this.patientName,
    this.appointmentId,
    this.existingAllergies,
  });

  @override
  State<PrescriptionAuthoringScreen> createState() => _PrescriptionAuthoringScreenState();
}

class _PrescriptionAuthoringScreenState extends State<PrescriptionAuthoringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  final _adviceController = TextEditingController();
  final _prescriptionService = PrescriptionService();

  final List<Map<String, dynamic>> _medicineItems = [
    {
      'nameController': TextEditingController(text: 'Paracetamol 650mg'),
      'dosageController': TextEditingController(text: '1 tab'),
      'frequencyController': TextEditingController(text: '1-0-1 (Twice daily)'),
      'durationController': TextEditingController(text: '3'),
      'timingController': TextEditingController(text: 'After food'),
      'instructionsController': TextEditingController(text: 'Take with warm water'),
    },
  ];

  bool _isSaving = false;

  void _addMedicineRow() {
    setState(() {
      _medicineItems.add({
        'nameController': TextEditingController(),
        'dosageController': TextEditingController(text: '1 tab'),
        'frequencyController': TextEditingController(text: '1-0-1'),
        'durationController': TextEditingController(text: '5'),
        'timingController': TextEditingController(text: 'After food'),
        'instructionsController': TextEditingController(),
      });
    });
  }

  void _removeMedicineRow(int index) {
    if (_medicineItems.length > 1) {
      setState(() {
        final removed = _medicineItems.removeAt(index);
        removed['nameController']?.dispose();
        removed['dosageController']?.dispose();
        removed['frequencyController']?.dispose();
        removed['durationController']?.dispose();
        removed['timingController']?.dispose();
        removed['instructionsController']?.dispose();
      });
    }
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;

    final diagnosis = _diagnosisController.text.trim();
    if (diagnosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify a clinical diagnosis')),
      );
      return;
    }

    final items = <PrescriptionItemModel>[];
    for (int i = 0; i < _medicineItems.length; i++) {
      final name = _medicineItems[i]['nameController']!.text.trim();
      if (name.isNotEmpty) {
        items.add(
          PrescriptionItemModel(
            id: 'item-$i',
            medicineName: name,
            dosage: _medicineItems[i]['dosageController']!.text.trim(),
            frequency: _medicineItems[i]['frequencyController']!.text.trim(),
            durationDays: int.tryParse(_medicineItems[i]['durationController']!.text.trim()) ?? 5,
            timing: _medicineItems[i]['timingController']!.text.trim(),
            instructions: _medicineItems[i]['instructionsController']!.text.trim(),
          ),
        );
      }
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medication')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final rx = await _prescriptionService.createPrescription(
        patientProfileId: widget.patientProfileId,
        appointmentId: widget.appointmentId,
        diagnosis: diagnosis,
        doctorNotes: _notesController.text.trim(),
        generalAdvice: _adviceController.text.trim(),
        items: items,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primaryTeal,
            content: Text('Digital Prescription #${rx.id.substring(0, 8)} signed & sent to patient!'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _adviceController.dispose();
    for (final item in _medicineItems) {
      item['nameController']?.dispose();
      item['dosageController']?.dispose();
      item['frequencyController']?.dispose();
      item['durationController']?.dispose();
      item['timingController']?.dispose();
      item['instructionsController']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Author Digital Prescription'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryDark,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, color: AppColors.primaryTeal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Known Allergies: ${widget.existingAllergies ?? 'None Reported'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.existingAllergies != null ? Colors.red.shade700 : AppColors.textSecondary,
                            fontWeight: widget.existingAllergies != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Clinical Diagnosis
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Diagnosis *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Acute Upper Respiratory Tract Infection',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Diagnosis is required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medication Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Medication Regimen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _addMedicineRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Medicine'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ...List.generate(_medicineItems.length, (index) {
              final row = _medicineItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: row['nameController'],
                            decoration: const InputDecoration(
                              hintText: 'Medicine Brand / Generic Name',
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_medicineItems.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeMedicineRow(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: row['dosageController'],
                            decoration: const InputDecoration(labelText: 'Dosage', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: row['frequencyController'],
                            decoration: const InputDecoration(labelText: 'Frequency', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: row['durationController'],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Days', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: row['timingController'],
                            decoration: const InputDecoration(labelText: 'Timing', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: row['instructionsController'],
                            decoration: const InputDecoration(labelText: 'Instructions', isDense: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            // Clinical Notes & Advice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clinical Notes & Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Doctor private observations or specific advice',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Diet & Lifestyle Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _adviceController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Dietary guidance, fluid intake, physical rest',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _submitPrescription,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.draw_rounded),
                label: const Text(
                  'Sign & Issue Digital Prescription',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

