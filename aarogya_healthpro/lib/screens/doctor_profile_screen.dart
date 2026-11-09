import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/doctor_profile_model.dart';
import '../services/doctor_auth_service.dart';
import '../services/doctor_profile_service.dart';
import '../services/doctor_appointment_service.dart';
import '../services/doctor_notification_service.dart';
import 'appointments/doctor_appointments_screen.dart';
import 'notifications/doctor_notifications_screen.dart';
import 'admin/superadmin_console_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final DoctorAuthService? authService;
  final DoctorProfileService? profileService;
  final DoctorAppointmentService? appointmentService;
  final DoctorNotificationService? notificationService;

  const DoctorProfileScreen({
    super.key,
    this.authService,
    this.profileService,
    this.appointmentService,
    this.notificationService,
  });

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  late final DoctorProfileService _profileService;
  DoctorProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  bool isDutyActive = true;
  bool enableTachycardiaAlerts = true;
  bool enableSmsEscalation = true;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? DoctorProfileService(apiClient: widget.authService?.apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prof = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profile = prof;
          isDutyActive = prof.isOnline;
          _isLoading = false;
        });
        widget.authService?.updateProfileLocally(prof);
      }
    } catch (_) {
      if (mounted) {
        // Fall back to locally stored profile if available
        setState(() {
          _profile = widget.authService?.currentProfile;
          _isLoading = false;
          if (_profile == null) {
            _errorMessage = 'Unable to load physician profile. Please retry.';
          }
        });
      }
    }
  }

  void _showEditProfileDialog() {
    if (_profile == null) return;

    final nameController = TextEditingController(text: _profile!.fullName);
    final specController = TextEditingController(text: _profile!.specialization);
    final qualController = TextEditingController(text: _profile!.qualifications);
    final expController = TextEditingController(text: _profile!.experienceYears.toString());
    final feeController = TextEditingController(text: _profile!.consultationFee.toStringAsFixed(0));
    final bioController = TextEditingController(text: _profile!.bio ?? '');
    final hospitalController = TextEditingController(text: _profile!.hospitalAffiliation ?? '');
    final addressController = TextEditingController(text: _profile!.clinicAddress ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Update Clinical Practice Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: nameController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Dr. John Doe')),
                  const SizedBox(height: 12),
                  const Text('Medical Specialization', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: specController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. Cardiology, Dermatology')),
                  const SizedBox(height: 12),
                  const Text('Qualifications & Degrees', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: qualController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. MBBS, MD, MS')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Experience (Years)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(controller: expController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fee (INR ₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            TextField(controller: feeController, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder())),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Hospital / Institution Affiliation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: hospitalController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. AIIMS, Max Hospital')),
                  const SizedBox(height: 12),
                  const Text('Clinic Physical Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: addressController, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Full clinic address')),
                  const SizedBox(height: 12),
                  const Text('Professional Bio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(controller: bioController, maxLines: 2, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Brief summary of clinical background')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      setModalState(() => isSaving = true);
                      try {
                        final updated = await _profileService.updateProfile(
                          fullName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
                          specialization: specController.text.trim().isNotEmpty ? specController.text.trim() : null,
                          qualifications: qualController.text.trim().isNotEmpty ? qualController.text.trim() : null,
                          experienceYears: int.tryParse(expController.text.trim()),
                          consultationFee: double.tryParse(feeController.text.trim()),
                          bio: bioController.text.trim(),
                          hospitalAffiliation: hospitalController.text.trim(),
                          clinicAddress: addressController.text.trim(),
                        );
                        if (mounted) {
                          setState(() => _profile = updated);
                          widget.authService?.updateProfileLocally(updated);
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Physician profile updated successfully!')),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Update failed: $e')),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFeeDialog() {
    if (_profile == null) return;
    final feeController = TextEditingController(
      text: _profile!.consultationFee > 0
          ? _profile!.consultationFee.toInt().toString()
          : '500',
    );
    bool isSaving = false;
    final presets = [200, 300, 500, 700, 1000, 1500];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final currentInputVal = double.tryParse(feeController.text.trim()) ?? 0;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_rupee, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Consultation Fee',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set your per-consultation fee in INR. This fee is presented transparently to patients during doctor discovery and appointment booking.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quick Presets:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((amount) {
                        final isSelected = currentInputVal == amount.toDouble();
                        return ChoiceChip(
                          label: Text(
                            '₹$amount',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                feeController.text = amount.toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Custom Fee (₹)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: feeController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                        hintText: 'Enter consultation fee (e.g. 500)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Updates instantly on Aarogya Patient App discovery & appointment cards.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final val = double.tryParse(feeController.text.trim());
                        if (val == null || val < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid consultation fee amount.')),
                          );
                          return;
                        }

                        setModalState(() => isSaving = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final nav = Navigator.of(ctx);

                        try {
                          final updated = await _profileService.updateProfile(consultationFee: val);
                          if (mounted) {
                            setState(() => _profile = updated);
                            widget.authService?.updateProfileLocally(updated);
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('✓ Consultation fee updated to ₹${val.toInt()} successfully!'),
                                backgroundColor: const Color(0xFF15803D),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSaving = false);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to update fee: $e')),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Fee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVerificationInfoModal() {
    final isVerified = _profile?.isVerified ?? false;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.admin_panel_settings,
                  color: isVerified ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isVerified ? 'Verified Medical Practitioner' : 'Verification Details',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              isVerified
                  ? 'Your doctor account is VERIFIED. You are currently visible to all patients across the Aarogya Ecosystem and can receive appointment requests and write prescriptions.'
                  : 'Healthcare compliance requires every medical license to be verified before a doctor profile appears publicly on the Aarogya Patient App.',
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.onSurface),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildVerificationRow(
                    'Authorized Verifier',
                    'Aarogya Platform Administrator / Medical Council',
                    Icons.shield_outlined,
                  ),
                  const Divider(height: 16),
                  _buildVerificationRow(
                    'Standard Review SLA',
                    '12 – 24 Business Hours',
                    Icons.schedule,
                  ),
                  const Divider(height: 16),
                  _buildVerificationRow(
                    'Medical License (NMC)',
                    _profile?.medicalLicenseNumber.isNotEmpty == true
                        ? _profile!.medicalLicenseNumber
                        : 'Registration Submitted',
                    Icons.badge_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Understood', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  void _showAvailabilityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _DoctorAvailabilityModal(profileService: _profileService),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your current clinical session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.authService != null) {
      await widget.authService!.logout();
    }
  }

  Future<void> _handleLogoutAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out All Sessions'),
        content: const Text('This will revoke all active access and refresh tokens across all doctor workstations and devices.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.criticalRed),
            child: const Text('Revoke All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.authService != null) {
      await widget.authService!.logoutAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Physician Profile & Credentials', style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'In-App Alerts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorNotificationsScreen(
                    notificationService: widget.notificationService ?? DoctorNotificationService(apiClient: widget.authService?.apiClient),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: _profile != null ? _showEditProfileDialog : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null && _profile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      // Doctor identity card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderHairline),
                          boxShadow: const [
                            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: const Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 40),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _profile?.fullName ?? widget.authService?.currentUser?.email ?? 'Doctor Profile',
                              style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _profile != null
                                  ? '${_profile!.specialization} • ${_profile!.qualifications}'
                                  : 'Verified Clinician',
                              style: AppTypography.bodySm,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Medical License: ${_profile?.medicalLicenseNumber ?? "NMC Pending"}',
                              style: AppTypography.clinicalCode.copyWith(fontSize: 11, color: AppColors.primary),
                            ),
                            const SizedBox(height: 10),

                            // Verification Status Banner
                            InkWell(
                              onTap: _showVerificationInfoModal,
                              borderRadius: BorderRadius.circular(20),
                              child: _profile != null && _profile!.isVerified
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFF86EFAC)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified, size: 16, color: Color(0xFF15803D)),
                                          SizedBox(width: 6),
                                          Text(
                                            'VERIFIED MEDICAL PRACTITIONER',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.info_outline, size: 13, color: Color(0xFF15803D)),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFFCD34D)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.pending_actions, size: 16, color: Color(0xFFB45309)),
                                          SizedBox(width: 6),
                                          Text(
                                            'PENDING VERIFICATION • TAP FOR INFO',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.chevron_right, size: 14, color: Color(0xFFB45309)),
                                        ],
                                      ),
                                    ),
                            ),

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 10),

                            // Consultation Fee Display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                InkWell(
                                  onTap: _showEditFeeDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text('Consultation Fee', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            SizedBox(width: 4),
                                            Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text('₹${_profile?.consultationFee.toStringAsFixed(0) ?? "0"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 28, color: AppColors.borderHairline),
                                Column(
                                  children: [
                                    const Text('Experience', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    const SizedBox(height: 2),
                                    Text('${_profile?.experienceYears ?? 0} Years', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Active Duty Toggle Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDutyActive ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDutyActive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDutyActive ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDutyActive ? Icons.online_prediction : Icons.bedtime,
                                color: isDutyActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDutyActive ? 'Duty Status: ACTIVE (Online)' : 'Duty Status: OFF DUTY (Offline)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDutyActive ? const Color(0xFF15803D) : const Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isDutyActive
                                        ? 'Patients can discover you & book live time slots'
                                        : 'Not taking appointments right now',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isDutyActive,
                              activeColor: const Color(0xFF16A34A),
                              onChanged: (val) async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => isDutyActive = val);
                                try {
                                  await _profileService.setDutyStatus(val);
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(val
                                            ? '✓ You are now ON DUTY. Consultation slots active.'
                                            : '✓ You are now OFF DUTY.'),
                                        backgroundColor: val ? const Color(0xFF15803D) : const Color(0xFF475569),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  if (mounted) setState(() => isDutyActive = !val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Availability Management Quick Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderHairline),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.schedule, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Consultation Availability', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 2),
                                  Text('Publish and manage appointment time slots', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _showAvailabilityDialog,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Manage Slots', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Consultation Fee Management Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderHairline),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_outlined, color: Color(0xFF15803D), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Consultation Fee', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          '₹${_profile?.consultationFee.toStringAsFixed(0) ?? "500"}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text('Standard OPD & Teleconsultation charges', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _showEditFeeDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Edit Fee', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderHairline),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_month, color: Color(0xFF4F46E5), size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Appointments Console', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 2),
                                  Text('Accept, reject, and complete bookings', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorAppointmentsScreen(
                                      appointmentService: widget.appointmentService ?? DoctorAppointmentService(apiClient: widget.authService?.apiClient),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
                              child: const Text('View All', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Institutional Affiliations & Practice Details
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderHairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('CLINICAL PRACTICE & CLINIC', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
                                InkWell(
                                  onTap: _showEditProfileDialog,
                                  child: const Text('Edit Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.local_hospital_outlined, size: 20, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    (_profile?.hospitalAffiliation != null && _profile!.hospitalAffiliation!.trim().isNotEmpty)
                                        ? _profile!.hospitalAffiliation!
                                        : 'Hospital affiliation not specified (tap Edit Details)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: (_profile?.hospitalAffiliation != null && _profile!.hospitalAffiliation!.trim().isNotEmpty)
                                          ? AppColors.onSurface
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 20, color: AppColors.textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    (_profile?.clinicAddress != null && _profile!.clinicAddress!.trim().isNotEmpty)
                                        ? _profile!.clinicAddress!
                                        : 'Clinic address not added yet (tap Edit Details)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (_profile?.clinicAddress != null && _profile!.clinicAddress!.trim().isNotEmpty)
                                          ? AppColors.onSurface
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_profile?.bio != null && _profile!.bio!.trim().isNotEmpty) ...[
                              const Divider(height: 20),
                              Text('ABOUT PHYSICIAN', style: AppTypography.labelSm.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 6),
                              Text(_profile!.bio!, style: const TextStyle(fontSize: 12, color: AppColors.onSurface, height: 1.35)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SuperAdmin Access Entry (Visible if user is PLATFORM_ADMIN)
                      if (widget.authService?.currentUser?.role == 'PLATFORM_ADMIN') ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SuperAdminConsoleScreen()),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.shield_rounded, color: Color(0xFFA5B4FC), size: 28),
                                    SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SuperAdmin Management Console',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Full ecosystem access • Verify, suspend, or delete users',
                                            style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Logout buttons
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.criticalRed,
                            side: const BorderSide(color: AppColors.criticalRedBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Sign Out Session'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _handleLogoutAll,
                        style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                        child: const Text('Sign out of all workstations and devices', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class _DoctorAvailabilityModal extends StatefulWidget {
  final DoctorProfileService profileService;

  const _DoctorAvailabilityModal({required this.profileService});

  @override
  State<_DoctorAvailabilityModal> createState() => _DoctorAvailabilityModalState();
}

class _DoctorAvailabilityModalState extends State<_DoctorAvailabilityModal> {
  List<DoctorAvailabilityModel> _slots = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final slots = await widget.profileService.getAvailability();
      if (mounted) {
        setState(() {
          _slots = slots;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load availability slots';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSlot(String slotId) async {
    try {
      await widget.profileService.deleteAvailability(slotId);
      _loadSlots();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete availability slot')),
        );
      }
    }
  }

  Future<void> _autoGenerateDutySlots() async {
    setState(() => _isLoading = true);
    try {
      await widget.profileService.setDutyStatus(true);
      await _loadSlots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Standard duty slots generated for today and tomorrow!'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate slots: $e')),
        );
      }
    }
  }

  Future<void> _addNewSlot() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 10, 0);
    final endTime = tomorrow.add(const Duration(hours: 4));

    try {
      await widget.profileService.createAvailability(
        dayOfWeek: tomorrow.weekday % 7,
        startTime: tomorrow,
        endTime: endTime,
      );
      _loadSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create slot: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Publish Availability Slots'),
      content: SizedBox(
        width: 360,
        height: 340,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _slots.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy, size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No availability slots published yet.\nAuto-generate standard duty slots or add a shift below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _autoGenerateDutySlots,
                            icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                            label: const Text('Auto-Generate Duty Slots', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                          ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: _slots.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = _slots[i];
                          final startStr = '${s.startTime.toLocal().day}/${s.startTime.toLocal().month} ${s.startTime.toLocal().hour.toString().padLeft(2, '0')}:${s.startTime.toLocal().minute.toString().padLeft(2, '0')}';
                          final endStr = '${s.endTime.toLocal().hour.toString().padLeft(2, '0')}:${s.endTime.toLocal().minute.toString().padLeft(2, '0')}';
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('$startStr - $endStr', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Status: ${s.status}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteSlot(s.id),
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton.icon(
          onPressed: _autoGenerateDutySlots,
          icon: const Icon(Icons.flash_on, size: 16),
          label: const Text('Auto-Fill'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
        ),
        ElevatedButton.icon(
          onPressed: _addNewSlot,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('+ Shift'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
