import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/doctor_appointment_model.dart';
import '../services/doctor_appointment_service.dart';
import '../core/api/api_exception.dart';

class PatientsDirectoryScreen extends StatefulWidget {
  final DoctorAppointmentService? appointmentService;

  const PatientsDirectoryScreen({super.key, this.appointmentService});

  @override
  State<PatientsDirectoryScreen> createState() => _PatientsDirectoryScreenState();
}

class _PatientsDirectoryScreenState extends State<PatientsDirectoryScreen> {
  late final DoctorAppointmentService _appointmentService;
  List<DoctorAppointmentModel> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _appointmentService = widget.appointmentService ?? DoctorAppointmentService();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _appointmentService.getAppointments();
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
          _errorMessage = 'Unable to load patient directory. Please retry.';
          _isLoading = false;
        });
      }
    }
  }

  // Extract unique authorized patients from appointments
  List<PatientInfoModel> get _uniquePatients {
    final Map<String, PatientInfoModel> map = {};
    for (final apt in _appointments) {
      if (apt.patient != null && apt.patient!.id.isNotEmpty) {
        map[apt.patient!.id] = apt.patient!;
      } else if (apt.patientProfileId.isNotEmpty) {
        map.putIfAbsent(
          apt.patientProfileId,
          () => PatientInfoModel(
            id: apt.patientProfileId,
            fullName: apt.patient?.fullName ?? 'Patient (${apt.patientProfileId.substring(0, 8)})',
            phoneNumber: apt.patient?.phoneNumber,
            bloodGroup: apt.patient?.bloodGroup,
            allergies: apt.patient?.allergies,
          ),
        );
      }
    }

    var list = map.values.toList();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        final name = p.fullName.toLowerCase();
        final phone = p.phoneNumber?.toLowerCase() ?? '';
        final blood = p.bloodGroup?.toLowerCase() ?? '';
        return name.contains(query) || phone.contains(query) || blood.contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final patients = _uniquePatients;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Patient Directory (${_isLoading ? '...' : patients.length})',
          style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadPatients,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search by patient name, phone, or blood group...',
                  prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textPlaceholder),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoading && patients.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Loading authorized patient records...', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ] else if (_errorMessage != null && patients.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.criticalRed),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _loadPatients,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ] else if (patients.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE6F4F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_search_outlined,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No Patients Registered Yet',
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Patients who book consultations with you will be securely recorded in your clinical directory with contact information and clinical history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: patients.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _buildPatientCard(context, patient);
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, PatientInfoModel patient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: AppColors.cardElevation,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFCEEAE2),
            child: Text(
              patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (patient.gender != null)
                      Text(
                        '${patient.gender} • ',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    if (patient.bloodGroup != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          patient.bloodGroup!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    if (patient.phoneNumber != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        patient.phoneNumber!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
                if (patient.allergies != null && patient.allergies!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Allergies: ${patient.allergies}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
