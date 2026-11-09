import 'package:flutter/material.dart';
import '../theme/clinical_sanctuary_theme.dart';
import '../models/patient_model.dart';
import '../models/doctor_profile_model.dart';
import '../services/doctor_profile_service.dart';
import 'doctor_imaging_review_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  final Function(PatientModel patient)? onSelectPatient;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
    this.onSelectPatient,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late final DoctorProfileService _profileService;
  DoctorProfileModel? _doctorProfile;
  bool _isDutyActive = true;
  bool _isUpdatingDuty = false;

  @override
  void initState() {
    super.initState();
    _profileService = DoctorProfileService();
    _loadDutyStatus();
  }

  Future<void> _loadDutyStatus() async {
    try {
      final prof = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _doctorProfile = prof;
          _isDutyActive = prof.isOnline;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleDuty() async {
    if (_isUpdatingDuty) return;
    final nextStatus = !_isDutyActive;
    setState(() {
      _isUpdatingDuty = true;
      _isDutyActive = nextStatus;
    });

    try {
      await _profileService.setDutyStatus(nextStatus);
      if (mounted) {
        setState(() => _isUpdatingDuty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextStatus
                  ? '✓ You are now ON DUTY. Today & tomorrow consultation slots published!'
                  : '✓ You are now OFF DUTY. Appointments paused.',
            ),
            backgroundColor: nextStatus ? const Color(0xFF15803D) : const Color(0xFF475569),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingDuty = false;
          _isDutyActive = !nextStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update duty status: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = PatientModel.samplePatients;

    return Scaffold(
      backgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: ClinicalSpacing.margin,
            vertical: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopAppHeader(),
              const SizedBox(height: 12),
              _buildHospitalDutyBar(),
              const SizedBox(height: 16),
              _buildHighPriorityAlertCard(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildClinicalCoPilotBanner(),
              const SizedBox(height: 20),
              _buildActiveTelemetryHeader(),
              const SizedBox(height: 12),
              _buildPatientCard(patients[0]), // Rahul Sharma
              const SizedBox(height: 16),
              _buildPatientCard(patients[1]), // Sunita Devi
              const SizedBox(height: 24),
              _buildClinicalShortcuts(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppHeader() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ClinicalColors.optimalWash,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ClinicalColors.optimalBorder),
          ),
          child: const Center(
            child: Icon(
              Icons.add_box_rounded,
              color: ClinicalColors.primaryTeal,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Aarogya HealthPro',
          style: ClinicalTypography.headlineMd(color: ClinicalColors.deepMarineTeal)
              .copyWith(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, color: ClinicalColors.deepSlateNavy, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 14),
        Stack(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: ClinicalColors.surfaceContainerHigh,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150&auto=format&fit=crop&q=80',
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ClinicalColors.optimalEmerald,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHospitalDutyBar() {
    final docName = _doctorProfile?.fullName ?? 'Physician Station';
    final affiliation = _doctorProfile?.hospitalAffiliation ?? _doctorProfile?.clinicAddress ?? 'Aarogya Clinical Network';
    final spec = _doctorProfile?.specialization ?? 'General Healthcare';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedMd,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (_isDutyActive ? ClinicalColors.optimalEmerald : ClinicalColors.textMuted).withOpacity(0.12),
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Icon(
              Icons.apartment_rounded,
              color: _isDutyActive ? ClinicalColors.optimalEmerald : ClinicalColors.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$affiliation • $spec',
                  style: ClinicalTypography.labelSm(color: ClinicalColors.deepSlateNavy)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  docName,
                  style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                      .copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _toggleDuty,
            borderRadius: ClinicalRadii.roundedFull,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _isDutyActive ? ClinicalColors.optimalWash : const Color(0xFFF1F5F9),
                borderRadius: ClinicalRadii.roundedFull,
                border: Border.all(
                  color: _isDutyActive ? ClinicalColors.optimalBorder : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUpdatingDuty)
                    const SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isDutyActive ? ClinicalColors.optimalEmerald : const Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 5),
                  Text(
                    _isDutyActive ? 'Duty Active' : 'Off Duty',
                    style: ClinicalTypography.labelSm(
                      color: _isDutyActive ? ClinicalColors.optimalEmerald : const Color(0xFF475569),
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighPriorityAlertCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClinicalColors.criticalWash,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.criticalBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ClinicalColors.crimsonRose,
                  borderRadius: ClinicalRadii.roundedMd,
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HIGH-PRIORITY ALERT',
                          style: ClinicalTypography.labelSm(
                            color: ClinicalColors.crimsonRose,
                          ).copyWith(letterSpacing: 0.5),
                        ),
                        Text(
                          'Ward A • Telemetry',
                          style: ClinicalTypography.labelSm(
                            color: ClinicalColors.crimsonRose,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '2 Critical Alerts Pending Immediate Action',
                      style: ClinicalTypography.headlineSm(
                        color: ClinicalColors.darkRedCta,
                      ).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  widget.onNavigateTab?.call(2); // Navigate to Alerts Triage
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClinicalColors.darkRedCta,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: ClinicalRadii.rounded,
                  ),
                ),
                icon: const Text(
                  'Triage Alerts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                label: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ECG Desat (Bed 4) + VTach',
                  style: ClinicalTypography.labelSm(
                    color: ClinicalColors.darkRedCta,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _buildStatCard(
          title: 'ASSIGNED PATIENTS',
          icon: Icons.personal_injury_outlined,
          iconColor: ClinicalColors.primaryTeal,
          value: '42',
          unit: 'Total',
          subtext: '• 12 Critical Watch',
          subtextColor: ClinicalColors.crimsonRose,
        ),
        _buildStatCard(
          title: 'ACTIVE RPM TELEMETRY',
          icon: Icons.monitor_heart_outlined,
          iconColor: ClinicalColors.primaryTeal,
          value: '18',
          unit: 'Live Cuffs',
          subtext: '⇌ boAt Wave / Omron Synced',
          subtextColor: ClinicalColors.primaryTeal,
        ),
        _buildStatCard(
          title: 'UNACKNOWLEDGED ALERTS',
          icon: Icons.notifications_active_outlined,
          iconColor: ClinicalColors.crimsonRose,
          value: '2',
          valueColor: ClinicalColors.crimsonRose,
          unit: 'Urgent',
          subtext: '• 5 Warning Flags',
          subtextColor: ClinicalColors.textMuted,
        ),
        _buildStatCard(
          title: 'PENDING CONSULTS',
          icon: Icons.calendar_today_outlined,
          iconColor: ClinicalColors.primaryTeal,
          value: '6',
          unit: 'Scheduled',
          subtext: '✓ 1 Review OPD Next',
          subtextColor: ClinicalColors.optimalEmerald,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    Color? valueColor,
    required String unit,
    required String subtext,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: ClinicalTypography.labelSm(
                    color: ClinicalColors.textMuted,
                  ).copyWith(fontSize: 10, letterSpacing: 0.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: ClinicalTypography.metricDisplay(
                  color: valueColor ?? ClinicalColors.deepSlateNavy,
                ).copyWith(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              Text(
                unit,
                style: ClinicalTypography.bodySm(
                  color: ClinicalColors.textMuted,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
          Text(
            subtext,
            style: ClinicalTypography.labelSm(color: subtextColor)
                .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        borderRadius: ClinicalRadii.roundedMd,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: TextField(
        controller: _searchController,
        style: ClinicalTypography.bodyMd(color: ClinicalColors.deepSlateNavy),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          hintText: 'Search ABHA ID, Patient name, or Bed #...',
          hintStyle: ClinicalTypography.bodyMd(color: ClinicalColors.textSubtle),
          prefixIcon: const Icon(
            Icons.search,
            color: ClinicalColors.textMuted,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: ClinicalColors.textMuted,
              size: 19,
            ),
            onPressed: () {},
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All (42)', 'badge': false},
      {'label': '• Critical Alerts (2)', 'badge': true, 'color': ClinicalColors.crimsonRose},
      {'label': 'Telemetry Active (18)', 'badge': false},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          final f = filters[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              borderRadius: ClinicalRadii.roundedFull,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ClinicalColors.deepSlateNavy
                      : ClinicalColors.surfaceElevated,
                  borderRadius: ClinicalRadii.roundedFull,
                  border: Border.all(
                    color: isSelected
                        ? ClinicalColors.deepSlateNavy
                        : (f['badge'] == true
                            ? ClinicalColors.criticalBorder
                            : ClinicalColors.hairlineBorder),
                  ),
                  boxShadow: isSelected ? ClinicalElevations.level1 : null,
                ),
                child: Text(
                  f['label'] as String,
                  style: ClinicalTypography.labelSm(
                    color: isSelected
                        ? Colors.white
                        : (f['badge'] == true
                            ? ClinicalColors.crimsonRose
                            : ClinicalColors.textMuted),
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildClinicalCoPilotBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ClinicalColors.optimalWash.withOpacity(0.6),
            ClinicalColors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: ClinicalRadii.roundedLg,
        border: const Border(
          left: BorderSide(color: ClinicalColors.primaryTeal, width: 3.5),
          top: BorderSide(color: ClinicalColors.hairlineBorder),
          right: BorderSide(color: ClinicalColors.hairlineBorder),
          bottom: BorderSide(color: ClinicalColors.hairlineBorder),
        ),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: ClinicalColors.primaryTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                    .copyWith(height: 1.4),
                children: const [
                  TextSpan(
                    text: 'Aarogya Clinical Co-Pilot: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'Morning vitals indicate 3 patients in Post-MI cohort show accelerated diastolic stabilization following beta-blocker adjustments.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTelemetryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Active Patient Telemetry',
          style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
              .copyWith(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            const Icon(
              Icons.sync_rounded,
              color: ClinicalColors.primaryTeal,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Live Stream',
              style: ClinicalTypography.labelSm(color: ClinicalColors.primaryTeal)
                  .copyWith(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
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
          // Header info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: patient.id == 'patient-rahul'
                    ? ClinicalColors.optimalWash
                    : ClinicalColors.secondaryContainer.withOpacity(0.5),
                child: Text(
                  patient.initials,
                  style: TextStyle(
                    color: patient.id == 'patient-rahul'
                        ? ClinicalColors.primaryTeal
                        : ClinicalColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${patient.name} (${patient.gender}, ${patient.age})',
                            style: ClinicalTypography.headlineSm(
                              color: ClinicalColors.deepSlateNavy,
                            ).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: patient.wardOrLocation.contains('Ward')
                                ? ClinicalColors.optimalWash
                                : ClinicalColors.secondaryContainer.withOpacity(0.5),
                            borderRadius: ClinicalRadii.roundedSm,
                          ),
                          child: Text(
                            patient.wardOrLocation,
                            style: ClinicalTypography.labelSm(
                              color: patient.wardOrLocation.contains('Ward')
                                  ? ClinicalColors.primaryTeal
                                  : ClinicalColors.secondary,
                            ).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ABHA: ${patient.abhaId}',
                      style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                          .copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      patient.primaryDiagnosis,
                      style: ClinicalTypography.bodySm(color: ClinicalColors.onSurfaceVariant)
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Vitals dual boxes
          Row(
            children: [
              if (patient.id == 'patient-rahul') ...[
                Expanded(
                  child: _buildTelemetryBox(
                    label: 'HEART RATE',
                    icon: Icons.favorite_rounded,
                    iconColor: ClinicalColors.crimsonRose,
                    value: '${patient.heartRate}',
                    unit: 'BPM',
                    statusText: patient.heartRateContext,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTelemetryBox(
                    label: 'SPO2 OXYGEN',
                    icon: Icons.air_rounded,
                    iconColor: ClinicalColors.primaryTeal,
                    value: '${patient.spo2}%',
                    unit: 'Optimal',
                    unitColor: ClinicalColors.optimalEmerald,
                    statusText: 'Stable trendline (Continuous)',
                  ),
                ),
              ] else ...[
                Expanded(
                  child: _buildTelemetryBox(
                    label: 'BLOOD GLUCOSE',
                    icon: Icons.water_drop_rounded,
                    iconColor: ClinicalColors.crimsonRose,
                    value: '${patient.bloodGlucose}',
                    valueColor: ClinicalColors.crimsonRose,
                    unit: 'mg/dL',
                    statusText: 'Queued manual log (34m ago)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTelemetryBox(
                    label: 'PULSE RATE',
                    icon: Icons.favorite_border_rounded,
                    iconColor: ClinicalColors.primaryTeal,
                    value: '${patient.heartRate}',
                    unit: 'BPM',
                    statusText: 'Resting steady state',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Status bar / sub-note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: ClinicalColors.surfaceInset,
              borderRadius: ClinicalRadii.roundedSm,
            ),
            child: Row(
              children: [
                Icon(
                  patient.id == 'patient-rahul'
                      ? Icons.check_circle_rounded
                      : Icons.sensors_rounded,
                  size: 15,
                  color: patient.id == 'patient-rahul'
                      ? ClinicalColors.optimalEmerald
                      : ClinicalColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    patient.statusNote,
                    style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                        .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (patient.id != 'patient-rahul')
                  InkWell(
                    onTap: () {},
                    child: Text(
                      'Ping Patient',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.primaryTeal)
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onSelectPatient?.call(patient);
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
                  icon: const Icon(Icons.show_chart_rounded, size: 16),
                  label: const Text(
                    'View Telemetry',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ClinicalColors.deepSlateNavy,
                    side: const BorderSide(color: ClinicalColors.hairlineBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: ClinicalRadii.rounded,
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text(
                    'Clinical Notes',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBox({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
    Color? valueColor,
    required String unit,
    Color? unitColor,
    required String statusText,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceInset,
        borderRadius: ClinicalRadii.roundedSm,
        border: Border.all(color: ClinicalColors.hairlineBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                    .copyWith(fontSize: 9, letterSpacing: 0.3),
              ),
              Icon(icon, size: 14, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: ClinicalTypography.headlineMd(
                  color: valueColor ?? ClinicalColors.deepSlateNavy,
                ).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: ClinicalTypography.labelSm(
                  color: unitColor ?? ClinicalColors.textMuted,
                ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            statusText,
            style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalShortcuts() {
    final shortcuts = [
      {'title': 'Record\nNote', 'icon': Icons.edit_note_rounded, 'color': ClinicalColors.primaryTeal},
      {'title': 'E-\nPrescribe', 'icon': Icons.medication_rounded, 'color': ClinicalColors.primaryTeal},
      {'title': 'Triage\nList', 'icon': Icons.emergency_rounded, 'color': ClinicalColors.crimsonRose},
      {'title': 'Imaging\nReview', 'icon': Icons.image_search_rounded, 'color': const Color(0xFF7C3AED)},
      {'title': 'Tele-OPD', 'icon': Icons.videocam_rounded, 'color': ClinicalColors.secondary},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLINICAL SHORTCUTS',
          style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
              .copyWith(letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(shortcuts.length, (index) {
              final s = shortcuts[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    if (index == 2) {
                      widget.onNavigateTab?.call(2); // Go to Triage List
                    } else if (index == 3) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DoctorImagingReviewScreen(),
                        ),
                      );
                    }
                  },
                  borderRadius: ClinicalRadii.roundedLg,
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: ClinicalColors.surfaceElevated,
                      borderRadius: ClinicalRadii.roundedLg,
                      border: Border.all(color: ClinicalColors.hairlineBorder),
                      boxShadow: ClinicalElevations.level1,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (s['color'] as Color).withOpacity(0.1),
                            borderRadius: ClinicalRadii.roundedSm,
                          ),
                          child: Icon(
                            s['icon'] as IconData,
                            size: 22,
                            color: s['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s['title'] as String,
                          textAlign: TextAlign.center,
                          style: ClinicalTypography.labelSm(
                            color: ClinicalColors.deepSlateNavy,
                          ).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
