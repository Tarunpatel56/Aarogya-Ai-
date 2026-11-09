import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../theme/app_theme.dart';
import '../widgets/ecg_sparkline.dart';

class HandoverReportScreen extends StatefulWidget {
  final EmergencyRequest request;
  final VoidCallback onBack;
  final VoidCallback onFinishTrip;

  const HandoverReportScreen({
    super.key,
    required this.request,
    required this.onBack,
    required this.onFinishTrip,
  });

  @override
  State<HandoverReportScreen> createState() => _HandoverReportScreenState();
}

class _HandoverReportScreenState extends State<HandoverReportScreen> {
  bool isTransmitted = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Patient & Dispatch Routing Summary Banner
            _buildPatientHeaderCard(req),
            const SizedBox(height: 14),

            // 2. Pre-Hospital Telemetry & Wearable Cross-Verification
            _buildWearableCrossVerificationSection(req),
            const SizedBox(height: 14),

            // 3. On-Scene Paramedic Manual Log (ALS Monitor)
            _buildParamedicManualLogCard(req),
            const SizedBox(height: 14),

            // 4. Known Diagnoses Card
            _buildKnownDiagnosesCard(req),
            const SizedBox(height: 14),

            // 5. High Alert Allergies Card (Critical Warning)
            _buildHighAlertAllergiesCard(req),
            const SizedBox(height: 14),

            // 6. Current Daily Medications Card
            _buildDailyMedicationsCard(req),
            const SizedBox(height: 14),

            // 7. Pre-Arrival Paramedic Handover Form (SBAR / MIST)
            _buildSbarHandoverForm(req),
            const SizedBox(height: 16),

            // 8. Transmission & Handover Action Buttons
            _buildHandoverActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: SanctuaryColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SanctuaryColors.deepSlateNavy),
        onPressed: widget.onBack,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const Icon(Icons.emergency_outlined, color: SanctuaryColors.crimsonRose, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aarogya Rapid',
                  style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Incident #${widget.request.id}',
                  style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: SanctuaryColors.optimalGreenBg,
            borderRadius: SanctuaryRadius.rFull,
            border: Border.all(color: SanctuaryColors.optimalGreenBorder),
          ),
          child: const Text(
            'HANDOVER REPORT',
            style: TextStyle(
              color: SanctuaryColors.optimalGreen,
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: SanctuaryColors.hairlineBorder),
      ),
    );
  }

  Widget _buildPatientHeaderCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_ind_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${req.patientName}, ${req.patientAge}${req.patientGender}',
                      style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF3FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ABHA ID: ${req.abhaId}',
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Trigger Source: Aarogya AI Patient App SOS Trigger (Continuous / Defibrillator mode)',
            style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
          ),
          const SizedBox(height: 10),

          // Trigger Time & Dispatch Status Pills
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('TRIGGER TIME', style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('10:11 AM (23 min ago)', style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SanctuaryColors.optimalGreenBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SanctuaryColors.optimalGreenBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('DISPATCH STATUS', style: TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Patient Transporting to Hospital', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Destination & ETA
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: SanctuaryRadius.rBase,
              border: Border.all(color: SanctuaryColors.hairlineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 14, color: SanctuaryColors.primaryTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Destination: ${req.receivingHospital}, ${req.hospitalBay}',
                        style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.route_outlined, size: 14, color: SanctuaryColors.optimalGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ETA: ${req.eta} (Traffic prioritized via Green Corridor)',
                        style: const TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWearableCrossVerificationSection(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined, color: SanctuaryColors.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pre-Hospital Patient Telemetry & Wearable Cross-Verification',
                  style: SanctuaryTypography.labelMd(color: SanctuaryColors.deepSlateNavy).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Synchronized comparison between consumer continuous sensor & certified ALS Paramedic equipment.',
            style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: SanctuaryColors.optimalGreenBg,
              borderRadius: SanctuaryRadius.rFull,
              border: Border.all(color: SanctuaryColors.optimalGreenBorder),
            ),
            child: const Text(
              '✓ Dual Channel Validated',
              style: TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          // Consumer Wearable Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: SanctuaryRadius.rBase,
              border: Border.all(color: SanctuaryColors.hairlineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.watch_outlined, size: 14, color: SanctuaryColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          req.wearableDevice,
                          style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Synced via Aarogya App',
                        style: TextStyle(color: Color(0xFF2563EB), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Continuous Heart Rate & ECG Line
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('CONTINUOUS HEART RATE', style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text('10:35:12 IST', style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 9)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: '${req.heartRate} ', style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
                                TextSpan(
                                  text: req.heartRate > 100 ? 'BPM (Tachycardic)' : 'BPM (Normal)',
                                  style: TextStyle(
                                    color: req.heartRate > 100 ? SanctuaryColors.warningAmber : SanctuaryColors.optimalGreen,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Animated Live ECG Sparkline!
                      const EcgSparklineWidget(
                        lineColor: SanctuaryColors.primaryTeal,
                        height: 38,
                        animate: true,
                        isTachycardia: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // SpO2
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PULSE OXIMETRY (SPO2)', style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('${req.spo2}%  (Plethysmography)', style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: SanctuaryColors.optimalGreenBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Stable', style: TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: const [
                    Icon(Icons.bluetooth_connected, size: 12, color: SanctuaryColors.primaryTeal),
                    SizedBox(width: 4),
                    Text(
                      'Latency: 42 ms • Device battery: 74% (BLE Paired)',
                      style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamedicManualLogCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'On-Scene\nParamedic Manual\nLog',
                style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Continuous Defib\n& ALS Monitor',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold, height: 1.15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.verified, size: 12, color: SanctuaryColors.primaryTeal),
              SizedBox(width: 4),
              Text(
                'Certified ALS Paramedic Entry • 10:20:11 Log',
                style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5-Metric Telemetry Grid
          Row(
            children: [
              Expanded(
                child: _buildParamedicMetricBox(
                  label: 'NIBP (BP)',
                  value: '135/90',
                  unit: 'mmHg (MAP 105)',
                  badge: 'Verified Normal',
                  badgeColor: SanctuaryColors.optimalGreen,
                  badgeBg: SanctuaryColors.optimalGreenBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildParamedicMetricBox(
                  label: 'AVG PULSE',
                  value: '108',
                  unit: 'BPM',
                  badge: 'Regular Rhythm',
                  badgeColor: SanctuaryColors.primaryTeal,
                  badgeBg: const Color(0xFFCCFBF1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildParamedicMetricBox(
                  label: 'SPO2 (ALS)',
                  value: '97%',
                  unit: 'On Room Air',
                  badge: 'Pleth Waveform OK',
                  badgeColor: SanctuaryColors.optimalGreen,
                  badgeBg: SanctuaryColors.optimalGreenBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildParamedicMetricBox(
                  label: 'GCS SCORE',
                  value: '15/15',
                  unit: 'E4 V5 M6',
                  badge: 'Alert & Oriented',
                  badgeColor: SanctuaryColors.primaryTeal,
                  badgeBg: const Color(0xFFCCFBF1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildParamedicMetricBox(
            label: 'GLUCOSE',
            value: '118',
            unit: 'mg/dL (Accu-Chek)',
            badge: 'Normoglycemic',
            badgeColor: SanctuaryColors.optimalGreen,
            badgeBg: SanctuaryColors.optimalGreenBg,
          ),
          const SizedBox(height: 10),

          // Lead II & 12-Lead ECG Observation Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: SanctuaryRadius.rBase,
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.monitor_heart, color: SanctuaryColors.primaryTeal, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lead II & 12-Lead ECG: Sinus tachycardia, no acute ST-elevation in "field observation" 12-lead screening.',
                        style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Logged by: Paramedic V. Nambiar (#P-408181)',
                  style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamedicMetricBox({
    required String label,
    required String value,
    required String unit,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: SanctuaryRadius.rBase,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: SanctuaryColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$value ', style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                TextSpan(text: unit, style: const TextStyle(color: SanctuaryColors.textSecondary, fontSize: 9.5)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnownDiagnosesCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.folder_shared_outlined, color: SanctuaryColors.primaryTeal, size: 18),
              SizedBox(width: 8),
              Text(
                'Known Diagnoses',
                style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...req.diagnoses.map((diag) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 6, color: SanctuaryColors.primaryTeal),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        diag,
                        style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHighAlertAllergiesCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.errorWash,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.errorBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: SanctuaryColors.crimsonRose, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'High Alert Allergies',
                    style: TextStyle(color: SanctuaryColors.crimsonRose, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SanctuaryColors.emergencyRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('CRITICAL', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            req.allergyName,
            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.emergencyRed).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Reaction: ${req.allergyReaction}',
            style: const TextStyle(color: SanctuaryColors.crimsonRose, fontWeight: FontWeight.w600, fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Contraindicated: ${req.allergyContraindications}',
            style: const TextStyle(color: SanctuaryColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMedicationsCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.medication_outlined, color: SanctuaryColors.primaryTeal, size: 18),
              SizedBox(width: 8),
              Text(
                'Current Daily Meds',
                style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...req.medications.map((med) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: SanctuaryColors.hairlineBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            med.timing,
                            style: const TextStyle(color: SanctuaryColors.textSecondary, fontSize: 10.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      med.category,
                      style: const TextStyle(color: SanctuaryColors.primaryTeal, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSbarHandoverForm(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.assignment_outlined, color: SanctuaryColors.primaryTeal, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pre-Arrival Paramedic\nHandover Form',
                      style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Certified Paramedic SBAR / 1.38 MR Clinical Summary for Receiving Cath Lab Team',
                      style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Attending Physician Link Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: SanctuaryRadius.rBase,
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFF0369A1), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Attending Physician Link', style: TextStyle(color: Color(0xFF0369A1), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      Text(
                        '${req.assignedDoctor} (${req.receivingHospital})',
                        style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Text('Intercom Voice Radio Ch. 4 Active', style: TextStyle(color: Color(0xFF0284C7), fontSize: 9.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // S - SITUATION
          _buildSbarItem(
            prefix: 'S - SITUATION',
            content: req.sbarSituation,
          ),
          const SizedBox(height: 8),

          // B - BACKGROUND
          _buildSbarItem(
            prefix: 'B - BACKGROUND',
            content: req.sbarBackground,
          ),
          const SizedBox(height: 8),

          // A - ASSESSMENT
          _buildSbarItem(
            prefix: 'A - ASSESSMENT',
            content: req.sbarAssessment,
          ),
          const SizedBox(height: 8),

          // R - RECOMMENDATION
          _buildSbarItem(
            prefix: 'R - RECOMMENDATION',
            content: req.sbarRecommendation,
          ),
          const SizedBox(height: 10),

          // En-route Rx / Rescue Interventions
          ClipRRect(
            borderRadius: SanctuaryRadius.rBase,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3.0, color: SanctuaryColors.optimalGreen),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 16, color: SanctuaryColors.optimalGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'En-route Rx / Rescue Interventions:',
                                    style: TextStyle(color: SanctuaryColors.optimalGreen, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    req.enrouteInterventions,
                                    style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11.5, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSbarItem({required String prefix, required String content}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: SanctuaryRadius.rBase,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prefix, style: const TextStyle(color: SanctuaryColors.primaryTeal, fontSize: 10.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(content, style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11.5, height: 1.35)),
        ],
      ),
    );
  }

  void _showMissionAccomplishedDialog(EmergencyRequest req) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebratory Green Checkmark Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                '🎉 Emergency Mission Accomplished!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17.5,
                  color: SanctuaryColors.deepSlateNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thank you for your life-saving service! Patient has been safely handed over to the ER Trauma Team.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: SanctuaryColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Summary Details Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SanctuaryColors.hairlineBorder),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('Patient Name:', '${req.patientName} (${req.patientGender}, ${req.patientAge}y)'),
                    const SizedBox(height: 6),
                    _buildDialogRow('Blood Group:', req.bloodGroup),
                    const SizedBox(height: 6),
                    _buildDialogRow('Receiving ER:', '${req.receivingHospital} • ${req.hospitalBay}'),
                    const SizedBox(height: 6),
                    _buildDialogRow('Doctor in Charge:', req.assignedDoctor),
                    const SizedBox(height: 6),
                    _buildDialogRow('Vitals Synced:', 'HR: ${req.heartRate} bpm • SpO2: ${req.spo2}%'),
                    const SizedBox(height: 6),
                    _buildDialogRow('ABDM Handover:', '✓ Signed & Cryptographically Encrypted'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Big Action Button: READY FOR NEXT ORDER
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.onFinishTrip();
                  },
                  icon: const Icon(Icons.radar_rounded, size: 20),
                  label: const Text(
                    'READY FOR NEXT ORDER / STANDBY',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: SanctuaryColors.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: SanctuaryColors.deepSlateNavy),
          ),
        ),
      ],
    );
  }

  Widget _buildHandoverActionButtons() {
    final req = widget.request;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _showMissionAccomplishedDialog(req),
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            label: const Text(
              'COMPLETE RESCUE & HANDOVER TO HOSPITAL',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: SanctuaryRadius.rBase),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                isTransmitted = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ABDM Handover sheet transmitted to Hospital ER & printed!'),
                  backgroundColor: SanctuaryColors.primaryTeal,
                ),
              );
            },
            icon: const Icon(Icons.print_outlined, size: 17, color: SanctuaryColors.deepSlateNavy),
            label: Text(
              isTransmitted ? '✓ Handover Sheet Transmitted' : 'Print / Transmit Handover Sheet',
              style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: SanctuaryColors.hairlineBorder),
              shape: RoundedRectangleBorder(borderRadius: SanctuaryRadius.rBase),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Icon(Icons.verified_user_outlined, size: 12, color: SanctuaryColors.optimalGreen),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'Physical cryptographic signatures valid • Sync Queue: 0 pending',
                style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: const [
            Icon(Icons.lock_clock_outlined, size: 12, color: SanctuaryColors.primaryTeal),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'ABDM M3 Compliant (Aadhaar Based Digital Signature)',
                style: TextStyle(color: SanctuaryColors.primaryTeal, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
