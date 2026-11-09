import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/doctor_appointment_model.dart';
import '../../services/doctor_appointment_service.dart';
import '../../core/api/api_exception.dart';
import '../../widgets/patient_medical_file_dialog.dart';
import '../prescriptions/prescription_authoring_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final DoctorAppointmentService appointmentService;

  const DoctorAppointmentsScreen({
    super.key,
    required this.appointmentService,
  });

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  List<DoctorAppointmentModel> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatusFilter = 'ALL';

  final List<String> _filters = [
    'ALL',
    'REQUESTED',
    'CONFIRMED',
    'COMPLETED',
    'CANCELLED',
    'REJECTED',
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusParam = _selectedStatusFilter == 'ALL' ? null : _selectedStatusFilter;
      final results = await widget.appointmentService.getAppointments(status: statusParam);
      if (mounted) {
        setState(() {
          _appointments = results;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to connect to clinical appointments service. Please retry.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAppointment(DoctorAppointmentModel apt) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Appointment'),
        content: Text(
          'Confirm appointment for ${apt.patient?.fullName ?? "the patient"} at ${apt.startTime.toLocal().toString().substring(0, 16)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.appointmentService.confirmAppointment(apt.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Appointment confirmed successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadAppointments();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Confirmation failed: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Network error. Unable to confirm appointment.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectAppointment(DoctorAppointmentModel apt) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Appointment Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide a reason for rejecting ${apt.patient?.fullName ?? "the patient"}\'s request:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Doctor unavailable during this slot, emergency surgery scheduled',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await widget.appointmentService.rejectAppointment(apt.id, reason: reason);
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment request rejected.')),
      );
      _loadAppointments();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Rejection failed: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _completeAppointment(DoctorAppointmentModel apt) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Consultation Completed'),
        content: Text('Mark consultation with ${apt.patient?.fullName ?? "patient"} as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Mark Completed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.appointmentService.completeAppointment(apt.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Appointment marked as completed.'),
          backgroundColor: AppColors.primary,
        ),
      );
      _loadAppointments();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markNoShow(DoctorAppointmentModel apt) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Patient No-Show'),
        content: Text('Record that ${apt.patient?.fullName ?? "patient"} did not attend the scheduled consultation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            child: const Text('Mark No-Show', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.appointmentService.markNoShow(apt.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment marked as No-Show.')),
      );
      _loadAppointments();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelAppointment(DoctorAppointmentModel apt) async {
    final messenger = ScaffoldMessenger.of(context);
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for cancellation (required):'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Unforeseen schedule conflict',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await widget.appointmentService.cancelAppointment(apt.id, reason: reason);
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully.')),
      );
      _loadAppointments();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Cancellation failed: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Clinical Appointments Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh Appointments',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final isSelected = _selectedStatusFilter == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedStatusFilter = f);
                        _loadAppointments();
                      }
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadAppointments,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _appointments.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedStatusFilter == 'ALL'
                                        ? 'No clinical appointments found.'
                                        : 'No appointments in $_selectedStatusFilter status.',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'When patients book consultations, requests will appear here.',
                                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAppointments,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _appointments.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final apt = _appointments[i];
                                return _buildAppointmentCard(apt);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _prescribeAppointment(DoctorAppointmentModel apt) {
    Navigator.push(
      context,
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

  void _showPatientMedicalReportDialog(DoctorAppointmentModel apt) {
    PatientMedicalFileDialog.show(
      context,
      apt,
      onPrescribe: (apt) => _prescribeAppointment(apt),
    );
  }

  Widget _buildAppointmentCard(DoctorAppointmentModel apt) {
    Color statusColor;
    switch (apt.status) {
      case 'REQUESTED':
        statusColor = const Color(0xFFD97706); // Amber
        break;
      case 'CONFIRMED':
        statusColor = const Color(0xFF059669); // Emerald
        break;
      case 'COMPLETED':
        statusColor = const Color(0xFF2563EB); // Blue
        break;
      case 'CANCELLED':
      case 'REJECTED':
        statusColor = const Color(0xFFDC2626); // Red
        break;
      default:
        statusColor = const Color(0xFF6B7280);
    }

    final dateStr = '${apt.startTime.toLocal().day}/${apt.startTime.toLocal().month}/${apt.startTime.toLocal().year}';
    final timeStr = '${apt.startTime.toLocal().hour.toString().padLeft(2, '0')}:${apt.startTime.toLocal().minute.toString().padLeft(2, '0')} - ${apt.endTime.toLocal().hour.toString().padLeft(2, '0')}:${apt.endTime.toLocal().minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Patient & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt.patient?.fullName ?? 'Patient ID: ${apt.patientProfileId.substring(0, 8)}...',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if (apt.patient?.bloodGroup != null)
                            Text(
                              'Blood Group: ${apt.patient!.bloodGroup!}  •  Gender: ${apt.patient?.gender ?? "N/A"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  apt.status,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Date, Time, Mode & Fee (Wrapped to guarantee ZERO RenderFlex overflow)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(dateStr, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(timeStr, style: const TextStyle(fontSize: 12.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  apt.mode == 'ONLINE' ? 'Video Consult' : 'Clinic Visit',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'Fee: ₹${apt.consultationFee.toInt()}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),

          if (apt.reason != null && apt.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Reason: ${apt.reason!}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],

          if (apt.cancellationReason != null && apt.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Cancellation Reason: ${apt.cancellationReason!}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            ),
          ],

          const SizedBox(height: 12),

          // Full Medical Report & Vitals Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPatientMedicalReportDialog(apt),
              icon: const Icon(Icons.assignment_outlined, size: 16),
              label: const Text('View Patient Medical Report & Vitals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          // Actions (Using Wrap so multiple buttons never cause RenderFlex overflow)
          if (apt.canConfirm || apt.canReject || apt.canComplete || apt.canMarkNoShow || apt.canCancel) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (apt.canReject)
                  OutlinedButton(
                    onPressed: () => _rejectAppointment(apt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Reject'),
                  ),
                if (apt.canConfirm)
                  ElevatedButton(
                    onPressed: () => _confirmAppointment(apt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Confirm Request'),
                  ),
                if (apt.canComplete)
                  ElevatedButton(
                    onPressed: () => _completeAppointment(apt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Mark Completed'),
                  ),
                if (apt.canMarkNoShow)
                  OutlinedButton(
                    onPressed: () => _markNoShow(apt),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                      side: BorderSide(color: Colors.orange.shade800),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('No-Show'),
                  ),
                if (apt.canCancel && !apt.canReject)
                  TextButton(
                    onPressed: () => _cancelAppointment(apt),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
