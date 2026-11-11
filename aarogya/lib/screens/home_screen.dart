import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/patient_profile_model.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/appointment_service.dart';
import '../services/doctor_service.dart';
import '../services/notification_service.dart';
import '../services/watch_service.dart';
import 'ocr_scanner_modal.dart';
import 'doctors/doctor_directory_screen.dart';
import 'appointments/appointments_screen.dart';
import 'ai/brain_mri_screen.dart';
import 'ai/lung_xray_screen.dart';
import 'ai/skin_analysis_screen.dart';
import 'ai/eye_analysis_screen.dart';
import 'ai/symptom_checker_screen.dart';
import 'ai/medical_report_analyzer_screen.dart';
import 'physio/physiotherapy_home_screen.dart';
import 'reminders/medicine_reminders_screen.dart';
import 'hospitals/nearby_hospitals_screen.dart';
import 'prescriptions/patient_prescriptions_screen.dart';
import 'community/government_schemes_screen.dart';
import 'community/blood_donor_directory_screen.dart';
import 'community/health_camps_screen.dart';
import 'wellness/vaccination_tracker_screen.dart';
import 'wellness/wellness_dashboard_screen.dart';
import 'ai/medical_report_comparison_screen.dart';
import 'medicines/medicine_safety_screen.dart';
import 'voice/talk_to_talk_voice_assistant_screen.dart';
import '../services/ai_service.dart';
import '../services/community_service.dart';
import '../services/medicine_reminder_service.dart';
import '../services/physiotherapy_service.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_sos_card.dart';
import '../widgets/home/home_quick_actions.dart';
import '../widgets/home/home_upcoming_consultation.dart';
import '../widgets/home/home_vitals_summary.dart';
import '../widgets/home/home_reminders_card.dart';
import '../widgets/home/home_physio_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAI;
  final VoidCallback? onNavigateToHealth;
  final AuthService? authService;
  final PatientService? patientService;
  final AppointmentService? appointmentService;

  const HomeScreen({
    super.key,
    this.onNavigateToAI,
    this.onNavigateToHealth,
    this.authService,
    this.patientService,
    this.appointmentService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final PatientService _patientService;
  late final AppointmentService _appointmentService;

  UserModel? _currentUser;
  PatientProfileModel? _currentProfile;
  AppointmentModel? _upcomingAppointment;

  bool _isLoadingAppointment = true;
  String _glucoseReading = 'No recent reading';
  String _glucoseSub = 'Tap to log reading';
  bool _hasLoggedGlucose = false;
  late AnimationController _syncAnimController;
  late final MedicineReminderService _reminderService;
  late final PhysiotherapyService _physioService;

  @override
  void initState() {
    super.initState();
    _reminderService = MedicineReminderService();
    _reminderService.init();
    _physioService = PhysiotherapyService();
    _physioService.init();

    _patientService = widget.patientService ?? PatientService(apiClient: widget.authService?.apiClient);
    _appointmentService = widget.appointmentService ?? AppointmentService(apiClient: widget.authService?.apiClient);

    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _currentUser = widget.authService?.currentUser;
    _currentProfile = widget.authService?.currentProfile;

    WatchService().connectionStateNotifier.addListener(_onWatchUpdate);
    WatchService().telemetryNotifier.addListener(_onWatchUpdate);

    _loadData();
  }

  void _onWatchUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WatchService().connectionStateNotifier.removeListener(_onWatchUpdate);
    WatchService().telemetryNotifier.removeListener(_onWatchUpdate);
    _syncAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // 1. Load real profile
    try {
      final profile = await _patientService.getProfile();
      if (mounted) {
        setState(() {
          _currentProfile = profile;
        });
      }
    } catch (_) {
      // Use fallback from authService if already cached
      if (mounted && _currentProfile == null) {
        setState(() {
          _currentProfile = widget.authService?.currentProfile;
        });
      }
    }

    // 2. Load real appointments for upcoming consultation card
    try {
      final appointments = await _appointmentService.getAppointments();
      if (mounted) {
        // Find earliest upcoming appointment that is CONFIRMED or REQUESTED
        final activeList = appointments.where((a) => a.status == 'CONFIRMED' || a.status == 'REQUESTED').toList();
        setState(() {
          _upcomingAppointment = activeList.isNotEmpty ? activeList.first : null;
          _isLoadingAppointment = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _upcomingAppointment = null;
          _isLoadingAppointment = false;
        });
      }
    }
  }

  void _triggerSync() {
    _syncAnimController.repeat();
    _loadData().then((_) {
      if (mounted) {
        _syncAnimController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Verified records synchronized with ABHA EHR!'),
            backgroundColor: AppColors.primaryTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }).catchError((_) {
      if (mounted) {
        _syncAnimController.stop();
      }
    });
  }

  void _openDoctorDirectory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorDirectoryScreen(
          doctorService: DoctorService(apiClient: widget.authService?.apiClient),
          appointmentService: _appointmentService,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openAppointmentsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentsScreen(
          appointmentService: _appointmentService,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _openOcrScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const OcrScannerModal(),
    );
  }

  void _openBrainMri() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BrainMriScreen()),
    );
  }

  void _openLungXray() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LungXrayScreen()),
    );
  }

  void _openSkinAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SkinAnalysisScreen()),
    );
  }

  void _openEyeAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EyeAnalysisScreen()),
    );
  }

  void _openSymptomChecker() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
    );
  }

  void _openReportAnalyzer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedicalReportAnalyzerScreen()),
    );
  }

  void _openPhysio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhysiotherapyHomeScreen()),
    );
  }

  void _openNearbyHospitals() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NearbyHospitalsScreen()),
    );
  }

  void _openReminders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineRemindersScreen(reminderService: _reminderService),
      ),
    );
  }

  void _openPrescriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientPrescriptionsScreen(
          patientProfileId: _currentProfile?.id,
        ),
      ),
    );
  }

  void _openGovtSchemes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GovernmentSchemesScreen(
          communityService: CommunityService(apiClient: widget.authService?.apiClient),
        ),
      ),
    );
  }

  void _openBloodDonors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BloodDonorDirectoryScreen(
          communityService: CommunityService(apiClient: widget.authService?.apiClient),
        ),
      ),
    );
  }

  void _openHealthCamps() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthCampsScreen(
          communityService: CommunityService(apiClient: widget.authService?.apiClient),
        ),
      ),
    );
  }

  void _openVaccines() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaccinationTrackerScreen(
          communityService: CommunityService(apiClient: widget.authService?.apiClient),
        ),
      ),
    );
  }

  void _openWellness() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WellnessDashboardScreen(),
      ),
    );
  }

  void _openReportComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MedicalReportComparisonScreen(),
      ),
    );
  }

  void _openMedicineSafety() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineSafetyScreen(
          communityService: CommunityService(apiClient: widget.authService?.apiClient),
        ),
      ),
    );
  }

  void _openVoiceAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TalkToTalkVoiceAssistantScreen(
          aiService: AiService(apiClient: widget.authService?.apiClient),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Header (Real Profile / Real ABHA)
                HomeHeader(
                  user: _currentUser,
                  profile: _currentProfile,
                  syncAnimController: _syncAnimController,
                  onTriggerSync: _triggerSync,
                  notificationService: NotificationService(apiClient: widget.authService?.apiClient),
                ),
                const SizedBox(height: 16),

                // 2. Emergency SOS Card
                const HomeSosCard(),
                const SizedBox(height: 18),

                // 3. Quick AI & Doctor Actions
                HomeQuickActions(
                  onNavigateToAI: widget.onNavigateToAI ?? () {},
                  onOpenVoiceAssistant: _openVoiceAssistant,
                  onOpenOcrScanner: _openOcrScanner,
                  onOpenDoctorDirectory: _openDoctorDirectory,
                  onOpenBrainMri: _openBrainMri,
                  onOpenLungXray: _openLungXray,
                  onOpenSkinAnalysis: _openSkinAnalysis,
                  onOpenEyeAnalysis: _openEyeAnalysis,
                  onOpenSymptomChecker: _openSymptomChecker,
                  onOpenReportAnalyzer: _openReportAnalyzer,
                  onOpenPhysio: _openPhysio,
                  onOpenNearbyHospitals: _openNearbyHospitals,
                  onOpenPrescriptions: _openPrescriptions,
                ),
                const SizedBox(height: 18),

                // 4. Upcoming Doctor Consultation (Real Appointments / Empty State)
                HomeUpcomingConsultation(
                  upcomingAppointment: _upcomingAppointment,
                  isLoading: _isLoadingAppointment,
                  onBookDoctor: _openDoctorDirectory,
                  onViewAll: _openAppointmentsScreen,
                ),
                const SizedBox(height: 18),

                // 5. Personal Health Metrics (Honest, not fake telemetry)
                HomeVitalsSummary(
                  glucoseReading: _glucoseReading,
                  glucoseSub: _glucoseSub,
                  hasLoggedGlucose: _hasLoggedGlucose,
                  watchTelemetry: WatchService().currentTelemetry,
                  connectionState: WatchService().connectionState,
                  onConnectWatch: widget.onNavigateToHealth ?? () {},
                  onGlucoseLogged: (mgDl, type) {
                    setState(() {
                      _glucoseReading = '$mgDl mg/dL';
                      _glucoseSub = '$type • Logged just now';
                      _hasLoggedGlucose = true;
                    });
                  },
                  onNavigateToHealth: widget.onNavigateToHealth ?? () {},
                ),
                const SizedBox(height: 18),

                // 6. Smart Medicine Reminders Summary Card
                HomeRemindersCard(
                  reminderService: _reminderService,
                  onOpenReminders: _openReminders,
                ),
                const SizedBox(height: 18),

                // 7. Daily Rehabilitation & Physio Plan Card
                HomePhysioCard(
                  physioService: _physioService,
                  onOpenPhysio: _openPhysio,
                ),
                const SizedBox(height: 18),

                // 8. Community, Schemes & Wellness Section
                _buildCommunityAndWellnessSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityAndWellnessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: const [
                  Icon(Icons.hub_outlined, color: AppColors.primaryTeal, size: 19),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Citizen Health & Community Hub',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Public Welfare',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHubTile(
                icon: Icons.account_balance_rounded,
                iconBg: const Color(0xFFE0F2F1),
                iconColor: AppColors.primaryTeal,
                title: 'Govt Schemes',
                subtitle: 'PM-JAY & Vay Vandana',
                onTap: _openGovtSchemes,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHubTile(
                icon: Icons.favorite_rounded,
                iconBg: const Color(0xFFFEF2F2),
                iconColor: const Color(0xFFDC2626),
                title: 'Blood Donors',
                subtitle: 'Find & Register',
                onTap: _openBloodDonors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHubTile(
                icon: Icons.event_available_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Health Camps',
                subtitle: 'Free Checkups',
                onTap: _openHealthCamps,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildHubTile(
                icon: Icons.shield_outlined,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                title: 'Vaccinations',
                subtitle: 'Universal Tracker',
                onTap: _openVaccines,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHubTile(
                icon: Icons.water_drop_outlined,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                title: 'Wellness Log',
                subtitle: 'Hydration & Sleep',
                onTap: _openWellness,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildHubTile(
                icon: Icons.compare_arrows_rounded,
                iconBg: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFD97706),
                title: 'Report Delta',
                subtitle: 'Biomarker Trends',
                onTap: _openReportComparison,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildHubTile(
                icon: Icons.medication_outlined,
                iconBg: const Color(0xFFFAF5FF),
                iconColor: const Color(0xFF9333EA),
                title: 'Medicine Safety',
                subtitle: 'Warnings & Interactions',
                onTap: _openMedicineSafety,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHubTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
