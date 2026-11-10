import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/doctor_appointment_model.dart';
import '../services/doctor_appointment_service.dart';
import '../services/doctor_auth_service.dart';
import '../services/doctor_ai_service.dart';
import '../models/doctor_ai_model.dart';
import '../widgets/copilot_banner.dart';
import '../widgets/dashboard/doctor_header.dart';
import '../widgets/dashboard/doctor_metrics_grid.dart';
import '../widgets/dashboard/doctor_appointments_queue.dart';
import 'notifications/doctor_notifications_screen.dart';
import 'doctor_imaging_review_screen.dart';
import 'prescriptions/prescription_authoring_screen.dart';
import 'hospital/hospital_beds_screen.dart';
import 'admin/superadmin_console_screen.dart';
import '../services/doctor_notification_service.dart';
import '../services/doctor_socket_service.dart';
import '../core/api/api_exception.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;
  final DoctorAppointmentService? appointmentService;
  final DoctorAuthService? authService;

  const DoctorDashboardScreen({
    super.key,
    this.onNavigateTab,
    this.appointmentService,
    this.authService,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late final DoctorAppointmentService _appointmentService;
  late final DoctorAuthService _authService;
  final DoctorAiService _aiService = DoctorAiService();

  List<DoctorAppointmentModel> _appointments = [];
  bool _isLoadingAppointments = true;
  String? _appointmentsError;

  ClinicalCoPilotInsight? _coPilotInsight;
  bool _isLoadingCoPilot = false;

  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _activeTraumaAlert;
  final DoctorSocketService _socketService = DoctorSocketService();

  @override
  void initState() {
    super.initState();
    _appointmentService = widget.appointmentService ?? DoctorAppointmentService();
    _authService = widget.authService ?? DoctorAuthService();
    _loadAppointments();
    _loadCoPilotInsight();
    _initSocket();
  }

  void _initSocket() {
    _socketService.connect();
    _socketService.onEmergencyBroadcast = (data) {
      if (mounted) {
        setState(() {
          _activeTraumaAlert = data;
        });
      }
    };
    _socketService.onAppointmentUpdated = (_) {
      if (mounted) {
        _loadAppointments();
      }
    };
  }

  void _handlePrescribe(DoctorAppointmentModel apt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrescriptionAuthoringScreen(
          patientProfileId: apt.patientProfileId,
          patientName: apt.patient?.fullName ?? 'Patient',
          appointmentId: apt.id,
          existingAllergies: apt.patient?.allergies,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });

    try {
      final list = await _appointmentService.getAppointments();
      if (mounted) {
        setState(() {
          _appointments = list;
          _isLoadingAppointments = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _appointmentsError = e.message;
          _isLoadingAppointments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appointmentsError = 'Unable to connect to clinical appointments service. Please retry.';
          _isLoadingAppointments = false;
        });
      }
    }
  }

  Future<void> _loadCoPilotInsight() async {
    setState(() {
      _isLoadingCoPilot = true;
    });

    try {
      final profile = _authService.currentProfile;
      final docName = profile?.fullName ?? 'Doctor';
      final specialization = profile?.specialization ?? 'General Medicine';

      final res = await _aiService.fetchCoPilotSummary(
        patientName: 'Active OPD Roster ($docName)',
        age: 45,
        gender: 'Mixed',
        telemetry: {'opdQueueCount': _appointments.length, 'specialty': specialization},
        currentDiagnosis: '$specialization Consultation Review',
        medications: ['Clinical Evidence-based Guidelines'],
        recentObservations: 'Awaiting patient check-ins and intake consultations.',
      );

      if (mounted) {
        setState(() {
          _coPilotInsight = res;
          _isLoadingCoPilot = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCoPilot = false;
        });
      }
    }
  }

  List<DoctorAppointmentModel> get _filteredAppointments {
    var list = _appointments;

    if (_selectedStatusFilter != 'ALL') {
      list = list.where((a) => a.status == _selectedStatusFilter).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((a) {
        final patientName = a.patient?.fullName.toLowerCase() ?? '';
        final reason = a.reason?.toLowerCase() ?? '';
        final id = a.id.toLowerCase();
        return patientName.contains(query) || reason.contains(query) || id.contains(query);
      }).toList();
    }

    return list;
  }

  Future<void> _handleConfirm(DoctorAppointmentModel apt) async {
    final patientName = apt.patient?.fullName ?? 'the patient';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Appointment'),
        content: Text('Confirm consultation for $patientName at ${apt.startTime.toLocal().toString().substring(0, 16)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _appointmentService.confirmAppointment(apt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Consultation confirmed successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm: $e'), backgroundColor: AppColors.criticalRed),
        );
      }
    }
  }

  Future<void> _handleReject(DoctorAppointmentModel apt) async {
    final reasonController = TextEditingController();
    final patientName = apt.patient?.fullName ?? 'the patient';

    final rejected = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Appointment Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide a reason for declining $patientName\'s appointment:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Doctor unavailable / Emergency surgery',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (rejected != true) return;

    try {
      await _appointmentService.rejectAppointment(apt.id, reason: reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment request declined.'),
            backgroundColor: AppColors.secondary,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline: $e'), backgroundColor: AppColors.criticalRed),
        );
      }
    }
  }

  Future<void> _handleComplete(DoctorAppointmentModel apt) async {
    final patientName = apt.patient?.fullName ?? 'the patient';
    final completed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Consultation'),
        content: Text('Mark consultation with $patientName as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.stableGreen),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (completed != true) return;

    try {
      await _appointmentService.completeAppointment(apt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Consultation marked as completed!'),
            backgroundColor: AppColors.stableGreen,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete: $e'), backgroundColor: AppColors.criticalRed),
        );
      }
    }
  }

  Future<void> _handleNoShow(DoctorAppointmentModel apt) async {
    final patientName = apt.patient?.fullName ?? 'the patient';
    final markNoShow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Patient as No-Show'),
        content: Text('Record that $patientName did not attend the scheduled consultation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.outline),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Record No-Show', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (markNoShow != true) return;

    try {
      await _appointmentService.markNoShow(apt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment recorded as No-Show.'),
            backgroundColor: AppColors.secondary,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record no-show: $e'), backgroundColor: AppColors.criticalRed),
        );
      }
    }
  }

  void _showCoPilotModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aarogya Clinical Co-Pilot',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _coPilotInsight?.riskAssessment == 'CRITICAL'
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Risk: ${_coPilotInsight?.riskAssessment ?? "STABLE"}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _coPilotInsight?.riskAssessment == 'CRITICAL'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0369A1),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Provider: ${_coPilotInsight?.provider.toUpperCase() ?? "GROQ LPU / GEMINI"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _coPilotInsight?.clinicalSummary ??
                  'Clinical Co-Pilot analyzes your appointments queue to suggest evidence-based workflows.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.onSurface),
            ),
            const SizedBox(height: 14),
            const Text(
              'Recommended Clinical Actions:',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            ...(_coPilotInsight?.suggestedInterventions ??
                    ['Review patient intake allergies before prescription', 'Verify EHR vitals before final discharge'])
                .map((interv) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.mintAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(interv, style: const TextStyle(fontSize: 12, color: AppColors.onSurface)),
                          ),
                        ],
                      ),
                    )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadCoPilotInsight();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Co-Pilot Assessment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _authService.currentProfile;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([
              _loadAppointments(),
              _loadCoPilotInsight(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile != null && !profile.isVerified) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded, color: Color(0xFFD97706), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Verification Pending Super Admin Approval',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Aapka doctor account Super Admin ke verification queue mein hai. Super Admin ke approve karte hi aap Patient App par visible ho jayenge.',
                                style: TextStyle(color: Color(0xFFB45309), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_activeTraumaAlert != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRAUMA ALERT: ${_activeTraumaAlert!['patientName'] ?? 'Emergency Patient'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_activeTraumaAlert!['emergencyType'] ?? 'EMERGENCY'} • ${_activeTraumaAlert!['pickupAddress'] ?? 'Nearby'}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Color(0xFF991B1B)),
                          onPressed: () => setState(() => _activeTraumaAlert = null),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_authService.currentUser?.role == 'PLATFORM_ADMIN') ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0x334338CA), blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SuperAdminConsoleScreen()),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SUPERADMIN ECOSYSTEM CONSOLE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Manage all accounts, verify doctors, delete/suspend users',
                                      style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                DoctorHeader(
                  profile: profile,
                  onNotificationTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DoctorNotificationsScreen(
                          notificationService: DoctorNotificationService(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Real Metrics Grid
                DoctorMetricsGrid(
                  appointments: _appointments,
                  isLoading: _isLoadingAppointments,
                  onPendingTap: () => setState(() => _selectedStatusFilter = 'REQUESTED'),
                  onConfirmedTap: () => setState(() => _selectedStatusFilter = 'CONFIRMED'),
                  onAllTap: () => setState(() => _selectedStatusFilter = 'ALL'),
                ),
                const SizedBox(height: 14),

                // Clinical Co-Pilot Banner
                ClinicalCoPilotBanner(
                  title: _coPilotInsight != null
                      ? 'Aarogya Clinical Co-Pilot (${_coPilotInsight!.provider.toUpperCase()}):'
                      : 'Aarogya Clinical Co-Pilot:',
                  text: _coPilotInsight?.clinicalSummary ??
                      (_isLoadingCoPilot
                          ? 'Synthesizing verified appointment roster with Aarogya AI...'
                          : 'Clinical Co-Pilot is active. Tap to view AI triage assessment and consultation recommendations.'),
                  onTap: () => _showCoPilotModal(context),
                ),
                const SizedBox(height: 12),

                // Diagnostic Imaging Queue Quick Action
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DoctorImagingReviewScreen(
                          authService: _authService,
                          aiService: _aiService,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.image_search_rounded, color: Color(0xFF7C3AED), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Diagnostic Imaging Review Queue (MRI • X-Ray • Skin)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B21B6),
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF7C3AED)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Hospital Beds & Ward Management Quick Action
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HospitalBedsScreen(
                          hospitalId: '821448ec-841f-4d37-bb65-7c5658f62f89',
                          hospitalName: profile?.hospitalAffiliation ?? 'AIIMS New Delhi',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.single_bed_rounded, color: Color(0xFF059669), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hospital Wards & ICU Beds Allocation (Real-Time Census)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF059669)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search & Filter Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consultation Queue',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_filteredAppointments.length} record${_filteredAppointments.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search by patient name, reason, or appointment ID...',
                    prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textPlaceholder),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All (${_appointments.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'REQUESTED',
                        'Requested (${_appointments.where((a) => a.isRequested).length})',
                        activeColor: AppColors.warningAmber,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'CONFIRMED',
                        'Confirmed (${_appointments.where((a) => a.isConfirmed).length})',
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'COMPLETED',
                        'Completed (${_appointments.where((a) => a.isCompleted).length})',
                        activeColor: AppColors.stableGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Real Appointments Queue
                DoctorAppointmentsQueue(
                  appointments: _filteredAppointments,
                  isLoading: _isLoadingAppointments,
                  errorMessage: _appointmentsError,
                  onRetry: _loadAppointments,
                  onConfirm: _handleConfirm,
                  onReject: _handleReject,
                  onComplete: _handleComplete,
                  onNoShow: _handleNoShow,
                  onPrescribe: _handlePrescribe,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, {Color? activeColor}) {
    final isSelected = _selectedStatusFilter == value;
    final color = activeColor ?? AppColors.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.borderHairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
