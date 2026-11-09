import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/patient.dart';
import '../models/telemetry.dart';
import '../data/sample_clinical_data.dart';
import '../widgets/status_badge.dart';
import '../widgets/heart_rate_sparkline.dart';
import '../widgets/prescription_row.dart';
import 'modals/soap_note_dialog.dart';
import 'modals/eprescribe_dialog.dart';
import 'modals/ecg_waveform_dialog.dart';

class PatientTelemetryScreen extends StatefulWidget {
  final Patient patient;

  const PatientTelemetryScreen({super.key, required this.patient});

  @override
  State<PatientTelemetryScreen> createState() => _PatientTelemetryScreenState();
}

class _PatientTelemetryScreenState extends State<PatientTelemetryScreen> {
  late List<MedicationItem> medications;

  @override
  void initState() {
    super.initState();
    medications = List.from(SampleClinicalData.rahulMedications);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient RPM Telemetry', style: AppTypography.headlineSm.copyWith(fontSize: 16)),
            Text('Aarogya HealthPro • Clinical Care Provider Portal', style: AppTypography.bodySm.copyWith(fontSize: 11)),
          ],
        ),
        actions: [
          const StatusBadge(
            label: 'Live',
            variant: BadgeVariant.mint,
            showDot: true,
            height: 24,
            horizontalPadding: 8,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _showAddOptions(context),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Rx / Note', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientOverviewCard(p),
            const SizedBox(height: 14),
            _buildWearableDeviceCard(),
            const SizedBox(height: 14),
            _buildHeartRateTrendCard(context),
            const SizedBox(height: 14),
            _buildBloodPressureCuffCard(),
            const SizedBox(height: 14),
            _buildSpo2Card(),
            const SizedBox(height: 14),
            _buildMedicationRegimenCard(context),
            const SizedBox(height: 14),
            _buildClinicalNotesCard(context),
            const SizedBox(height: 14),
            _buildDoctorClinicalActions(context),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientOverviewCard(Patient p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFCEEAE2),
                child: Text(
                  p.initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AppTypography.headlineSm.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Age: ${p.age}, ${p.gender == "M" ? "Male" : "Female"}',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'ABHA ID: ${p.abhaId}',
              style: AppTypography.clinicalCode.copyWith(fontSize: 11, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.mintChipBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_outline, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Essential Stage II HTN & Post-PCI (Stent LAD) 2023',
                    style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.medical_information_outlined, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attending Physician: ${p.attendingPhysician}', style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600)),
                    Text('Affiliated Clinic: ${p.clinic}', style: AppTypography.bodySm),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Proxy/Caregiver
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AUTHORIZED PROXY / CAREGIVER', style: AppTypography.labelSm.copyWith(fontSize: 9.5)),
                      Text(p.proxyCaregiver, style: AppTypography.bodySm.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const StatusBadge(
                  label: 'Verified',
                  variant: BadgeVariant.mint,
                  height: 18,
                  horizontalPadding: 6,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Allergies Warning
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.criticalRedWash,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.criticalRedBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.criticalRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CRITICAL CLINICAL ALLERGIES', style: AppTypography.labelSm.copyWith(color: AppColors.criticalRed, fontSize: 9.5)),
                      Text(p.allergies, style: AppTypography.bodySm.copyWith(color: AppColors.criticalRed, fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildWearableDeviceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFCEEAE2)),
        boxShadow: AppColors.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3.5,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.watch_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'boAt Wave Pro',
                      style: AppTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Critical Measurement: 10:12 AM IST • Last Server Sync: 2m ago via Common Backend',
                  style: AppTypography.bodySm.copyWith(fontSize: 11, color: AppColors.onSurface),
                ),
                const SizedBox(height: 3),
                Text(
                  'Telemetry Grade: Consumer Wearable - Not Standalone Clinical Diagnostic',
                  style: AppTypography.bodySm.copyWith(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateTrendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite, size: 16, color: AppColors.mintAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Continuous Resting Heart Rate (24h Trend)',
                    style: AppTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Continuous PPG sensor telemetry across 15-minute sampling epochs',
            style: AppTypography.bodySm.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 6),
          const StatusBadge(
            label: 'Threshold: > 100 BPM Tachycardia',
            variant: BadgeVariant.critical,
            height: 20,
            horizontalPadding: 8,
          ),
          const SizedBox(height: 12),
          // 3 Metrics Columns
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT PULSE', style: AppTypography.labelSm.copyWith(fontSize: 9)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('72', style: AppTypography.metricDisplay.copyWith(fontSize: 22, color: AppColors.primary)),
                          const SizedBox(width: 2),
                          const Text('BPM', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      Row(
                        children: const [
                          Icon(Icons.check, size: 11, color: AppColors.stableGreen),
                          SizedBox(width: 2),
                          Text('Normal Sinus', style: TextStyle(fontSize: 9.5, color: AppColors.stableGreen, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('24h MINIMUM', style: AppTypography.labelSm.copyWith(fontSize: 9)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('58', style: AppTypography.metricDisplay.copyWith(fontSize: 22, color: AppColors.darkSlate)),
                          const SizedBox(width: 2),
                          const Text('BPM', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      const Text('04:12 AM\n(Rest / Sleep)', style: TextStyle(fontSize: 9, color: AppColors.textMuted, height: 1.1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('24h PEAK / MAX', style: AppTypography.labelSm.copyWith(fontSize: 9)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('124', style: AppTypography.metricDisplay.copyWith(fontSize: 22, color: AppColors.criticalRed)),
                          const SizedBox(width: 2),
                          const Text('BPM', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                      const Text('10:30 PM\n(EXERTION)', style: TextStyle(fontSize: 9, color: AppColors.criticalRed, fontWeight: FontWeight.w600, height: 1.1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Chart
          HeartRateTrendChart(
            points: SampleClinicalData.heartRate24hPoints,
            onEcgTap: () {
              showDialog(
                context: context,
                builder: (_) => EcgWaveformDialog(patientName: widget.patient.name, bpm: 72),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureCuffCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Blood Pressure Cuff', style: AppTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const StatusBadge(
                label: 'Target Met',
                variant: BadgeVariant.stable,
                height: 20,
                horizontalPadding: 8,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('120/80', style: AppTypography.metricDisplay.copyWith(fontSize: 28, color: AppColors.darkSlate)),
              const SizedBox(width: 6),
              Text('mmHg', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Logged yesterday via verified clinical cuff (Omron HEM-7120)',
            style: AppTypography.bodySm.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 10),
          // Target Protocol Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TARGET PROTOCOL', style: AppTypography.labelSm.copyWith(fontSize: 9.5)),
                Text('< 130/<80 mmHg', style: AppTypography.clinicalCode.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(
              children: [
                Expanded(flex: 5, child: Container(height: 6, color: AppColors.stableGreen)),
                Expanded(flex: 2, child: Container(height: 6, color: AppColors.warningAmber)),
                Expanded(flex: 2, child: Container(height: 6, color: AppColors.criticalRed)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clinical Target Window: Optimal Controlled Range',
            style: AppTypography.bodySm.copyWith(fontSize: 10, color: AppColors.stableGreen, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSpo2Card() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.air, size: 16, color: AppColors.mintAccent),
                  const SizedBox(width: 6),
                  Text('SpO2 & Respiration', style: AppTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const StatusBadge(
                label: 'Optimal',
                variant: BadgeVariant.stable,
                height: 20,
                horizontalPadding: 8,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('98%', style: AppTypography.metricDisplay.copyWith(fontSize: 28, color: AppColors.primary)),
              const SizedBox(width: 6),
              Text('Oxygen Saturation', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCEEAE2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bedtime_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sleep-Oximetry Guard', style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontSize: 10)),
                      Text(
                        'No nocturnal hypoxemia detected. Mean overnight SpO2 was 97.6%, with stable respiratory rate (16 bpm).',
                        style: AppTypography.bodySm.copyWith(fontSize: 10.5, color: AppColors.onSurface),
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

  Widget _buildMedicationRegimenCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.medication, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Active Medication Regimen', style: AppTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const StatusBadge(
                label: 'Overall: 96%',
                variant: BadgeVariant.mint,
                height: 20,
                horizontalPadding: 8,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Real-time daily adherence logged via patient portal', style: AppTypography.bodySm.copyWith(fontSize: 11)),
          const SizedBox(height: 12),
          ...medications.map(
            (med) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: PrescriptionTrackerRow(
                item: med,
                onToggleLogged: (logged) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${med.name} dose marked as ${logged ? "taken" : "pending"}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onMoreOptions: () {
                  showDialog(
                    context: context,
                    builder: (_) => EPrescribeDialog(
                      patient: widget.patient,
                      onPrescribed: (d, dose) {},
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalNotesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Recent Clinical Notes & FHIR', style: AppTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
              const Icon(Icons.sync, size: 16, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 2),
          Text('FHIR R4 DiagnosticReport / Observation Sync', style: AppTypography.bodySm.copyWith(fontSize: 11)),
          const SizedBox(height: 12),
          ...SampleClinicalData.rahulClinicalNotes.map((note) => _buildNoteItem(note)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening longitudinal ABDM Health Records vault...')),
                );
              },
              child: const Text('View Complete Patient Longitudinal Record', style: TextStyle(fontSize: 11.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(ClinicalSoapNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(note.date, style: AppTypography.labelSm.copyWith(fontSize: 10.5, color: AppColors.primary)),
              StatusBadge(
                label: note.encounterType,
                variant: BadgeVariant.neutral,
                height: 18,
                horizontalPadding: 6,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note.summaryText,
            style: AppTypography.bodySm.copyWith(fontSize: 11, height: 1.3),
          ),
          if (note.loincCode != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Encounter Code: ${note.loincCode}', style: AppTypography.clinicalCode.copyWith(fontSize: 9.5)),
                Text(note.emrSync, style: AppTypography.clinicalCode.copyWith(fontSize: 9.5, color: AppColors.textMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorClinicalActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Doctor Clinical Actions', style: AppTypography.headlineSm.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Physician authorised clinical workflows and prescription modification suite',
            style: AppTypography.bodySm.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 12),
          _buildActionRow(
            icon: Icons.edit_note,
            iconColor: AppColors.primary,
            title: 'Record Clinical Progress Note (SOAP format)',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => SoapNoteDialog(patient: widget.patient),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionRow(
            icon: Icons.medication_outlined,
            iconColor: AppColors.mintAccent,
            title: 'Modify Prescription / Dosage',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => EPrescribeDialog(patient: widget.patient),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionRow(
            icon: Icons.biotech_outlined,
            iconColor: const Color(0xFF6366F1),
            title: 'Order Diagnostic Lab Test',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order sent to Apollo HealthCity Pathology Lab (Lipid Panel + HbA1c).')),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildActionRow(
            icon: Icons.event_available_outlined,
            iconColor: AppColors.warningAmber,
            title: 'Schedule Follow-Up OPD',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Follow-Up OPD scheduled for next Tuesday 10:30 AM.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMd.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Clinical Record', style: AppTypography.headlineSm),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.edit_note, color: AppColors.primary),
                  title: const Text('Add SOAP Progress Note'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => SoapNoteDialog(patient: widget.patient),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication, color: AppColors.mintAccent),
                  title: const Text('Modify or Add Medication Rx'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => EPrescribeDialog(patient: widget.patient),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.show_chart, color: Color(0xFF6BD8CB)),
                  title: const Text('View Full Lead-II ECG Waveform'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (_) => EcgWaveformDialog(patientName: widget.patient.name),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
