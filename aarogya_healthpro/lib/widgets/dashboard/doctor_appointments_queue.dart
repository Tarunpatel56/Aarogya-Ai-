import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/doctor_appointment_model.dart';
import '../../widgets/status_badge.dart';

class DoctorAppointmentsQueue extends StatelessWidget {
  final List<DoctorAppointmentModel> appointments;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Function(DoctorAppointmentModel) onConfirm;
  final Function(DoctorAppointmentModel) onReject;
  final Function(DoctorAppointmentModel) onComplete;
  final Function(DoctorAppointmentModel) onNoShow;
  final Function(DoctorAppointmentModel)? onPrescribe;

  const DoctorAppointmentsQueue({
    super.key,
    required this.appointments,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onConfirm,
    required this.onReject,
    required this.onComplete,
    required this.onNoShow,
    this.onPrescribe,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        alignment: Alignment.center,
        child: const Column(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text(
              'Loading verified appointment queue...',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && appointments.isEmpty) {
      return Container(
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
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (appointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
                Icons.event_available_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Appointment Requests in Queue',
              style: AppTypography.headlineSm.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'When patients book consultations through Aarogya, their verified appointments will appear here with clinical symptoms and history.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: appointments.map((apt) => _buildAppointmentCard(context, apt)).toList(),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, DoctorAppointmentModel apt) {
    final patientName = apt.patient?.fullName ?? 'Patient (ID: ${apt.patientProfileId.substring(0, 8)})';
    final patientPhone = apt.patient?.phoneNumber;
    final patientAllergies = apt.patient?.allergies;
    final patientBlood = apt.patient?.bloodGroup;
    final startTimeFormatted = apt.startTime.toLocal().toString().substring(0, 16);
    final isOnline = apt.mode == 'ONLINE';

    BadgeVariant badgeVariant;

    if (apt.isRequested) {
      badgeVariant = BadgeVariant.warning;
    } else if (apt.isConfirmed) {
      badgeVariant = BadgeVariant.mint;
    } else if (apt.isCompleted) {
      badgeVariant = BadgeVariant.stable;
    } else {
      badgeVariant = BadgeVariant.critical;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header Row: Patient Name & Status Badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFCEEAE2),
                child: Text(
                  patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (patientBlood != null && patientBlood.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              patientBlood,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (patientPhone != null)
                          Text(
                            patientPhone,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: apt.status,
                variant: badgeVariant,
                height: 22,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Consultation Timing & Mode & Fee Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    startTimeFormatted,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOnline ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOnline ? Icons.videocam_outlined : Icons.business_outlined,
                          size: 13,
                          color: isOnline ? const Color(0xFF4338CA) : AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Teleconsult' : 'In-Person OPD',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? const Color(0xFF4338CA) : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Fee: ₹${apt.consultationFee.toInt()}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Symptoms / Reason
          if (apt.reason != null && apt.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Symptoms: ${apt.reason}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.onSurfaceVariant, height: 1.3),
              ),
            ),
          ],

          // Allergies Flag
          if (patientAllergies != null && patientAllergies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Allergies: $patientAllergies',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Full Patient Medical Report Trigger
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showPatientMedicalReportDialog(context, apt),
              icon: const Icon(Icons.folder_shared_outlined, size: 16),
              label: const Text(
                'View Patient Medical Report & Vitals',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: const BorderSide(color: Color(0xFF14B8A6)),
                backgroundColor: const Color(0xFFF0FDFA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // Action Buttons for Consultation
          if (apt.canConfirm || apt.canComplete) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (apt.canConfirm) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.criticalRed,
                        side: const BorderSide(color: AppColors.criticalRedBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => onReject(apt),
                      child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => onConfirm(apt),
                      child: const Text('Confirm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                if (apt.canComplete) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.outline,
                        side: const BorderSide(color: AppColors.borderHairline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => onNoShow(apt),
                      child: const Text('No-Show', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.stableGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () => onComplete(apt),
                      child: const Text('Complete Consult', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (apt.isConfirmed || apt.isCompleted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F766E),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () => onPrescribe?.call(apt),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Author Digital e-Prescription', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPatientMedicalReportDialog(BuildContext context, DoctorAppointmentModel apt) {
    final patient = apt.patient;
    final vitals = patient?.vitalReadings ?? [];
    final records = patient?.medicalRecords ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient?.fullName ?? 'Patient Medical File',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${apt.mode == "ONLINE" ? "Teleconsult" : "In-Person Clinic"} • Fee: ₹${apt.consultationFee.toInt()}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 8),

                // 1. Patient Baseline
                const Text('Patient Demographics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Gender: ${patient?.gender ?? "N/A"}', style: const TextStyle(fontSize: 12)),
                          Text('Blood: ${patient?.bloodGroup ?? "N/A"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phone: ${patient?.phoneNumber ?? "N/A"}', style: const TextStyle(fontSize: 12)),
                          Text('Allergies: ${patient?.allergies ?? "None"}', style: const TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                        ],
                      ),
                      if (patient?.address != null && patient!.address!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('Address: ${patient.address!}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                      if (patient?.emergencyContact != null && patient!.emergencyContact!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.contact_phone_outlined, size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('Emergency: ${patient.emergencyContact!}', style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                      if (apt.reason != null && apt.reason!.isNotEmpty) ...[
                        const Divider(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Symptoms: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(apt.reason!, style: const TextStyle(fontSize: 12, color: AppColors.onSurface))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Vital Signs (From Smartwatch & Mobile Logs)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Vital Signs & Wearable Telemetry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Live Sync', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (vitals.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text('No recent vital readings logged yet.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vitals.take(6).map((v) {
                      Color bg = const Color(0xFFEFF6FF);
                      Color textCol = const Color(0xFF1D4ED8);
                      IconData ic = Icons.monitor_heart;

                      if (v.metricType.contains('HEART')) {
                        bg = const Color(0xFFFEF2F2);
                        textCol = const Color(0xFFDC2626);
                        ic = Icons.favorite_rounded;
                      } else if (v.metricType.contains('OXYGEN') || v.metricType.contains('SPO2')) {
                        bg = const Color(0xFFEFF6FF);
                        textCol = const Color(0xFF2563EB);
                        ic = Icons.water_drop;
                      } else if (v.metricType.contains('PRESSURE')) {
                        bg = const Color(0xFFFFF7ED);
                        textCol = const Color(0xFFC2410C);
                        ic = Icons.speed;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: textCol.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(ic, size: 16, color: textCol),
                            const SizedBox(width: 6),
                            Text(
                              '${v.metricType.replaceAll('_', ' ')}: ${v.metricValue.toInt()}${v.secondaryValue != null ? "/${v.secondaryValue!.toInt()}" : ""} ${v.unit}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // 3. Uploaded Medical Records & Lab Reports
                const Text('Medical Records & Lab Reports', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (records.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text('No uploaded clinical reports or prescriptions.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  )
                else
                  Column(
                    children: records.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf_outlined, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                  Text('${r.recordType} • ${r.recordDate.toLocal().day}/${r.recordDate.toLocal().month}/${r.recordDate.toLocal().year}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Attached', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Report'),
          ),
        ],
      ),
    );
  }
}
