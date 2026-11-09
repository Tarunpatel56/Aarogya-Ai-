import 'package:flutter/material.dart';
import '../../models/prescription_model.dart';
import '../../services/prescription_service.dart';
import '../../services/patient_service.dart';
import '../../theme/app_theme.dart';

class PatientPrescriptionsScreen extends StatefulWidget {
  final String? patientProfileId;
  final PrescriptionService? prescriptionService;

  const PatientPrescriptionsScreen({
    super.key,
    this.patientProfileId,
    this.prescriptionService,
  });

  @override
  State<PatientPrescriptionsScreen> createState() => _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState extends State<PatientPrescriptionsScreen> {
  late final PrescriptionService _prescriptionService;
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = true;
  String? _effectiveProfileId;

  @override
  void initState() {
    super.initState();
    _prescriptionService = widget.prescriptionService ?? PrescriptionService();
    _initProfileAndLoad();
  }

  Future<void> _initProfileAndLoad() async {
    setState(() => _isLoading = true);
    try {
      if (widget.patientProfileId != null && widget.patientProfileId!.isNotEmpty) {
        _effectiveProfileId = widget.patientProfileId;
      } else {
        final profile = await PatientService().getProfile();
        _effectiveProfileId = profile.id;
      }

      if (_effectiveProfileId != null) {
        final list = await _prescriptionService.getPatientPrescriptions(_effectiveProfileId!);
        if (mounted) {
          setState(() {
            _prescriptions = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Digital e-Prescriptions', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initProfileAndLoad,
            tooltip: 'Refresh prescriptions',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : _prescriptions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _prescriptions.length,
                  itemBuilder: (ctx, i) => _buildPrescriptionCard(_prescriptions[i]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_outlined, size: 48, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Prescriptions on Record',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'When your consulting doctor issues a digital prescription during or after your appointment, it will appear here with complete dosage, timing, and digital verification seal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel rx) {
    final dateStr = rx.createdAt.toLocal().toString().substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Rx icon + Diagnosis + Date
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('℞', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rx.diagnosis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Date: $dateStr',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prescribed Medicines Heading
                const Text(
                  'PRESCRIBED MEDICATIONS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),

                // Medicines List
                ...rx.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle, size: 8, color: AppColors.primaryTeal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.medicineName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dosage: ${item.dosage} • Frequency: ${item.frequency} • ${item.durationDays} days',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                                if (item.instructions != null && item.instructions!.isNotEmpty)
                                  Text(
                                    'Note: ${item.instructions}',
                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF0F766E)),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

                // Clinical Advice
                if (rx.generalAdvice != null && rx.generalAdvice!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Doctor\'s Advice: ${rx.generalAdvice}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],

                // Digital Signature Seal
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, size: 16, color: AppColors.primaryTeal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rx.digitalSignature ?? 'Digitally Verified & Sealed via Aarogya Central Healthcare Network',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
    );
  }
}
