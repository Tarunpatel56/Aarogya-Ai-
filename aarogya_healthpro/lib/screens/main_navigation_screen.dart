import 'package:flutter/material.dart';
import '../theme/clinical_sanctuary_theme.dart';
import '../models/patient_model.dart';
import 'dashboard_screen.dart';
import 'triage_screen.dart';
import 'patient_rpm_detail_screen.dart';
import 'doctor_imaging_review_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  PatientModel? _selectedPatient;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      _selectedPatient = null;
    });
  }

  void _onOpenPatientDetail(PatientModel patient) {
    setState(() {
      _selectedPatient = patient;
    });
  }

  void _onBackFromPatientDetail() {
    setState(() {
      _selectedPatient = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activeBody;

    if (_selectedPatient != null) {
      activeBody = PatientRpmDetailScreen(
        patient: _selectedPatient,
        onBack: _onBackFromPatientDetail,
      );
    } else {
      switch (_currentIndex) {
        case 0:
          activeBody = DashboardScreen(
            onNavigateTab: (index) => _onTabSelected(index),
            onSelectPatient: _onOpenPatientDetail,
          );
          break;
        case 1:
          // Patients List Tab
          activeBody = _buildPatientsCohortScreen();
          break;
        case 2:
          // Alerts Triage Tab
          activeBody = TriageScreen(
            onBack: () => _onTabSelected(0),
            onSelectPatient: _onOpenPatientDetail,
          );
          break;
        case 3:
          // Records & FHIR Tab
          activeBody = _buildRecordsFhirScreen();
          break;
        case 4:
          // Profile Tab
          activeBody = _buildDoctorProfileScreen();
          break;
        default:
          activeBody = DashboardScreen(
            onNavigateTab: (index) => _onTabSelected(index),
            onSelectPatient: _onOpenPatientDetail,
          );
      }
    }

    return Scaffold(
      backgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      body: activeBody,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: ClinicalColors.surfaceElevated,
        border: const Border(
          top: BorderSide(color: ClinicalColors.hairlineBorder, width: 1),
        ),
        boxShadow: ClinicalElevations.level2,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Dashboard',
                icon: Icons.dashboard_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Patients',
                icon: Icons.people_outline_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'Alerts',
                icon: Icons.notifications_none_rounded,
                badgeCount: 2,
              ),
              _buildNavItem(
                index: 3,
                label: 'Records',
                icon: Icons.medical_information_outlined,
              ),
              _buildNavItem(
                index: 4,
                label: 'Profile',
                icon: Icons.account_circle_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    int? badgeCount,
  }) {
    final isSelected = (_selectedPatient == null && _currentIndex == index);
    final color = isSelected ? ClinicalColors.primaryDark : ClinicalColors.textMuted;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: const BoxDecoration(
                        color: ClinicalColors.crimsonRose,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: ClinicalTypography.labelSm(color: color).copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientsCohortScreen() {
    final patients = PatientModel.samplePatients;

    return Scaffold(
      backgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      appBar: AppBar(
        title: Text(
          'Assigned Patients Cohort (42)',
          style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
              .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(ClinicalSpacing.margin),
        itemCount: patients.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = patients[index];
          return InkWell(
            onTap: () => _onOpenPatientDetail(p),
            borderRadius: ClinicalRadii.roundedLg,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ClinicalColors.surfaceElevated,
                borderRadius: ClinicalRadii.roundedLg,
                border: Border.all(color: ClinicalColors.hairlineBorder),
                boxShadow: ClinicalElevations.level1,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: p.isCritical
                        ? ClinicalColors.criticalWash
                        : ClinicalColors.optimalWash,
                    child: Text(
                      p.initials,
                      style: TextStyle(
                        color: p.isCritical
                            ? ClinicalColors.crimsonRose
                            : ClinicalColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.name} (${p.gender}, ${p.age})',
                          style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                              .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          p.primaryDiagnosis,
                          style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                              .copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'HR: ${p.heartRate} BPM',
                              style: ClinicalTypography.labelSm(
                                color: p.heartRate > 100
                                    ? ClinicalColors.crimsonRose
                                    : ClinicalColors.optimalEmerald,
                              ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'SpO2: ${p.spo2}%',
                              style: ClinicalTypography.labelSm(
                                color: p.spo2 < 90
                                    ? ClinicalColors.crimsonRose
                                    : ClinicalColors.primaryTeal,
                              ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: ClinicalColors.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordsFhirScreen() {
    return Scaffold(
      backgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      appBar: AppBar(
        title: Text(
          'Clinical EHR & FHIR R4 Records',
          style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
              .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ClinicalSpacing.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ClinicalColors.optimalWash.withOpacity(0.5),
                borderRadius: ClinicalRadii.roundedLg,
                border: Border.all(color: ClinicalColors.optimalBorder),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cloud_done_rounded, color: ClinicalColors.primaryTeal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ayushman Bharat Digital Mission (ABDM) Node Synced: 24 Encounters Logged Today',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClinicalColors.deepSlateNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DoctorImagingReviewScreen(),
                  ),
                );
              },
              borderRadius: ClinicalRadii.roundedLg,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: ClinicalRadii.roundedLg,
                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                  boxShadow: ClinicalElevations.level1,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.image_search_rounded, color: Color(0xFF7C3AED), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Diagnostic Imaging Review Queue',
                                style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                                    .copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: ClinicalColors.warningAmber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '2 PENDING',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Review Brain MRI, Chest X-Ray & Dermoscopy AI pre-classifications and sign off.',
                            style: TextStyle(fontSize: 11, color: ClinicalColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: ClinicalColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recent FHIR Diagnostic Observations',
              style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                  .copyWith(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFhirRecordCard(
              title: 'Rahul Sharma • 12 Nov 2024 (Tele-Encounter)',
              code: 'LOINC 8480-6 (Systolic Blood Pressure)',
              status: 'Validated by Dr. Aarav Mehta',
            ),
            const SizedBox(height: 10),
            _buildFhirRecordCard(
              title: 'Sunita Devi • 27 Oct 2026 (Emergency Dispatch)',
              code: 'LOINC 59408-5 (Oxygen Saturation BLE stream)',
              status: 'Tier 1 Critical Escalation Logged',
            ),
            const SizedBox(height: 10),
            _buildFhirRecordCard(
              title: 'Vikram Patel • 27 Oct 2026 (Medication Tele-Call)',
              code: 'RxNorm 1191 (Aspirin / Clopidogrel Log)',
              status: 'Reconciliation Completed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFhirRecordCard({
    required String title,
    required String code,
    required String status,
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
        children: [
          Text(
            title,
            style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                .copyWith(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            code,
            style: ClinicalTypography.bodySm(color: ClinicalColors.primaryTeal)
                .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            status,
            style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                .copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorProfileScreen() {
    return Scaffold(
      backgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      appBar: AppBar(
        title: Text(
          'Physician Profile & Duty Roster',
          style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
              .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ClinicalSpacing.margin),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ClinicalColors.surfaceElevated,
                borderRadius: ClinicalRadii.roundedLg,
                border: Border.all(color: ClinicalColors.hairlineBorder),
                boxShadow: ClinicalElevations.level1,
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150&auto=format&fit=crop&q=80',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dr. Aarav Mehta, MD (Cardiology)',
                    style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                        .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'NMC Reg: 2018-09-54891 • Senior Interventional Cardiologist',
                    style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted)
                        .copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ClinicalColors.optimalWash,
                      borderRadius: ClinicalRadii.roundedFull,
                    ),
                    child: Text(
                      '● Active On Duty • Apollo HealthCity Bengaluru',
                      style: ClinicalTypography.labelSm(color: ClinicalColors.optimalEmerald)
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
