import 'package:flutter/material.dart';
import '../theme/clinical_sanctuary_theme.dart';
import '../models/alert_model.dart';
import '../models/patient_model.dart';

class TriageScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(PatientModel patient)? onSelectPatient;

  const TriageScreen({
    super.key,
    this.onBack,
    this.onSelectPatient,
  });

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  int _selectedStatusFilter = 0;
  int _selectedSeverityFilter = 0;

  final List<String> _statusTabs = ['New', 'Acknowledged', 'In-Progress', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    final alerts = TriageAlertModel.sampleAlerts;

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
            _buildStatusFilterRow(),
            const SizedBox(height: 14),
            _buildTriageEngineBanner(),
            const SizedBox(height: 14),
            _buildSeverityChips(),
            const SizedBox(height: 12),
            _buildTelemetryNodeStrip(),
            const SizedBox(height: 16),
            _buildCriticalAlertCard(alerts[0]), // Sunita Devi
            const SizedBox(height: 16),
            _buildInProgressAlertCard(alerts[1]), // Rahul Sharma
            const SizedBox(height: 16),
            _buildResolvedAlertCard(alerts[2]), // Vikram Patel
            const SizedBox(height: 24),
            _buildComplianceFooter(),
            const SizedBox(height: 32),
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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: ClinicalColors.optimalWash,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.add_box_rounded,
              color: ClinicalColors.primaryTeal,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AarogyaHealthPro',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 10),
                ),
                Text(
                  'Emergency Alert Triage',
                  style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                      .copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share_rounded, color: ClinicalColors.deepSlateNavy, size: 20),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusFilterRow() {
    return Row(
      children: [
        Text(
          'STATUS :',
          style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
              .copyWith(letterSpacing: 0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_statusTabs.length, (index) {
                final isSelected = _selectedStatusFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatusFilter = index;
                      });
                    },
                    borderRadius: ClinicalRadii.roundedFull,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ClinicalColors.primaryDark
                            : ClinicalColors.surfaceElevated,
                        borderRadius: ClinicalRadii.roundedFull,
                        border: Border.all(
                          color: isSelected
                              ? ClinicalColors.primaryDark
                              : ClinicalColors.hairlineBorder,
                        ),
                      ),
                      child: Text(
                        _statusTabs[index] + (index == 0 ? ' •' : ''),
                        style: ClinicalTypography.labelSm(
                          color: isSelected ? Colors.white : ClinicalColors.textMuted,
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriageEngineBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
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
                  color: ClinicalColors.criticalWash,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: ClinicalColors.crimsonRose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Clinical Triage Engine',
                      style: ClinicalTypography.headlineSm(
                        color: ClinicalColors.deepSlateNavy,
                      ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClinicalColors.optimalWash,
                        borderRadius: ClinicalRadii.roundedSm,
                      ),
                      child: Text(
                        'Configured Hospital Escalation Protocol Active',
                        style: ClinicalTypography.labelSm(
                          color: ClinicalColors.primaryDark,
                        ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Notice: Emergency actions require confirmed backend dispatch acknowledgement. Do not mark resolved without clinical action.',
            style: ClinicalTypography.bodySm(color: ClinicalColors.crimsonRose)
                .copyWith(fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ClinicalColors.criticalWash,
                borderRadius: ClinicalRadii.roundedFull,
                border: Border.all(color: ClinicalColors.criticalBorder),
              ),
              child: Text(
                '• Level 1 Triage',
                style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChips() {
    final chips = [
      {'label': '• Critical Red (2)', 'color': ClinicalColors.crimsonRose, 'wash': ClinicalColors.criticalWash},
      {'label': '• High Warning Amber (3)', 'color': ClinicalColors.warningAmber, 'wash': ClinicalColors.warningWash},
      {'label': '• Resolved (51)', 'color': ClinicalColors.optimalEmerald, 'wash': ClinicalColors.optimalWash},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(chips.length, (index) {
          final isSelected = _selectedSeverityFilter == index;
          final c = chips[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedSeverityFilter = index;
                });
              },
              borderRadius: ClinicalRadii.roundedFull,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? (c['wash'] as Color) : ClinicalColors.surfaceElevated,
                  borderRadius: ClinicalRadii.roundedFull,
                  border: Border.all(
                    color: (c['color'] as Color).withOpacity(0.5),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  c['label'] as String,
                  style: ClinicalTypography.labelSm(color: c['color'] as Color)
                      .copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTelemetryNodeStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceInset,
        borderRadius: ClinicalRadii.roundedSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Telemetry Node: Apollo Hospital aka Cluster',
            style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 10),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ClinicalColors.hairlineBorder),
            ),
            child: Text(
              'SPO > 70% | 88-90%',
              style: ClinicalTypography.labelSm(color: ClinicalColors.deepSlateNavy)
                  .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertCard(TriageAlertModel alert) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.crimsonRose.withOpacity(0.8), width: 1.5),
        boxShadow: ClinicalElevations.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Trigger pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicalColors.crimsonRose,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.radio_button_checked_rounded, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'NEW ALERT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trigger Time: ${alert.triggerTime}',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                      .copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            alert.triggerDevice,
            style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 10),
          ),
          const SizedBox(height: 10),

          // Patient details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${alert.patientName} (${alert.patientGender}, ${alert.patientAge})',
                      style: ClinicalTypography.headlineSm(
                        color: ClinicalColors.deepSlateNavy,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ABHA: ${alert.abhaId}',
                      style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Primary Dx: ${alert.primaryDx}',
                      style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                          .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '• Attending: ${alert.attendingPhysician}',
                      style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClinicalColors.surfaceInset,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: Text(
                  alert.roomOrLocation,
                  style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Priority Dispatch Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ClinicalColors.criticalWash,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Row(
              children: [
                Text(
                  'PRIORITY DISPATCH: ',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                      .copyWith(fontSize: 10),
                ),
                Text(
                  alert.tierLevel,
                  style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                const Spacer(),
                const Icon(
                  Icons.favorite_rounded,
                  color: ClinicalColors.crimsonRose,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Dual Vitals Boxes
          Row(
            children: [
              Expanded(
                child: Container(
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
                            'HEART RATE',
                            style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                .copyWith(fontSize: 9),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: ClinicalColors.criticalWash,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '+45 BPM Spike',
                              style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                                  .copyWith(fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${alert.heartRate}',
                            style: ClinicalTypography.metricDisplay(color: ClinicalColors.crimsonRose)
                                .copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'BPM (Tachycardia)',
                            style: ClinicalTypography.labelSm(color: ClinicalColors.crimsonRose)
                                .copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        'Baseline reading: 72-78 BPM',
                        style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                            .copyWith(fontSize: 9),
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
                            'SPO2 SATURATION',
                            style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                .copyWith(fontSize: 9),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: ClinicalColors.crimsonRose,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'Critical Dip',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${alert.spo2}%',
                            style: ClinicalTypography.metricDisplay(color: ClinicalColors.crimsonRose)
                                .copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ambient Air',
                            style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                .copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                      Text(
                        'Threshold alarm limit < 90%',
                        style: ClinicalTypography.bodySm(color: ClinicalColors.crimsonRose)
                            .copyWith(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Event detection box
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
                  'EVENT DETECTION',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sustained Tachycardia & SpO2 Dip',
                  style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                      .copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ClinicalColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ClinicalColors.hairlineBorder),
                  ),
                  child: Text(
                    alert.eventDetection,
                    style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                        .copyWith(fontSize: 10, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Backend Protocol Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicalColors.optimalWash.withOpacity(0.4),
              borderRadius: ClinicalRadii.roundedSm,
              border: Border.all(color: ClinicalColors.optimalBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: ClinicalColors.primaryTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backend Protocol Activation:',
                        style: ClinicalTypography.labelSm(color: ClinicalColors.primaryDark)
                            .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      Text(
                        alert.backendProtocol,
                        style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                            .copyWith(fontSize: 10, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ClinicalColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: ClinicalColors.optimalBorder),
                        ),
                        child: Text(
                          alert.dispatchCode,
                          style: ClinicalTypography.labelSm(color: ClinicalColors.primaryTeal)
                              .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Primary Actions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ClinicalColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: ClinicalRadii.rounded,
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text(
                'Acknowledge Alert',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: ClinicalColors.darkRedCta,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: ClinicalRadii.rounded,
                ),
              ),
              icon: const Icon(Icons.emergency_rounded, size: 18),
              label: const Text(
                'Trigger Rapid Response',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              foregroundColor: ClinicalColors.deepSlateNavy,
              side: const BorderSide(color: ClinicalColors.hairlineBorder),
              shape: RoundedRectangleBorder(
                borderRadius: ClinicalRadii.rounded,
              ),
            ),
            icon: const Icon(Icons.call_outlined, size: 16),
            label: const Text(
              'Call Patient / Caregiver (+91 98450-XXXXX)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.description_outlined, size: 16, color: ClinicalColors.textMuted),
                    SizedBox(width: 8),
                    Text(
                      'Document clinical action & resolution protocol',
                      style: TextStyle(
                        fontSize: 11,
                        color: ClinicalColors.deepSlateNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ClinicalColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInProgressAlertCard(TriageAlertModel alert) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.warningAmber.withOpacity(0.8), width: 1.5),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicalColors.warningAmber,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: const Text(
                  'ACKNOWLEDGED - IN PROGRESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trigger Time: ${alert.triggerTime}',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.warningAmber)
                      .copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 12, color: ClinicalColors.warningAmber),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'GPS coordinates received: ${alert.gpsLocation ?? 'Indiranagar, Bengaluru'}',
                  style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Patient details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alert.patientName} (${alert.patientGender}, ${alert.patientAge})',
                    style: ClinicalTypography.headlineSm(
                      color: ClinicalColors.deepSlateNavy,
                    ).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ABHA: ${alert.abhaId} • ${alert.triggerDevice}',
                    style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                        .copyWith(fontSize: 10),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClinicalColors.warningWash,
                  borderRadius: ClinicalRadii.roundedSm,
                ),
                child: Text(
                  'Patient Triggered\nSOS Alert',
                  textAlign: TextAlign.center,
                  style: ClinicalTypography.labelSm(color: ClinicalColors.warningAmber)
                      .copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Text(
              'Emergency Contact Notified: ${alert.emergencyContact ?? 'Wife (+91 98450-XXXXX)'}',
              style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                  .copyWith(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 12),

          // Latest Vitals 3-column
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
                  'LATEST VITALS TELEMETRY',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 9),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildTriStat(
                        'Heart Rate',
                        '${alert.heartRate}',
                        'bpm',
                        ClinicalColors.crimsonRose,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTriStat(
                        'SpO2',
                        '${alert.spo2}%',
                        'Safe',
                        ClinicalColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTriStat(
                        'Blood Pressure',
                        alert.bloodPressure ?? '130/85',
                        'mmHg',
                        ClinicalColors.deepSlateNavy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Active Clinical Routing
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceElevated,
              borderRadius: ClinicalRadii.roundedSm,
              border: Border.all(color: ClinicalColors.hairlineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE CLINICAL ROUTING',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 9),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.backendProtocol,
                  style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                      .copyWith(fontSize: 10, height: 1.3),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.circle, size: 8, color: ClinicalColors.warningAmber),
                    SizedBox(width: 4),
                    Text(
                      'Live GPS Telemetry Connected',
                      style: TextStyle(
                        fontSize: 10,
                        color: ClinicalColors.warningAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final rahul = PatientModel.samplePatients[0];
                    widget.onSelectPatient?.call(rahul);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClinicalColors.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: ClinicalRadii.rounded,
                    ),
                  ),
                  child: const Text(
                    'View Dispatch Telemetry',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ClinicalColors.deepSlateNavy,
                    side: const BorderSide(color: ClinicalColors.hairlineBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: ClinicalRadii.rounded,
                    ),
                  ),
                  child: const Text(
                    '+ Add Handover Note',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '📈 Telemetry Post 24h Trend',
              style: ClinicalTypography.labelSm(color: ClinicalColors.primaryTeal)
                  .copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriStat(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ClinicalColors.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 8),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: ClinicalTypography.headlineSm(color: color)
                .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            unit,
            style: ClinicalTypography.labelSm(color: ClinicalColors.textSubtle)
                .copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedAlertCard(TriageAlertModel alert) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalWash,
                  borderRadius: ClinicalRadii.roundedSm,
                  border: Border.all(color: ClinicalColors.optimalBorder),
                ),
                child: Text(
                  '✓ RESOLVED',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              Text(
                'ABHA: ${alert.abhaId}',
                style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                    .copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${alert.patientName} (${alert.patientGender}, ${alert.patientAge})',
            style: ClinicalTypography.headlineSm(
              color: ClinicalColors.deepSlateNavy,
            ).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Event: ${alert.eventDetection}',
            style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Resolution: ${alert.resolutionSummary ?? ''}',
            style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                .copyWith(fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alert.resolvedTimeAgo ?? 'Closed 41m ago',
                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                    .copyWith(fontSize: 10),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClinicalColors.deepSlateNavy,
                  side: const BorderSide(color: ClinicalColors.hairlineBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: ClinicalRadii.roundedSm,
                  ),
                ),
                icon: const Icon(Icons.receipt_long_outlined, size: 14),
                label: const Text(
                  'Audit Log',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceInset,
        borderRadius: ClinicalRadii.roundedMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_user_outlined, size: 16, color: ClinicalColors.primaryTeal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aarogya Central Critical Command • National Digital Health Mission (ABDM) Compliant Node',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ClinicalColors.deepSlateNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Escalation SLA: < 5 Min',
                style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                    .copyWith(fontSize: 10),
              ),
              Text(
                'Clinical Triage Policy Manual',
                style: ClinicalTypography.labelSm(color: ClinicalColors.primaryTeal)
                    .copyWith(fontSize: 10, decoration: TextDecoration.underline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
