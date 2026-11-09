import 'package:flutter/material.dart';
import '../theme/clinical_sanctuary_theme.dart';
import '../models/clinical_imaging_review_model.dart';
import '../services/clinical_imaging_service.dart';
import '../services/doctor_auth_service.dart';
import '../services/doctor_ai_service.dart';
import 'modals/physio_prescribe_dialog.dart';
import 'modals/doctor_copilot_telemetry_dialog.dart';

class DoctorImagingReviewScreen extends StatefulWidget {
  final ClinicalImagingService? imagingService;
  final DoctorAuthService? authService;
  final DoctorAiService? aiService;

  const DoctorImagingReviewScreen({
    super.key,
    this.imagingService,
    this.authService,
    this.aiService,
  });

  @override
  State<DoctorImagingReviewScreen> createState() => _DoctorImagingReviewScreenState();
}

class _DoctorImagingReviewScreenState extends State<DoctorImagingReviewScreen> {
  late final ClinicalImagingService _imagingService;
  late final DoctorAuthService _authService;
  late final DoctorAiService _aiService;

  ImagingModality? _selectedModality;
  ClinicalReviewStatus? _selectedStatus;

  // Sign-off controllers keyed by review ID
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, TextEditingController> _overrideControllers = {};
  final Map<String, bool> _agreesWithAiMap = {};
  final Map<String, String?> _prescribedPhysioMap = {};
  final Map<String, List<String>> _prescribedMedsMap = {};

  @override
  void initState() {
    super.initState();
    _imagingService = widget.imagingService ?? ClinicalImagingService();
    _authService = widget.authService ?? DoctorAuthService();
    _aiService = widget.aiService ?? DoctorAiService();
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    for (final controller in _overrideControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getNotesController(String id, String? initial) {
    return _notesControllers.putIfAbsent(
      id,
      () => TextEditingController(text: initial ?? ''),
    );
  }

  TextEditingController _getOverrideController(String id, String? initial) {
    return _overrideControllers.putIfAbsent(
      id,
      () => TextEditingController(text: initial ?? ''),
    );
  }

  bool _getAgreesWithAi(String id, bool initial) {
    return _agreesWithAiMap.putIfAbsent(id, () => initial);
  }

  Future<void> _handleSignOff(ClinicalImagingReview review) async {
    final notesController = _getNotesController(review.id, review.doctorNotes);
    final overrideController = _getOverrideController(review.id, review.overrideDiagnosis);
    final agrees = _getAgreesWithAi(review.id, review.isAgreedWithAi);

    if (notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter clinical diagnostic notes before signing off.'),
          backgroundColor: ClinicalColors.crimsonRose,
        ),
      );
      return;
    }

    if (!agrees && overrideController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify the clinical override diagnosis and rationale.'),
          backgroundColor: ClinicalColors.crimsonRose,
        ),
      );
      return;
    }

    final doctorName = _authService.currentProfile?.fullName ?? 'Dr. Aarav Mehta, MD';

    await _imagingService.validateReview(
      id: review.id,
      doctorName: doctorName,
      notes: notesController.text.trim(),
      agreesWithAi: agrees,
      overrideDiagnosis: agrees ? null : overrideController.text.trim(),
      prescribedPhysioPlan: _prescribedPhysioMap[review.id] ?? review.prescribedPhysioPlan,
      prescribedMedications: _prescribedMedsMap[review.id] ?? review.prescribedMedications,
    );

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            agrees
                ? '✓ Imaging study verified and signed by $doctorName'
                : '✓ Clinical override logged and signed by $doctorName',
          ),
          backgroundColor: agrees ? ClinicalColors.primaryTeal : ClinicalColors.deepSlateNavy,
        ),
      );
    }
  }

  void _openPhysioPrescriptionModal(ClinicalImagingReview review) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => PhysioPrescribeDialog(
        patientName: review.patientName,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _prescribedPhysioMap[review.id] = result['summary'] as String?;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Physiotherapy routine assigned to ${review.patientName}'),
          backgroundColor: ClinicalColors.primaryTeal,
        ),
      );
    }
  }

  void _openAddMedicationDialog(ClinicalImagingReview review) async {
    final medController = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Prescribe Medication for ${review.patientName}'),
        content: TextField(
          controller: medController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Amoxicillin-Clavulanate 625mg BD x 5 days',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ClinicalColors.primaryTeal),
            onPressed: () {
              if (medController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, medController.text.trim());
              }
            },
            child: const Text('Add Medication', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (added != null && mounted) {
      setState(() {
        final list = List<String>.from(_prescribedMedsMap[review.id] ?? review.prescribedMedications);
        list.add(added);
        _prescribedMedsMap[review.id] = list;
      });
    }
  }

  void _openCoPilotTelemetryDialog(ClinicalImagingReview review) {
    showDialog(
      context: context,
      builder: (ctx) => DoctorCoPilotTelemetryDialog(
        patientName: review.patientName,
        age: review.patientAge,
        gender: review.patientGender,
        currentDiagnosis: '${review.modalityLabel}: ${review.aiPreClassification}',
        aiService: _aiService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allReviews = _imagingService.getReviews();
    final filteredReviews = _imagingService.getReviews(
      modality: _selectedModality,
      status: _selectedStatus,
    );

    final pendingCount = allReviews.where((r) => r.isPending).length;
    final validatedCount = allReviews.where((r) => r.isValidated).length;
    final overriddenCount = allReviews.where((r) => r.isOverridden).length;

    return Scaffold(
      backgroundColor: ClinicalColors.sanctuaryBaseNeutral,
      appBar: AppBar(
        title: Text(
          'Clinical Imaging Review Queue',
          style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
              .copyWith(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ClinicalColors.primaryTeal),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Header Cards
            Row(
              children: [
                _buildStatPill('Pending Review', '$pendingCount', ClinicalColors.warningAmber),
                const SizedBox(width: 8),
                _buildStatPill('Validated', '$validatedCount', ClinicalColors.optimalEmerald),
                const SizedBox(width: 8),
                _buildStatPill('Overridden', '$overriddenCount', ClinicalColors.crimsonRose),
              ],
            ),
            const SizedBox(height: 14),

            // Modality Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All Modalities (${allReviews.length})',
                    isSelected: _selectedModality == null,
                    onTap: () => setState(() => _selectedModality = null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Brain MRI',
                    isSelected: _selectedModality == ImagingModality.brainMri,
                    onTap: () => setState(() => _selectedModality = ImagingModality.brainMri),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Chest X-Ray',
                    isSelected: _selectedModality == ImagingModality.chestXray,
                    onTap: () => setState(() => _selectedModality = ImagingModality.chestXray),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Dermoscopy',
                    isSelected: _selectedModality == ImagingModality.skinLesion,
                    onTap: () => setState(() => _selectedModality = ImagingModality.skinLesion),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All Statuses',
                    isSelected: _selectedStatus == null,
                    onTap: () => setState(() => _selectedStatus = null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Pending Only',
                    isSelected: _selectedStatus == ClinicalReviewStatus.pendingReview,
                    onTap: () => setState(() => _selectedStatus = ClinicalReviewStatus.pendingReview),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Validated Only',
                    isSelected: _selectedStatus == ClinicalReviewStatus.validated,
                    onTap: () => setState(() => _selectedStatus = ClinicalReviewStatus.validated),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Overridden Only',
                    isSelected: _selectedStatus == ClinicalReviewStatus.overridden,
                    onTap: () => setState(() => _selectedStatus = ClinicalReviewStatus.overridden),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (filteredReviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: ClinicalColors.primaryTeal, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No imaging studies match the selected filters.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: ClinicalColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              ...filteredReviews.map((review) => _buildReviewCard(review)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: ClinicalRadii.roundedMd,
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted).copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ClinicalRadii.roundedFull,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ClinicalColors.deepSlateNavy : Colors.white,
          borderRadius: ClinicalRadii.roundedFull,
          border: Border.all(
            color: isSelected ? ClinicalColors.deepSlateNavy : ClinicalColors.hairlineBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : ClinicalColors.deepSlateNavy,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(ClinicalImagingReview review) {
    final isAgreed = _getAgreesWithAi(review.id, review.isAgreedWithAi);
    final notesController = _getNotesController(review.id, review.doctorNotes);
    final overrideController = _getOverrideController(review.id, review.overrideDiagnosis);
    final prescribedPhysio = _prescribedPhysioMap[review.id] ?? review.prescribedPhysioPlan;
    final prescribedMeds = _prescribedMedsMap[review.id] ?? review.prescribedMedications;

    Color statusColor;
    String statusText;
    switch (review.reviewStatus) {
      case ClinicalReviewStatus.validated:
        statusColor = ClinicalColors.optimalEmerald;
        statusText = 'DOCTOR VALIDATED';
        break;
      case ClinicalReviewStatus.overridden:
        statusColor = ClinicalColors.crimsonRose;
        statusText = 'CLINICALLY OVERRIDDEN';
        break;
      case ClinicalReviewStatus.pendingReview:
        statusColor = ClinicalColors.warningAmber;
        statusText = 'PENDING REVIEW';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: ClinicalRadii.roundedLg,
        border: Border.all(color: ClinicalColors.hairlineBorder),
        boxShadow: ClinicalElevations.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: ClinicalColors.hairlineBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: ClinicalColors.primaryTeal.withOpacity(0.12),
                        child: Text(
                          review.patientName.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ClinicalColors.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review.patientName} (${review.patientGender}, ${review.patientAge}y)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Study ID: ${review.id} • Modality: ${review.modalityLabel}',
                              style: const TextStyle(fontSize: 10, color: ClinicalColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: ClinicalRadii.roundedSm,
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scan Preview Container & AI Analysis Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: ClinicalRadii.roundedMd,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.tealAccent.withOpacity(0.5)),
                        ),
                        child: Center(
                          child: Icon(
                            review.modality == ImagingModality.brainMri
                                ? Icons.psychology_outlined
                                : review.modality == ImagingModality.chestXray
                                    ? Icons.medical_services_outlined
                                    : Icons.grain_outlined,
                            color: Colors.tealAccent,
                            size: 28,
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
                                  review.modalityLabel.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${(review.aiConfidence * 100).toStringAsFixed(1)}% AI Confidence',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              review.aiPreClassification,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Provider: ${review.aiProvider}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Mandatory Clinical Notice Callout
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: ClinicalRadii.roundedSm,
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          review.mandatoryClinicalNotice,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // When in PENDING REVIEW state: doctor interaction inputs
                if (review.isPending) ...[
                  Text(
                    'PHYSICIAN CLINICAL EVALUATION',
                    style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                        .copyWith(fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),

                  // Agreement vs Override Radio Options
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _agreesWithAiMap[review.id] = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isAgreed ? ClinicalColors.optimalWash.withOpacity(0.5) : Colors.white,
                              borderRadius: ClinicalRadii.roundedSm,
                              border: Border.all(
                                color: isAgreed ? ClinicalColors.primaryTeal : ClinicalColors.hairlineBorder,
                                width: isAgreed ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isAgreed ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isAgreed ? ClinicalColors.primaryTeal : ClinicalColors.textMuted,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Agree with AI',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _agreesWithAiMap[review.id] = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: !isAgreed ? const Color(0xFFFEF2F2) : Colors.white,
                              borderRadius: ClinicalRadii.roundedSm,
                              border: Border.all(
                                color: !isAgreed ? ClinicalColors.crimsonRose : ClinicalColors.hairlineBorder,
                                width: !isAgreed ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  !isAgreed ? Icons.error_rounded : Icons.radio_button_unchecked,
                                  color: !isAgreed ? ClinicalColors.crimsonRose : ClinicalColors.textMuted,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Clinical Override',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (!isAgreed) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: overrideController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Override Diagnosis & Clinical Disagreement Rationale *',
                        hintText: 'e.g. Suspected early atypical consolidation, non-infectious etiology',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                        isDense: true,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      labelText: 'Doctor Clinical Diagnostic Notes *',
                      hintText: 'Enter clinical findings, patient symptoms correlation, and plan...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Optional Add-on Prescriptions (Physio & Meds)
                  if (prescribedPhysio != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ClinicalColors.optimalWash.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded, color: ClinicalColors.primaryTeal, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Physio Plan: $prescribedPhysio',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 14),
                            onPressed: () => setState(() => _prescribedPhysioMap.remove(review.id)),
                          ),
                        ],
                      ),
                    ),

                  if (prescribedMeds.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prescribed Medications:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: prescribedMeds.map((med) => Chip(
                              label: Text(med, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )).toList(),
                          ),
                        ],
                      ),
                    ),

                  // Action Buttons: Prescribe Physio / Prescribe Meds / Co-Pilot Telemetry
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openPhysioPrescriptionModal(review),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: ClinicalColors.primaryTeal),
                          ),
                          icon: const Icon(Icons.fitness_center_rounded, size: 14, color: ClinicalColors.primaryTeal),
                          label: const Text('Prescribe Physio', style: TextStyle(fontSize: 11, color: ClinicalColors.primaryTeal)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openAddMedicationDialog(review),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: ClinicalColors.deepSlateNavy),
                          ),
                          icon: const Icon(Icons.medication_outlined, size: 14, color: ClinicalColors.deepSlateNavy),
                          label: const Text('+ Medication', style: TextStyle(fontSize: 11, color: ClinicalColors.deepSlateNavy)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openCoPilotTelemetryDialog(review),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF7C3AED)),
                          label: const Text('Co-Pilot', style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sign & Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleSignOff(review),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAgreed ? ClinicalColors.primaryTeal : ClinicalColors.crimsonRose,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: ClinicalRadii.roundedMd),
                      ),
                      icon: const Icon(Icons.draw_rounded, size: 16),
                      label: Text(
                        isAgreed ? 'Sign & Validate Clinical Report' : 'Sign & Submit Clinical Override',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ] else ...[
                  // When already signed off / validated
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: review.isValidated
                          ? ClinicalColors.optimalWash.withOpacity(0.5)
                          : const Color(0xFFFEF2F2),
                      borderRadius: ClinicalRadii.roundedMd,
                      border: Border.all(
                        color: review.isValidated
                            ? ClinicalColors.optimalEmerald.withOpacity(0.4)
                            : ClinicalColors.crimsonRose.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              review.isValidated ? Icons.verified_user_rounded : Icons.warning_rounded,
                              color: review.isValidated
                                  ? ClinicalColors.optimalEmerald
                                  : ClinicalColors.crimsonRose,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                review.isValidated
                                    ? 'Signed & Verified by ${review.doctorSignOff ?? "Doctor"}'
                                    : 'Clinically Overridden by ${review.doctorSignOff ?? "Doctor"}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (review.overrideDiagnosis != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Override Diagnosis: ${review.overrideDiagnosis}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: ClinicalColors.crimsonRose,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Doctor Notes: ${review.doctorNotes ?? "Routine evaluation complete."}',
                          style: const TextStyle(fontSize: 11.5, color: ClinicalColors.deepSlateNavy),
                        ),
                        if (review.prescribedPhysioPlan != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Prescribed Physio: ${review.prescribedPhysioPlan}',
                            style: const TextStyle(fontSize: 11, color: ClinicalColors.primaryTeal, fontWeight: FontWeight.w600),
                          ),
                        ],
                        if (review.prescribedMedications.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Prescribed Meds: ${review.prescribedMedications.join(", ")}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4338CA), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _openCoPilotTelemetryDialog(review),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF7C3AED)),
                      label: const Text('Review Telemetry Co-Pilot', style: TextStyle(fontSize: 10.5, color: Color(0xFF7C3AED))),
                    ),
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
