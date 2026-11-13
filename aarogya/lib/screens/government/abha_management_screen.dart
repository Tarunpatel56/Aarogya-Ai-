import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';
import '../../core/storage/token_storage.dart';

class AbhaManagementScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const AbhaManagementScreen({super.key, this.service});

  @override
  State<AbhaManagementScreen> createState() => _AbhaManagementScreenState();
}

class _AbhaManagementScreenState extends State<AbhaManagementScreen> {
  late final GovernmentHealthService _service;
  final ITokenStorage _tokenStorage = SecureTokenStorage();

  bool _isLoading = true;
  String? _patientProfileId;
  Map<String, dynamic>? _abhaProfile;
  List<Map<String, dynamic>> _consents = [];
  List<Map<String, dynamic>> _linkedRecords = [];

  // Creation / Linking Form Controllers
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _abhaAddressController = TextEditingController();

  bool _isOtpSent = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _loadProfileAndData();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    _abhaAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _tokenStorage.getUser();
      final profileId = user?['patientProfile']?['id']?.toString() ??
          user?['profile']?['id']?.toString() ??
          user?['id']?.toString();

      _patientProfileId = profileId;

      if (profileId != null) {
        final data = await _service.getAbhaProfile(profileId);
        if (data != null && mounted) {
          setState(() {
            _abhaProfile = data['abhaProfile'] as Map<String, dynamic>?;
            if (data['consents'] is List) {
              _consents = List<Map<String, dynamic>>.from(data['consents']);
            }
            if (data['linkedRecords'] is List) {
              _linkedRecords = List<Map<String, dynamic>>.from(data['linkedRecords']);
            }
          });
        }
      }
    } catch (_) {
      // Non-blocking load
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    final aadhaar = _aadhaarController.text.trim();
    if (aadhaar.length < 12) {
      _showMessage('Kripya 12-digit Aadhaar number darj karein', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.generateAbhaOtp(aadhaarNumber: aadhaar);
      setState(() {
        _isOtpSent = true;
      });
      _showMessage('Aadhaar OTP safalta-purvak bheja gaya (Sandbox OTP: 123456)');
    } catch (e) {
      _showMessage('OTP bhejne me dikkat aayi: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtpAndCreate() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showMessage('Kripya 6-digit OTP darj karein', isError: true);
      return;
    }

    if (_patientProfileId == null) {
      _showMessage('Patient profile ID uplabdh nahi hai. Kripya login check karein.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _service.createOrLinkAbha(
        aadhaarNumber: _aadhaarController.text.trim(),
        otp: otp,
        patientProfileId: _patientProfileId!,
        preferredAbhaAddress: _abhaAddressController.text.trim(),
      );

      _showMessage('ABHA ID safalta-purvak ban gayi aur link ho gayi!');
      _loadProfileAndData();
    } catch (e) {
      _showMessage('ABHA verification failed: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.sosRed : AppColors.primaryTeal,
      ),
    );
  }

  Future<void> _handleConsentAction(String consentId, String action) async {
    try {
      await _service.updateConsentAction(consentId, action);
      _showMessage('Consent anurodh ko $action kar diya gaya');
      _loadProfileAndData();
    } catch (e) {
      _showMessage('Consent update me samasya: $e', isError: true);
    }
  }

  Future<void> _showAiSummaryModal(String recordName, String content) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primaryTeal, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI Health Record Summary ($recordName)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _service.summarizeHealthRecord(recordText: content, language: 'hi'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primaryTeal),
                          SizedBox(height: 12),
                          Text('ABDM FHIR Record ka AI Clinical Vishleshan ho raha hai...', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text('Summary generate karne me truti: ${snapshot.error ?? "No data"}'),
                    );
                  }

                  final data = snapshot.data!;
                  final summary = data['patientSummaryHindi']?.toString() ??
                      data['plainLanguageSummary']?.toString() ??
                      'Medical record summary is ready.';
                  final keyFindings = (data['keyFindings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                  final nextSteps = (data['recommendedNextSteps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            summary,
                            style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF166534)),
                          ),
                        ),
                        if (keyFindings.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Pramukh Nateeje (Key Findings):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          ...keyFindings.map((f) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              )),
                        ],
                        if (nextSteps.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text('Agla Kadam (Doctor Advice):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          ...nextSteps.map((s) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: AppColors.primaryTeal, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'ABHA & ABDM Ecosystem',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileAndData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_abhaProfile != null) ...[
                    _buildAbhaCard(_abhaProfile!),
                    const SizedBox(height: 20),
                    _buildConsentsSection(),
                    const SizedBox(height: 20),
                    _buildLinkedRecordsSection(),
                  ] else ...[
                    _buildCreateOrLinkCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildAbhaCard(Map<String, dynamic> abha) {
    final abhaNumber = abha['abhaNumber']?.toString() ?? '14-Digit ABHA ID';
    final abhaAddress = abha['abhaAddress']?.toString() ?? 'user@abdm';
    final name = abha['fullName']?.toString() ?? 'Verified Citizen';
    final gender = abha['gender']?.toString() ?? 'N/A';
    final dob = abha['dateOfBirth']?.toString() ?? 'N/A';
    final bloodGroup = abha['bloodGroup']?.toString() ?? 'B+';
    final status = abha['status']?.toString() ?? 'ACTIVE';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B), Color(0xFF0A7E70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NATIONAL HEALTH AUTHORITY',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        'Ayushman Bharat Digital Mission',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            abhaNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ABHA Address: $abhaAddress',
            style: const TextStyle(color: Color(0xFFE0F2F1), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CITIZEN NAME', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GENDER / DOB', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('$gender | $dob', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BLOOD', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(bloodGroup, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateOrLinkCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primaryTeal, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apna ABHA ID Banayein ya Link Karein',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'National Digital Health Mission se direct juden',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _aadhaarController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: InputDecoration(
              labelText: '12-Digit Aadhaar Card Number',
              hintText: 'XXXX-XXXX-XXXX',
              counterText: '',
              prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primaryTeal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          if (!_isOtpSent) ...[
            ElevatedButton(
              onPressed: _isSubmitting ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Center(
                      child: Text('Aadhaar OTP Bhejein', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ),
          ] else ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Enter 6-digit OTP',
                hintText: '123456',
                counterText: '',
                prefixIcon: const Icon(Icons.lock_clock_rounded, color: AppColors.primaryTeal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _abhaAddressController,
              decoration: InputDecoration(
                labelText: 'Preferred ABHA Address (Optional)',
                hintText: 'e.g. rahul@abdm',
                prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.primaryTeal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _verifyOtpAndCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Center(
                      child: Text('Verify OTP & Link ABHA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsentsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Row(
                children: [
                  Icon(Icons.rule_rounded, color: AppColors.primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Text('ABDM Consent Manager (M3)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_consents.length} Requests', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_consents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Koi sakriya consent anurodh nahi hai. Aapka data puri tarah surakshit hai.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _consents.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final c = _consents[idx];
                final status = c['status']?.toString() ?? 'REQUESTED';
                final requester = c['requesterName']?.toString() ?? 'Hospital Staff';
                final purpose = c['purpose']?.toString() ?? 'Clinical Consultation';
                final consentId = c['id']?.toString() ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(requester, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'GRANTED'
                                ? Colors.green.shade50
                                : status == 'DENIED' || status == 'REVOKED'
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == 'GRANTED'
                                  ? Colors.green.shade700
                                  : status == 'DENIED' || status == 'REVOKED'
                                      ? Colors.red.shade700
                                      : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Uddeshya: $purpose', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    if (status == 'REQUESTED')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleConsentAction(consentId, 'DENIED'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.sosRed,
                                side: const BorderSide(color: AppColors.sosRed),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text('Deny (Mana Karein)', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleConsentAction(consentId, 'GRANTED'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: const Text('Grant (Manzoor Karein)', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      )
                    else if (status == 'GRANTED')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _handleConsentAction(consentId, 'REVOKED'),
                          icon: const Icon(Icons.cancel_outlined, size: 14, color: AppColors.sosRed),
                          label: const Text('Revoke Consent (Wapas Lein)', style: TextStyle(color: AppColors.sosRed, fontSize: 11)),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLinkedRecordsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Row(
                children: [
                  Icon(Icons.folder_shared_rounded, color: AppColors.primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Text('ABDM Linked Health Records (M2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Text('${_linkedRecords.length} Documents', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          if (_linkedRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Abhi koi linked medical record nahi hai.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _linkedRecords.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final r = _linkedRecords[idx];
                final hipName = r['hipName']?.toString() ?? 'Healthcare Facility';
                final docType = r['documentType']?.toString() ?? 'MEDICAL_RECORD';
                final content = r['fhirBundle']?.toString() ?? 'Clinical summary available in health record.';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: AppColors.primaryTeal),
                  ),
                  title: Text(hipName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(docType, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: AppColors.primaryTeal),
                    tooltip: 'AI Clinical Summary',
                    onPressed: () => _showAiSummaryModal(docType, content),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
