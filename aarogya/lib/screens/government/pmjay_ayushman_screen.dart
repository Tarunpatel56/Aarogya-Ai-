import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';
import 'nearby_healthcare_places_screen.dart';

class PmjayAyushmanScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const PmjayAyushmanScreen({super.key, this.service});

  @override
  State<PmjayAyushmanScreen> createState() => _PmjayAyushmanScreenState();
}

class _PmjayAyushmanScreenState extends State<PmjayAyushmanScreen> with SingleTickerProviderStateMixin {
  late final GovernmentHealthService _service;
  late final TabController _tabController;

  // Eligibility Checker
  final TextEditingController _idNumberCtrl = TextEditingController();
  String _selectedIdType = 'AADHAAR';
  bool _isCheckingEligibility = false;
  Map<String, dynamic>? _eligibilityResult;

  // Packages Explorer
  bool _isLoadingPackages = true;
  List<Map<String, dynamic>> _packages = [];
  String _selectedSpecialty = 'ALL';
  final TextEditingController _packageSearchCtrl = TextEditingController();

  final List<String> _specialties = [
    'ALL',
    'Cardiology',
    'Oncology',
    'Orthopaedics',
    'General Surgery',
    'Nephrology',
    'Obstetrics & Gynaecology',
    'Paediatrics'
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _tabController = TabController(length: 2, vsync: this);
    _loadPackages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idNumberCtrl.dispose();
    _packageSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    final idNum = _idNumberCtrl.text.trim();
    if (idNum.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya card number darj karein'), backgroundColor: AppColors.sosRed),
      );
      return;
    }

    setState(() => _isCheckingEligibility = true);
    try {
      final res = await _service.checkAyushmanEligibility(
        idType: _selectedIdType,
        idNumber: idNum,
      );
      if (mounted) {
        setState(() {
          _eligibilityResult = res;
          _isCheckingEligibility = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingEligibility = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eligibility check me truti: $e'), backgroundColor: AppColors.sosRed),
        );
      }
    }
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoadingPackages = true);
    try {
      final list = await _service.getPmjayPackages(
        specialty: _selectedSpecialty,
        search: _packageSearchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _packages = list;
          _isLoadingPackages = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPackages = false);
    }
  }

  void _callHelpline() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ayushman Bharat National Toll-Free: 14555 / 1800-111-565'),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Ayushman Bharat (PM-JAY)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: AppColors.primaryTeal),
            tooltip: 'Toll-Free 14555',
            onPressed: _callHelpline,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.verified_user_rounded), text: 'Patrata Jaanch (Eligibility)'),
            Tab(icon: Icon(Icons.medical_services_rounded), text: '1,949+ Packages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEligibilityTab(),
          _buildPackagesTab(),
        ],
      ),
    );
  }

  Widget _buildEligibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PM-JAY Overview Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFF57C00), Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE65100).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PM-JAY GOLDEN CARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                    Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  ],
                ),
                SizedBox(height: 12),
                Text('₹5,00,000 Saalana Muft Ilaaj', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                SizedBox(height: 4),
                Text('Prati parivaar cash-less aur paper-less upchar sabhi empanelled sarkari aur private hospitals me.', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search Form
          Container(
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
                const Text('Apni Patrata (Eligibility) Check Karein', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                const Text('Aapke paas jo dastavez ho usse check karein:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _selectedIdType,
                  items: const [
                    DropdownMenuItem(value: 'AADHAAR', child: Text('Aadhaar Card Number')),
                    DropdownMenuItem(value: 'RATION_CARD', child: Text('Ration Card Number (NFSA / BPL)')),
                    DropdownMenuItem(value: 'PMJAY_ID', child: Text('PM-JAY Family ID / HH ID')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIdType = val);
                  },
                  decoration: InputDecoration(
                    labelText: 'Dastavez Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _idNumberCtrl,
                  decoration: InputDecoration(
                    labelText: 'Enter Card / Document Number',
                    hintText: _selectedIdType == 'AADHAAR' ? '12-digit number' : 'Document identifier',
                    prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.primaryTeal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isCheckingEligibility ? null : _checkEligibility,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isCheckingEligibility
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Center(
                          child: Text('Patrata Jaanch Karein (Verify Status)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                ),
              ],
            ),
          ),

          if (_eligibilityResult != null) ...[
            const SizedBox(height: 20),
            _buildEligibilityResultCard(_eligibilityResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildEligibilityResultCard(Map<String, dynamic> result) {
    final isEligible = result['isEligible'] == true;
    final beneficiary = result['beneficiaryName']?.toString() ?? 'Citizen';
    final familyMembers = (result['familyMembers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final state = result['state']?.toString() ?? 'All India';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isEligible ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEligible ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEligible ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isEligible ? const Color(0xFF166534) : const Color(0xFF991B1B),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEligible ? 'Aap PM-JAY Ayushman Card ke liye Patra (Eligible) hain!' : 'Yeh dastavez PM-JAY database me darj nahi mila.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isEligible ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          if (isEligible) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text('Labharthi (Beneficiary): $beneficiary', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Rajya: $state', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            if (familyMembers.isNotEmpty) ...[
              const Text('Parivaar ke Sadasya (Covered Family Members):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              ...familyMembers.map((m) => Text('• $m', style: const TextStyle(fontSize: 12))),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _packageSearchCtrl,
                onSubmitted: (_) => _loadPackages(),
                decoration: InputDecoration(
                  hintText: 'Search procedure (e.g. Heart surgery, Knee, Dialysis)...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryTeal),
                    onPressed: _loadPackages,
                  ),
                  filled: true,
                  fillColor: AppColors.scaffoldBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _specialties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final sp = _specialties[idx];
                    final isSel = _selectedSpecialty == sp;
                    return ChoiceChip(
                      label: Text(sp, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: isSel,
                      selectedColor: AppColors.primaryTeal,
                      backgroundColor: AppColors.scaffoldBg,
                      onSelected: (val) {
                        setState(() => _selectedSpecialty = sp);
                        _loadPackages();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingPackages
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
              : _packages.isEmpty
                  ? const Center(child: Text('Koi PM-JAY package nahi mila.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _packages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final p = _packages[idx];
                        final name = p['procedureName']?.toString() ?? 'Medical Procedure';
                        final code = p['packageCode']?.toString() ?? '';
                        final specialty = p['specialty']?.toString() ?? '';
                        final rate = (p['rate'] as num?)?.toDouble() ?? 0.0;
                        final preAuth = p['preAuthRequired'] == true;

                        return InkWell(
                          onTap: () => _showPackageDetailsSheet(p),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
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
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Text(
                                      '₹${rate.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primaryTeal),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Code: $code | $specialty', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const Spacer(),
                                    if (preAuth)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('Pre-Auth Required', style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Tap to view coverage & empaneled hospital benefits →', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showPackageDetailsSheet(Map<String, dynamic> p) {
    final name = p['procedureName']?.toString() ?? 'Medical Procedure';
    final code = p['packageCode']?.toString() ?? '';
    final specialty = p['specialty']?.toString() ?? 'Multi-Speciality';
    final rate = (p['rate'] as num?)?.toDouble() ?? 0.0;
    final preAuth = p['preAuthRequired'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('PM-JAY Scheme Code: $code • $specialty', style: const TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sarkari Nishulk Package Mulya', style: TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                      Text('₹${rate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF166534))),
                      const Text('100% Cashless Coverage under PM-JAY', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('FREE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF166534), fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.scaffoldBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryTeal),
                      const SizedBox(width: 6),
                      const Text('Package me kya kya shamil hai:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('• Operation / Treatment fee and OT charges', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Text('• 3-5 Din tak ka hospital stay aur ward bedding', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Text('• Dawaiyan, test aur discharge ke baad 15 din ki dawa', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (preAuth) ...[
                    const SizedBox(height: 6),
                    Text('• Pre-Authorization: Ayushman Mitra dwara pehle approved karwaya jayega', style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyHealthcarePlacesScreen()));
                    },
                    icon: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
                    label: const Text('Nazdeeki Hospital Dekhein', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '$name (Code: $code)'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package details copy ho gayi!')));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
