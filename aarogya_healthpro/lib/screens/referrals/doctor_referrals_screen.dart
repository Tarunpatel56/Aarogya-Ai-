import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/referral_service.dart';
import '../../services/doctor_auth_service.dart';

class DoctorReferralsScreen extends StatefulWidget {
  final ReferralService? referralService;
  final DoctorAuthService? authService;

  const DoctorReferralsScreen({super.key, this.referralService, this.authService});

  @override
  State<DoctorReferralsScreen> createState() => _DoctorReferralsScreenState();
}

class _DoctorReferralsScreenState extends State<DoctorReferralsScreen> with SingleTickerProviderStateMixin {
  late final ReferralService _service;
  late final DoctorAuthService _auth;
  late final TabController _tabController;

  bool _isLoading = true;
  String? _doctorId;
  List<Map<String, dynamic>> _incoming = [];
  List<Map<String, dynamic>> _outgoing = [];

  @override
  void initState() {
    super.initState();
    _service = widget.referralService ?? ReferralService();
    _auth = widget.authService ?? DoctorAuthService();
    _tabController = TabController(length: 2, vsync: this);
    _loadReferrals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReferrals() async {
    setState(() => _isLoading = true);
    try {
      final doctor = _auth.currentProfile;
      final id = doctor?.id ?? _auth.currentUser?.id;
      _doctorId = id;

      if (id != null) {
        final data = await _service.getDoctorReferrals(id);
        if (mounted) {
          setState(() {
            _incoming = List<Map<String, dynamic>>.from(data['incoming'] ?? []);
            _outgoing = List<Map<String, dynamic>>.from(data['outgoing'] ?? []);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToReferral(String referralId, String action) async {
    final notesCtrl = TextEditingController();
    final isAccept = action == 'ACCEPTED';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAccept ? 'Accept Clinical Referral' : 'Decline Referral'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isAccept
                ? 'Mareez ko apne clinical appointment schedule me add karein?'
                : 'Referral ko decline karne ka clinical reason darj karein:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Physician Response Notes (Optional)',
                hintText: 'e.g. Bed confirmed / Clinic full',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: isAccept ? AppColors.primary : Colors.red),
            child: Text(isAccept ? 'Confirm Accept' : 'Decline', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.respondToReferral(
          referralId: referralId,
          action: action,
          responseNotes: notesCtrl.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Referral $action safalta-purvak update ho gaya'),
            backgroundColor: isAccept ? AppColors.primary : Colors.red,
          ),
        );
        _loadReferrals();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCreateReferralDialog() async {
    final patientNameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    String specialty = 'Cardiology';
    String priority = 'ROUTINE';
    bool isGeneratingSummary = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Doctor-to-Doctor Referral',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: patientNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name & Identifier',
                      hintText: 'e.g. Ramesh Kumar (P-1082)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: specialty,
                    items: const [
                      DropdownMenuItem(value: 'Cardiology', child: Text('Cardiology (Hridaya Rog)')),
                      DropdownMenuItem(value: 'Oncology', child: Text('Oncology (Cancer)')),
                      DropdownMenuItem(value: 'Orthopaedics', child: Text('Orthopaedics (Haddi)')),
                      DropdownMenuItem(value: 'Nephrology', child: Text('Nephrology (Kidney)')),
                      DropdownMenuItem(value: 'Neurology', child: Text('Neurology (Nerves/Brain)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => specialty = val);
                    },
                    decoration: const InputDecoration(labelText: 'Specialty Required', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    items: const [
                      DropdownMenuItem(value: 'ROUTINE', child: Text('Routine Clinical Consult')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent (Within 24 Hours)')),
                      DropdownMenuItem(value: 'EMERGENCY', child: Text('Critical Emergency (Immediate)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => priority = val);
                    },
                    decoration: const InputDecoration(labelText: 'Referral Priority', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Reason for Referral',
                      hintText: 'e.g. Refractory angina, elevated troponin, requires coronary angiography.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Clinical Case Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      TextButton.icon(
                        onPressed: isGeneratingSummary
                            ? null
                            : () async {
                                if (patientNameCtrl.text.trim().isEmpty) return;
                                setModalState(() => isGeneratingSummary = true);
                                try {
                                  final res = await _service.generateAiCaseSummary(
                                    patientName: patientNameCtrl.text.trim(),
                                    clinicalData: {
                                      'reason': reasonCtrl.text.trim(),
                                      'specialty': specialty,
                                      'priority': priority,
                                    },
                                  );
                                  final summary = res['clinicalCaseSummary']?.toString() ??
                                      res['executiveSummary']?.toString() ??
                                      '';
                                  setModalState(() {
                                    summaryCtrl.text = summary;
                                    isGeneratingSummary = false;
                                  });
                                } catch (_) {
                                  setModalState(() => isGeneratingSummary = false);
                                }
                              },
                        icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                        label: Text(
                          isGeneratingSummary ? 'Generating...' : 'AI Auto-Generate',
                          style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: summaryCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Detailed clinical telemetry and case history summary...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () async {
                      if (_doctorId == null || patientNameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        await _service.createReferral(
                          referringDoctorId: _doctorId!,
                          targetDoctorId: 'doc_target_specialist_108',
                          patientProfileId: 'patient_profile_active',
                          specialtyRequired: specialty,
                          clinicalReason: reasonCtrl.text.trim(),
                          priority: priority,
                          clinicalSummary: summaryCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Doctor Referral safalta-purvak send kiya gaya!'), backgroundColor: AppColors.primary),
                        );
                        _loadReferrals();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Referral failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Center(
                      child: Text('Send Clinical Referral', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Inter-Doctor Consultations & Referrals',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.onSurface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(icon: const Icon(Icons.inbox_rounded), text: 'Incoming (${_incoming.length})'),
            Tab(icon: const Icon(Icons.outbox_rounded), text: 'Outgoing (${_outgoing.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateReferralDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Refer Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReferralsList(_incoming, isIncoming: true),
                _buildReferralsList(_outgoing, isIncoming: false),
              ],
            ),
    );
  }

  Widget _buildReferralsList(List<Map<String, dynamic>> list, {required bool isIncoming}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isIncoming ? Icons.inbox_outlined : Icons.outbox_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                isIncoming ? 'Koi incoming referral nahi hai.' : 'Aapne abhi koi referral nahi bheja hai.',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final r = list[idx];
        final id = r['id']?.toString() ?? '';
        final specialty = r['specialtyRequired']?.toString() ?? 'Specialist Consultation';
        final reason = r['clinicalReason']?.toString() ?? '';
        final status = r['status']?.toString() ?? 'PENDING';
        final priority = r['priority']?.toString() ?? 'ROUTINE';
        final summary = r['clinicalSummary']?.toString() ?? '';

        final isUrgent = priority == 'URGENT' || priority == 'EMERGENCY';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isUrgent ? Colors.red.shade200 : AppColors.borderHairline),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUrgent ? Colors.red.shade50 : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.medical_information_rounded, color: isUrgent ? Colors.red : AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(specialty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Priority: $priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'ACCEPTED'
                          ? Colors.green.shade50
                          : status == 'REJECTED'
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'ACCEPTED'
                            ? Colors.green.shade800
                            : status == 'REJECTED'
                                ? Colors.red.shade800
                                : Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Clinical Indication: $reason', style: const TextStyle(fontSize: 13, height: 1.3)),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(summary, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
              ],
              if (isIncoming && status == 'PENDING') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToReferral(id, 'REJECTED'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Decline', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respondToReferral(id, 'ACCEPTED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Accept Referral', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
