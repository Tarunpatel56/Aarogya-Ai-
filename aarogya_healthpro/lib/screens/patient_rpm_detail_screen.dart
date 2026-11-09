import 'package:flutter/material.dart';
import '../theme/clinical_sanctuary_theme.dart';
import '../models/patient_model.dart';
import '../widgets/sparkline_chart.dart';
import '../widgets/bp_gauge_bar.dart';
import 'doctor_imaging_review_screen.dart';

class PatientRpmDetailScreen extends StatefulWidget {
  final PatientModel? patient;
  final VoidCallback? onBack;

  const PatientRpmDetailScreen({
    super.key,
    this.patient,
    this.onBack,
  });

  @override
  State<PatientRpmDetailScreen> createState() => _PatientRpmDetailScreenState();
}

class _PatientRpmDetailScreenState extends State<PatientRpmDetailScreen> {
  late PatientModel _patient;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient ?? PatientModel.samplePatients[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: ClinicalSpacing.margin,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientProfileHeaderCard(),
            const SizedBox(height: 16),
            _buildConnectedDeviceCard(),
            const SizedBox(height: 16),
            _buildHeartRateTrendCard(),
            const SizedBox(height: 16),
            _buildBloodPressureCard(),
            const SizedBox(height: 16),
            _buildSpo2RespirationCard(),
            const SizedBox(height: 16),
            _buildMedicationRegimenCard(),
            const SizedBox(height: 16),
            _buildRecentClinicalNotesFhirCard(),
            const SizedBox(height: 16),
            _buildDoctorClinicalActions(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: ClinicalColors.deepSlateNavy),
        onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Patient RPM Telemetry',
                  style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                      .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalWash,
                  borderRadius: ClinicalRadii.roundedFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ClinicalColors.optimalEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                          .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            'Aarogya HealthPro • Clinical Care Provider Portal',
            style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 10),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: ClinicalColors.primaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: ClinicalRadii.roundedSm,
              ),
            ),
            icon: const Icon(Icons.sync_rounded, size: 14),
            label: const Text(
              'ABDM / Sync',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ClinicalColors.optimalWash,
                child: Text(
                  _patient.initials,
                  style: const TextStyle(
                    color: ClinicalColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patient.name,
                      style: ClinicalTypography.headlineMd(
                        color: ClinicalColors.deepSlateNavy,
                      ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Age: ${_patient.age}, ${_patient.gender == 'M' ? 'Male' : 'Female'}',
                          style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                              .copyWith(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ClinicalColors.surfaceInset,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ABHA ID: ${_patient.abhaId}',
                            style: ClinicalTypography.labelSm(
                              color: ClinicalColors.deepSlateNavy,
                            ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClinicalColors.optimalWash.withOpacity(0.5),
                        borderRadius: ClinicalRadii.roundedSm,
                      ),
                      child: Text(
                        _patient.primaryDiagnosis,
                        style: ClinicalTypography.bodySm(
                          color: ClinicalColors.primaryDark,
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: ClinicalColors.hairlineBorder),
          const SizedBox(height: 10),

          // Attending Physician
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.medical_services_outlined, size: 16, color: ClinicalColors.primaryTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attending Physician',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 10),
                    ),
                    Text(
                      _patient.attendingPhysician,
                      style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Caregiver info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 16, color: ClinicalColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUTHORIZED PROXY / CAREGIVER',
                        style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                            .copyWith(fontSize: 9),
                      ),
                      Text(
                        _patient.caregiver,
                        style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                            .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ClinicalColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ClinicalColors.hairlineBorder),
                  ),
                  child: Text(
                    'Verified',
                    style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                        .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Critical Allergies Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicalColors.criticalWash,
              borderRadius: ClinicalRadii.roundedSm,
              border: Border.all(color: ClinicalColors.criticalBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: ClinicalColors.crimsonRose),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRITICAL CLINICAL ALLERGIES',
                        style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                            .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _patient.allergies,
                        style: ClinicalTypography.bodySm(color: ClinicalColors.darkRedCta)
                            .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.bookmark_added_rounded, size: 16, color: ClinicalColors.crimsonRose),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.optimalBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalWash,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: const Icon(
                  Icons.watch_rounded,
                  color: ClinicalColors.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'boAt Wave Pro',
                      style: ClinicalTypography.headlineSm(
                        color: ClinicalColors.deepSlateNavy,
                      ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Connected via Aarogya Patient App, Direct BLE Measurement • Last Server Sync: ${_patient.lastDeviceSync}',
                      style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: ClinicalColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Telemetry Source: Consumer Wearable - Not Standalone Clinical Diagnostic',
                    style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                        .copyWith(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateTrendCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalWash,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: ClinicalColors.primaryTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continuous Resting Heart Rate (24h Trend)',
                      style: ClinicalTypography.headlineSm(
                        color: ClinicalColors.deepSlateNavy,
                      ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Continuous PPG sensor telemetry across 15-minute sampling epochs',
                      style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ClinicalColors.criticalWash,
              borderRadius: ClinicalRadii.roundedFull,
              border: Border.all(color: ClinicalColors.criticalBorder),
            ),
            child: Text(
              '• Threshold > 100 BPM Tachycardia',
              style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Column metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'CURRENT PULSE',
                  value: '72',
                  unit: 'BPM',
                  sub: 'Normal Sinus',
                  subColor: ClinicalColors.optimalEmerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: '24H MINIMUM',
                  value: '58',
                  unit: 'BPM',
                  sub: '04:12 AM (Rest/Sleep)',
                  subColor: ClinicalColors.deepSlateNavy,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: '24H PEAK / MAX',
                  value: '124',
                  unit: 'BPM',
                  sub: 'EXERTION DETECTED',
                  subColor: ClinicalColors.crimsonRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sparkline Chart
          SparklineChart(
            dataPoints: _patient.hrTrend24h,
            thresholdValue: 100.0,
            minValue: 50.0,
            maxValue: 135.0,
            height: 130.0,
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ClinicalColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Synchronized telemetry stream (15-min burst)',
                    style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                        .copyWith(fontSize: 10),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View Full ECG Waveform',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.primaryTeal)
                          .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.open_in_new_rounded, size: 12, color: ClinicalColors.primaryTeal),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required String sub,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceInset,
        borderRadius: ClinicalRadii.roundedSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: ClinicalTypography.metricDisplay(color: ClinicalColors.deepSlateNavy)
                    .copyWith(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                    .copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: ClinicalTypography.labelSm(color: subColor)
                .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ClinicalColors.infoWash,
                      borderRadius: ClinicalRadii.roundedSm,
                    ),
                    child: const Icon(
                      Icons.speed_rounded,
                      color: ClinicalColors.infoCobalt,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Blood Pressure Cuff',
                    style: ClinicalTypography.headlineSm(
                      color: ClinicalColors.deepSlateNavy,
                    ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalWash,
                  borderRadius: ClinicalRadii.roundedFull,
                  border: Border.all(color: ClinicalColors.optimalBorder),
                ),
                child: Text(
                  'Target Met',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _patient.bloodPressure,
                style: ClinicalTypography.metricDisplay(color: ClinicalColors.deepSlateNavy)
                    .copyWith(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                'mmHg',
                style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted),
              ),
            ],
          ),
          Text(
            'Logged yesterday via verified clinical cuff (Omron HEM-7120)',
            style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 11),
          ),
          const SizedBox(height: 12),
          const BpGaugeBar(systolic: 120, diastolic: 80),
        ],
      ),
    );
  }

  Widget _buildSpo2RespirationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ClinicalColors.optimalWash,
                      borderRadius: ClinicalRadii.roundedSm,
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: ClinicalColors.primaryTeal,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SpO2 & Respiration',
                    style: ClinicalTypography.headlineSm(
                      color: ClinicalColors.deepSlateNavy,
                    ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalWash,
                  borderRadius: ClinicalRadii.roundedFull,
                  border: Border.all(color: ClinicalColors.optimalBorder),
                ),
                child: Text(
                  'Optimal',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_patient.spo2}%',
                style: ClinicalTypography.metricDisplay(color: ClinicalColors.deepSlateNavy)
                    .copyWith(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                'Oxygen Saturation',
                style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.bedtime_outlined,
                  size: 16,
                  color: ClinicalColors.primaryTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                          .copyWith(fontSize: 11, height: 1.35),
                      children: const [
                        TextSpan(
                          text: 'Sleep-Oximetry Guard: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'No nocturnal hypoxemia detected. Mean overnight SpO2 was 97.5%, with stable respiratory rate (16 bpm).',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationRegimenCard() {
    final meds = [
      {
        'name': 'Metformin 500mg',
        'timing': 'Morning • Post-Meal',
        'status': 'Taken 8:45 AM today • Adherence: 95%',
        'icon': Icons.check_circle_rounded,
        'iconColor': ClinicalColors.optimalEmerald,
      },
      {
        'name': 'Telmisartan 40mg',
        'timing': 'Evening',
        'status': 'Due 8:00 PM today • Adherence: 98%',
        'icon': Icons.access_time_rounded,
        'iconColor': ClinicalColors.warningAmber,
      },
      {
        'name': 'Atorvastatin 20mg',
        'timing': 'Bedtime',
        'status': 'Scheduled for 10:00 PM • 30-Day Refill Active',
        'icon': Icons.nightlight_round,
        'iconColor': ClinicalColors.secondary,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: ClinicalColors.secondaryContainer.withOpacity(0.5),
                      borderRadius: ClinicalRadii.roundedSm,
                    ),
                    child: const Icon(
                      Icons.medication_liquid_rounded,
                      color: ClinicalColors.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active Medication Regimen',
                    style: ClinicalTypography.headlineSm(
                      color: ClinicalColors.deepSlateNavy,
                    ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClinicalColors.surfaceInset,
                  borderRadius: ClinicalRadii.roundedFull,
                ),
                child: Text(
                  'Overall: 96%',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.deepSlateNavy)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Real-time daily adherence logged via patient portal',
            style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 10),
          ),
          const SizedBox(height: 12),

          ...meds.map((m) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ClinicalColors.surfaceInset,
                borderRadius: ClinicalRadii.roundedSm,
                border: Border.all(color: ClinicalColors.hairlineBorder.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(m['icon'] as IconData, size: 20, color: m['iconColor'] as Color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m['name'] as String,
                              style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                                  .copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: ClinicalColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                m['timing'] as String,
                                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                    .copyWith(fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['status'] as String,
                          style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                              .copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.more_vert, size: 16, color: ClinicalColors.textMuted),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentClinicalNotesFhirCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalWash,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: ClinicalColors.primaryTeal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Clinical Notes & FHIR',
                      style: ClinicalTypography.headlineSm(
                        color: ClinicalColors.deepSlateNavy,
                      ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'FHIR R4 DiagnosticReport / Observation Sync',
                      style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Note 1
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '12 Nov 2024 • Tele-Encounter',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.deepSlateNavy)
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: ClinicalColors.optimalWash,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'SOAP Validated',
                        style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                            .copyWith(fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '"S/O Non-diabetic reported mild evening dizziness. Advised hydration and BP log verification. - Dr. Aarav Mehta"',
                  style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                      .copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  'SNOMED CT Code: LOINC 8480-6 • Apollo HealthCity EHR Sync',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Note 2
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24 Oct 2024 • OPD Follow-Up',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.deepSlateNavy)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  'Echocardiogram: LVEF 55%, stable patient with preserved wall motion. Statin tolerance confirmed.',
                  style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(38),
              foregroundColor: ClinicalColors.deepSlateNavy,
              side: const BorderSide(color: ClinicalColors.hairlineBorder),
              shape: RoundedRectangleBorder(
                borderRadius: ClinicalRadii.rounded,
              ),
            ),
            icon: const Icon(Icons.history_edu_rounded, size: 16),
            label: const Text(
              'View Complete Patient Longitudinal Record',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorClinicalActions() {
    final actions = [
      {'title': 'Review Diagnostic Imaging Studies (MRI / X-Ray / Skin)', 'icon': Icons.image_search_rounded},
      {'title': 'Record Clinical Progress Note (SOAP format)', 'icon': Icons.edit_note_rounded},
      {'title': 'Modify Prescription / Dosage', 'icon': Icons.medication_outlined},
      {'title': 'Order Diagnostic Lab Test', 'icon': Icons.science_outlined},
      {'title': 'Schedule Follow-Up OPD', 'icon': Icons.calendar_month_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doctor Clinical Actions',
                    style: ClinicalTypography.headlineSm(
                      color: ClinicalColors.deepSlateNavy,
                    ).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Physician authorized clinical workflows and prescription suite',
                    style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                        .copyWith(fontSize: 10),
                  ),
                ],
              ),
              const Icon(Icons.local_hospital_outlined, color: ClinicalColors.primaryTeal, size: 20),
            ],
          ),
          const SizedBox(height: 12),

          ...actions.map((act) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: ClinicalColors.surfaceInset,
                borderRadius: ClinicalRadii.roundedSm,
                border: Border.all(color: ClinicalColors.hairlineBorder.withOpacity(0.5)),
              ),
              child: InkWell(
                borderRadius: ClinicalRadii.roundedSm,
                onTap: () {
                  if (act['icon'] == Icons.image_search_rounded) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DoctorImagingReviewScreen(),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: ClinicalColors.optimalWash,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(act['icon'] as IconData, size: 18, color: ClinicalColors.primaryTeal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          act['title'] as String,
                          style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                              .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ClinicalColors.textMuted),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
