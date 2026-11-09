import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/alert.dart';
import '../data/sample_clinical_data.dart';
import '../widgets/status_badge.dart';
import 'modals/rapid_dispatch_dialog.dart';
import 'patient_telemetry_screen.dart';

class EmergencyAlertTriageScreen extends StatefulWidget {
  final bool showAppBarBackButton;

  const EmergencyAlertTriageScreen({super.key, this.showAppBarBackButton = false});

  @override
  State<EmergencyAlertTriageScreen> createState() => _EmergencyAlertTriageScreenState();
}

class _EmergencyAlertTriageScreenState extends State<EmergencyAlertTriageScreen> {
  String selectedStatusFilter = 'New';
  String selectedSeverityFilter = 'Critical Red';
  bool isSunitaProtocolExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: widget.showAppBarBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.criticalRedWash,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.criticalRed),
            ),
            const SizedBox(width: 8),
            Text(
              'Emergency Alert Triage',
              style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing triage audit incident log with On-Duty ICU Staff')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusFilterRow(),
            const SizedBox(height: 12),
            _buildTriageEngineCard(),
            const SizedBox(height: 12),
            _buildSeverityPillsRow(),
            const SizedBox(height: 10),
            _buildTelemetryNodeBar(),
            const SizedBox(height: 14),
            _buildSunitaCriticalCard(context),
            const SizedBox(height: 16),
            _buildRahulAmberCard(context),
            const SizedBox(height: 16),
            _buildVikramResolvedCard(context),
            const SizedBox(height: 16),
            _buildComplianceFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterRow() {
    return Row(
      children: [
        Text('STATUS:', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip('New (1)', 'New'),
                const SizedBox(width: 6),
                _buildStatusChip('Acknowledged', 'Acknowledged'),
                const SizedBox(width: 6),
                _buildStatusChip('In Progress', 'In Progress'),
                const SizedBox(width: 6),
                _buildStatusChip('Resolved', 'Resolved'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String key) {
    final isSelected = selectedStatusFilter == key;
    return InkWell(
      onTap: () => setState(() => selectedStatusFilter = key),
      borderRadius: BorderRadius.circular(AppRadii.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderHairline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTriageEngineCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.criticalRedWash,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.flare, color: AppColors.criticalRed, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Clinical Triage Engine',
                      style: AppTypography.headlineSm.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Configured Hospital Escalation Protocol Active',
                        style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Notice: Emergency actions require confirmed backend dispatch acknowledgement. Do not mark resolved without clinical action.',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.criticalRed,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: StatusBadge(
              label: 'Level 1 Triage',
              variant: BadgeVariant.critical,
              showDot: true,
              height: 20,
              horizontalPadding: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityPillsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSeverityButton(
            '• Critical Red (2)',
            'Critical Red',
            AppColors.criticalRedWash,
            AppColors.criticalRed,
            AppColors.criticalRedBorder,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSeverityButton(
            '• High Warning Amber (3)',
            'Amber',
            AppColors.warningAmberWash,
            AppColors.warningAmber,
            AppColors.warningAmberBorder,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSeverityButton(
            '• Resolved (51)',
            'Resolved',
            AppColors.stableGreenWash,
            AppColors.stableGreen,
            AppColors.stableGreenBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityButton(
      String label, String key, Color bg, Color textColor, Color border) {
    final isSelected = selectedSeverityFilter == key;
    return InkWell(
      onTap: () => setState(() => selectedSeverityFilter = key),
      borderRadius: BorderRadius.circular(AppRadii.full),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? textColor : bg,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryNodeBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.dns_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'Telemetry Node: Apollo central emr Cluster',
              style: AppTypography.bodySm.copyWith(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'SLA: < 15 min | 99.98%',
            style: AppTypography.clinicalCode.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildSunitaCriticalCard(BuildContext context) {
    final alert = SampleClinicalData.triageAlerts.first;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.criticalRedBorder, width: 1.5),
        boxShadow: AppColors.floatingElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red Header Band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFFFF1F2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.criticalRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'NEW ALERT',
                        style: AppTypography.labelSm.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    Text(
                      alert.triggerTime,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.criticalRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert.trustIndexNote ?? '',
                    style: AppTypography.bodySm.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${alert.patientName} (${alert.patientGender}, ${alert.patientAge})',
                      style: AppTypography.headlineSm.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.roomOrLocation,
                        style: AppTypography.labelSm.copyWith(color: const Color(0xFF3730A3), fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('ABHA: ${alert.abhaId}', style: AppTypography.clinicalCode.copyWith(fontSize: 11)),
                const SizedBox(height: 4),
                Text('Primary Dx: ${alert.primaryDiagnosis}', style: AppTypography.bodySm.copyWith(fontSize: 11.5)),
                Text('• Attending: ${alert.attending}', style: AppTypography.bodySm.copyWith(fontSize: 11)),
                const SizedBox(height: 10),
                // Priority dispatch tier banner
                Row(
                  children: [
                    Text('PRIORITY DISPATCH: ', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
                    Text(
                      alert.priorityDispatchTier,
                      style: AppTypography.labelSm.copyWith(color: AppColors.criticalRed, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.criticalRedWash,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, size: 14, color: AppColors.criticalRed),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Vitals Row (Heart Rate & SpO2)
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('HEART RATE', style: AppTypography.labelSm.copyWith(fontSize: 9.5)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.criticalRedWash,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    alert.heartRateBadge ?? '',
                                    style: const TextStyle(fontSize: 9, color: AppColors.criticalRed, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '124',
                              style: AppTypography.metricDisplay.copyWith(color: AppColors.criticalRed, fontSize: 24),
                            ),
                            Text(
                              'BPM (Tachycardia)\n${alert.heartRateBaseline}',
                              style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SPO2 OXYGEN', style: AppTypography.labelSm.copyWith(fontSize: 9.5)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.criticalRed,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    alert.spo2Badge ?? 'Critical Dip',
                                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '89%',
                              style: AppTypography.metricDisplay.copyWith(color: AppColors.criticalRed, fontSize: 24),
                            ),
                            Text(
                              'Ambient Air\n${alert.spo2Limit}',
                              style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted, height: 1.2),
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
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EVENT DETECTION: ${alert.headline}',
                        style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.details,
                        style: AppTypography.bodySm.copyWith(fontSize: 10.5, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Backend Protocol Activated box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCEEAE2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.protocolDetails ?? '',
                          style: AppTypography.bodySm.copyWith(color: AppColors.primary, fontSize: 10.5),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Text(
                          alert.dispatchId ?? '',
                          style: AppTypography.clinicalCode.copyWith(fontSize: 9, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      setState(() {
                        alert.status = AlertStatus.acknowledged;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Alert acknowledged by Dr. Aarav Mehta. Escalation SLA timer paused.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Acknowledge Alert'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => RapidDispatchDialog(alert: alert),
                      );
                    },
                    icon: const Icon(Icons.emergency, size: 16),
                    label: const Text('Dispatch Rapid Response'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dialling patient emergency caregiver (+91 98450 XXXXX)...')),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Patient / Caregiver (+91 98450 XXXXX)'),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() => isSunitaProtocolExpanded = !isSunitaProtocolExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 15, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Document clinical action & resolution protocol',
                              style: AppTypography.labelSm.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                        Icon(
                          isSunitaProtocolExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSunitaProtocolExpanded) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: Text(
                      'Resolution Protocol: Administer supplemental O2 at 4 L/min via nasal cannula. Verify Lead II rhythm for ventricular ectopy. Rapid Response Team alert logged to Apollo HealthCity Critical Incident Command.',
                      style: AppTypography.bodySm.copyWith(fontSize: 10.5, height: 1.35),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRahulAmberCard(BuildContext context) {
    final alert = SampleClinicalData.triageAlerts[1];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.warningAmberBorder, width: 1.5),
        boxShadow: AppColors.cardElevation,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amber Header Band
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.warningAmberWash,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ACKNOWLEDGED - IN PROGRESS',
                        style: AppTypography.labelSm.copyWith(color: Colors.white, fontSize: 9.5),
                      ),
                    ),
                    Text(
                      alert.triggerTime,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.warningAmber,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 13, color: AppColors.warningAmber),
                    const SizedBox(width: 4),
                    Text(
                      'GPS coordinates received: ${alert.gpsLocation}',
                      style: AppTypography.bodySm.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${alert.patientName} (${alert.patientGender}, ${alert.patientAge})',
                      style: AppTypography.headlineSm.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmberWash,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Patient Triggered SOS Alert',
                        style: AppTypography.labelSm.copyWith(color: AppColors.warningAmber, fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'ABHA: ${alert.abhaId} • ${alert.roomOrLocation}',
                  style: AppTypography.clinicalCode.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Emergency Contact Notified: ${alert.emergencyContact}',
                    style: AppTypography.bodySm.copyWith(fontSize: 10.5),
                  ),
                ),
                const SizedBox(height: 10),
                // Latest vitals telemetry 3 columns
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LATEST VITALS TELEMETRY', style: AppTypography.labelSm.copyWith(fontSize: 9.5)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Heart Rate', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                              Text(alert.heartRateReadout ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.criticalRed)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('SpO2', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                              Text(alert.spo2Readout ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.stableGreen)),
                            ],
                          ),
                          Column(
                            children: [
                              const Text('Blood Pressure', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                              Text(alert.bloodPressure ?? '135/85',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkSlate)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Active Clinical Routing box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.mintBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCEEAE2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ACTIVE CLINICAL ROUTING', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(
                        alert.ambulanceInfo ?? '',
                        style: AppTypography.bodySm.copyWith(fontSize: 11, color: AppColors.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.gps_fixed, size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Live GPS Telemetry Connected',
                            style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
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
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PatientTelemetryScreen(
                                patient: SampleClinicalData.patients.first,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.alt_route, size: 15),
                        label: const Text('View Dispatch Telemetry', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Handover note pushed to Ambulance #KA-02-HA-1102 tablet.')),
                          );
                        },
                        icon: const Icon(Icons.note_add_outlined, size: 15),
                        label: const Text('Add Clinical Handover Note', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PatientTelemetryScreen(
                            patient: SampleClinicalData.patients.first,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.show_chart, size: 13, color: AppColors.primary),
                    label: Text(
                      'Telemetry Past 24h Trend',
                      style: AppTypography.labelSm.copyWith(color: AppColors.primary),
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

  Widget _buildVikramResolvedCard(BuildContext context) {
    final alert = SampleClinicalData.triageAlerts[2];

    return Container(
      padding: const EdgeInsets.all(14),
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
              StatusBadge(
                label: 'RESOLVED',
                variant: BadgeVariant.stable,
                icon: Icons.check,
                height: 22,
              ),
              Text('ABHA: ${alert.abhaId}', style: AppTypography.clinicalCode.copyWith(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${alert.patientName} (${alert.patientGender}, ${alert.patientAge})',
            style: AppTypography.headlineSm.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            'Event: ${alert.headline}',
            style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600, fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.stableGreen),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Resolution: ${alert.resolutionSummary}',
                  style: AppTypography.bodySm.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(alert.closedTimeAgo ?? '', style: AppTypography.bodySm.copyWith(fontSize: 10)),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Displaying ABDM FHIR audit log for Alert ID ALT-38410.')),
                  );
                },
                icon: const Icon(Icons.history, size: 14),
                label: const Text('Audit Log', style: TextStyle(fontSize: 11)),
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
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Aarogya Central Critical Command • National Digital Health Mission (ABDM) Compliant Node',
                  style: AppTypography.bodySm.copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Escalation SLA: < 15 Min',
                style: AppTypography.clinicalCode.copyWith(fontSize: 10, color: AppColors.primary),
              ),
              InkWell(
                onTap: () {},
                child: Text(
                  'Clinical Triage Policy Manual',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
