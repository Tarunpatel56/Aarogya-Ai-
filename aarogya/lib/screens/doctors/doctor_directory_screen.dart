import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import '../../services/appointment_service.dart';
import '../../core/api/api_exception.dart';

class DoctorDirectoryScreen extends StatefulWidget {
  final DoctorService? doctorService;
  final AppointmentService? appointmentService;
  final String? initialSpecialty;

  const DoctorDirectoryScreen({
    super.key,
    this.doctorService,
    this.appointmentService,
    this.initialSpecialty,
  });

  @override
  State<DoctorDirectoryScreen> createState() => _DoctorDirectoryScreenState();
}

class _DoctorDirectoryScreenState extends State<DoctorDirectoryScreen> {
  late final DoctorService _doctorService;
  late final AppointmentService _appointmentService;

  final _searchController = TextEditingController();
  String? _selectedSpecialization;
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _specializations = [
    'All',
    'Cardiology',
    'General Medicine',
    'Pediatrics',
    'Dermatology',
    'Neurology',
  ];

  @override
  void initState() {
    super.initState();
    _doctorService = widget.doctorService ?? DoctorService();
    _appointmentService = widget.appointmentService ?? AppointmentService();
    if (widget.initialSpecialty != null && widget.initialSpecialty!.isNotEmpty) {
      _selectedSpecialization = widget.initialSpecialty;
      if (!_specializations.contains(widget.initialSpecialty)) {
        _specializations.add(widget.initialSpecialty!);
      }
    }
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final spec = (_selectedSpecialization == null || _selectedSpecialization == 'All')
          ? null
          : _selectedSpecialization;
      final query = _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null;

      final doctors = await _doctorService.getDoctors(
        specialization: spec,
        search: query,
      );

      if (mounted) {
        setState(() {
          _doctors = doctors;
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
          _errorMessage = 'Failed to load doctors. Please check network connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _showBookingModal(DoctorModel doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DoctorBookingSheet(
        doctor: doctor,
        doctorService: _doctorService,
        appointmentService: _appointmentService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Verified Doctors Directory'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by doctor name or condition...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadDoctors();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _loadDoctors(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _specializations.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final spec = _specializations[i];
                        final isSelected = (_selectedSpecialization == null && spec == 'All') ||
                            _selectedSpecialization == spec;
                        return ChoiceChip(
                          label: Text(spec),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSpecialization = selected ? spec : null;
                            });
                            _loadDoctors();
                          },
                          selectedColor: AppColors.primaryTeal,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryTeal : const Color(0xFFCBD5E1),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadDoctors,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _doctors.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.person_search_outlined, size: 48, color: Color(0xFF94A3B8)),
                                    SizedBox(height: 12),
                                    Text(
                                      'No verified doctors found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Try adjusting your search criteria or specialization filter.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadDoctors,
                              color: AppColors.primaryTeal,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _doctors.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final doctor = _doctors[index];
                                  return _buildDoctorCard(doctor);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(DoctorModel doctor) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.mintBg,
                child: Text(
                  doctor.fullName.isNotEmpty
                      ? doctor.fullName
                          .split(' ')
                          .where((s) => s.isNotEmpty)
                          .take(2)
                          .map((s) => s[0])
                          .join()
                      : 'DR',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doctor.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: doctor.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: doctor.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                doctor.isOnline ? 'On Duty' : 'Off Duty',
                                style: TextStyle(
                                  color: doctor.isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doctor.specialization} • ${doctor.qualifications}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doctor.experienceYears} years experience',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consultation Fee', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    '₹${doctor.consultationFee.toInt()}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showBookingModal(doctor),
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Book Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoctorBookingSheet extends StatefulWidget {
  final DoctorModel doctor;
  final DoctorService doctorService;
  final AppointmentService appointmentService;

  const _DoctorBookingSheet({
    required this.doctor,
    required this.doctorService,
    required this.appointmentService,
  });

  @override
  State<_DoctorBookingSheet> createState() => _DoctorBookingSheetState();
}

class _DoctorBookingSheetState extends State<_DoctorBookingSheet> {
  List<DoctorAvailabilityModel> _availabilities = [];
  bool _isLoadingSlots = true;
  String? _slotsError;

  DoctorAvailabilityModel? _selectedSlot;
  String _selectedMode = 'IN_PERSON';
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _bookingError;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    if (widget.doctor.consultationModes.isNotEmpty) {
      _selectedMode = widget.doctor.consultationModes.first;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    try {
      final slots = await widget.doctorService.getDoctorAvailability(widget.doctor.id);
      if (mounted) {
        setState(() {
          _availabilities = slots.where((s) => s.status == 'AVAILABLE').toList();
          if (_availabilities.isNotEmpty) {
            _selectedSlot = _availabilities.first;
          }
          _isLoadingSlots = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _slotsError = 'Unable to load schedule';
          _isLoadingSlots = false;
        });
      }
    }
  }

  String _formatSlotTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(local.year, local.month, local.day);
    final diffDays = targetDate.difference(today).inDays;

    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr = '$displayHour:$minute $period';

    if (diffDays == 0) {
      return 'Today, $timeStr';
    } else if (diffDays == 1) {
      return 'Tomorrow, $timeStr';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${local.day} ${months[local.month - 1]}, $timeStr';
    }
  }

  Future<void> _submitBooking() async {
    DateTime slotStart;
    DateTime slotEnd;

    if (_selectedSlot != null) {
      slotStart = _selectedSlot!.startTime;
      slotEnd = _selectedSlot!.endTime;
    } else if (widget.doctor.isOnline) {
      final now = DateTime.now();
      final nextMin = ((now.minute / 15).ceil() * 15) % 60;
      final addHour = (now.minute >= 45) ? 1 : 0;
      slotStart = DateTime(now.year, now.month, now.day, now.hour + addHour, nextMin).add(const Duration(minutes: 15));
      slotEnd = slotStart.add(const Duration(minutes: 30));
    } else {
      setState(() => _bookingError = 'Please select an available appointment slot');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _bookingError = null;
    });

    try {
      await widget.appointmentService.requestAppointment(
        doctorProfileId: widget.doctor.id,
        startTime: slotStart,
        endTime: slotEnd,
        mode: _selectedMode,
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment requested successfully! Awaiting doctor confirmation.'),
            backgroundColor: Color(0xFF00675B),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          if (e.isConflict) {
            _bookingError = 'This time slot is already reserved or conflicts with another booking. Please choose another slot.';
          } else {
            _bookingError = e.message;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _bookingError = 'Failed to submit appointment request. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Book Consultation with ${widget.doctor.fullName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              widget.doctor.specialization,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            if (_bookingError != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  _bookingError!,
                  style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Consultation Mode Selector
            const Text('Consultation Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.doctor.consultationModes.map((mode) {
                final isSelected = _selectedMode == mode;
                return ChoiceChip(
                  label: Text(mode == 'ONLINE' ? 'Video / Online' : 'In-Person Clinic'),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedMode = mode);
                  },
                  selectedColor: AppColors.primaryTeal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Available Slots
            const Text('Available Time Slots', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_isLoadingSlots)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_slotsError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  _slotsError!,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
                ),
              )
            else if (_availabilities.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.doctor.isOnline ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.doctor.isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.doctor.isOnline ? Icons.verified_user : Icons.schedule,
                      size: 20,
                      color: widget.doctor.isOnline ? const Color(0xFF16A34A) : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.doctor.isOnline
                            ? 'Doctor is On Duty now! Tap Confirm Request below for an immediate consultation slot.'
                            : 'No available slots currently published for this doctor. Please check back later.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: widget.doctor.isOnline ? FontWeight.w600 : FontWeight.normal,
                          color: widget.doctor.isOnline ? const Color(0xFF15803D) : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availabilities.map((slot) {
                  final isSelected = _selectedSlot?.id == slot.id;
                  final startTimeStr = _formatSlotTime(slot.startTime);
                  return ChoiceChip(
                    label: Text(startTimeStr),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedSlot = slot);
                    },
                    selectedColor: AppColors.primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),

            // Reason field
            const Text('Reason for Consultation (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Briefly describe your symptoms...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSubmitting || (_availabilities.isEmpty && !widget.doctor.isOnline))
                    ? null
                    : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _selectedSlot != null
                            ? 'Confirm Request (${_formatSlotTime(_selectedSlot!.startTime)})'
                            : (widget.doctor.isOnline ? 'Request On-Duty Consultation' : 'Confirm Request'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
