import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../core/api/api_exception.dart';
import 'consultation_room_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final AppointmentService appointmentService;

  const AppointmentsScreen({
    super.key,
    required this.appointmentService,
  });

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'ALL';

  final List<String> _statusFilters = ['ALL', 'REQUESTED', 'CONFIRMED', 'COMPLETED', 'CANCELLED'];

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
      final status = _selectedStatus == 'ALL' ? null : _selectedStatus;
      final list = await widget.appointmentService.getAppointments(status: status);

      if (mounted) {
        setState(() {
          _appointments = list;
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
          _errorMessage = 'Failed to load appointments';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to cancel your consultation with ${appointment.doctorName ?? "Doctor"}?',
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Reason for cancellation (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.appointmentService.cancelAppointment(
          appointment.id,
          reason: reasonController.text.isNotEmpty ? reasonController.text : null,
        );
        _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cancellation failed: $e')),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return const Color(0xFF10B981);
      case 'REQUESTED':
        return const Color(0xFFF59E0B);
      case 'COMPLETED':
        return const Color(0xFF3B82F6);
      case 'CANCELLED':
      case 'REJECTED':
        return const Color(0xFFEF4444);
      case 'NO_SHOW':
        return const Color(0xFF6B7280);
      default:
        return AppColors.primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Filter Tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusFilters.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final status = _statusFilters[i];
                    final isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedStatus = status);
                          _loadAppointments();
                        }
                      },
                      selectedColor: AppColors.primaryTeal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Appointments List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_errorMessage!),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadAppointments, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _appointments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.event_busy, size: 48, color: Color(0xFF94A3B8)),
                                  SizedBox(height: 12),
                                  Text(
                                    'No appointments found',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Book an appointment from the verified doctor directory.',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAppointments,
                              color: AppColors.primaryTeal,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _appointments.length,
                                separatorBuilder: (_, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final appt = _appointments[index];
                                  final statusColor = _getStatusColor(appt.status);
                                  final timeStr =
                                      '${appt.startTime.toLocal().day}/${appt.startTime.toLocal().month}/${appt.startTime.toLocal().year} at ${appt.startTime.toLocal().hour.toString().padLeft(2, '0')}:${appt.startTime.toLocal().minute.toString().padLeft(2, '0')}';

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.cardBorder),
                                      boxShadow: AppColors.cardShadow,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                appt.doctorName ?? 'Verified Physician',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                appt.status,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (appt.doctorSpecialization != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            appt.doctorSpecialization!,
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 15, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Text(timeStr, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                                            const SizedBox(width: 14),
                                            Icon(
                                              appt.mode == 'ONLINE' ? Icons.videocam_outlined : Icons.business_outlined,
                                              size: 15,
                                              color: const Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              appt.mode == 'ONLINE' ? 'Online' : 'In-Person',
                                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                            ),
                                          ],
                                        ),
                                        if (appt.reason != null && appt.reason!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Reason: ${appt.reason}',
                                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                        if (appt.doctorNotes != null && appt.doctorNotes!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Doctor Notes: ${appt.doctorNotes}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (appt.mode == 'ONLINE' || appt.status == 'CONFIRMED')
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ConsultationRoomScreen(appointment: appt),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.videocam, size: 16),
                                                label: const Text('Join Consultation Room', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.primaryTeal,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                            if (appt.canCancel) ...[
                                              const SizedBox(width: 8),
                                              TextButton.icon(
                                                onPressed: () => _cancelAppointment(appt),
                                                icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                                                label: const Text(
                                                  'Cancel',
                                                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
