import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';
import '../../core/storage/token_storage.dart';

class MaternalChildScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const MaternalChildScreen({super.key, this.service});

  @override
  State<MaternalChildScreen> createState() => _MaternalChildScreenState();
}

class _MaternalChildScreenState extends State<MaternalChildScreen> with SingleTickerProviderStateMixin {
  late final GovernmentHealthService _service;
  late final TabController _tabController;
  final ITokenStorage _tokenStorage = SecureTokenStorage();

  bool _isLoading = true;
  String? _patientProfileId;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _tabController = TabController(length: 2, vsync: this);
    _loadMchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMchData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _tokenStorage.getUser();
      final profileId = user?['patientProfile']?['id']?.toString() ??
          user?['profile']?['id']?.toString() ??
          user?['id']?.toString();

      _patientProfileId = profileId;
      if (profileId != null) {
        final list = await _service.getMchProfiles(profileId);
        if (mounted) {
          setState(() {
            _profiles = list;
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

  Future<void> _showAddProfileModal(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String type = 'PREGNANT_MOTHER';
    final lmpCtrl = TextEditingController(text: '2026-04-10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Naya MCH Profile Banayein', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Beneficiary Name (Maa ya Bacche ka naam)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'PREGNANT_MOTHER', child: Text('Garbhavati Mahila (Pregnant Mother)')),
                  DropdownMenuItem(value: 'LACTATING_MOTHER', child: Text('Dhaatri Mata (Lactating Mother)')),
                  DropdownMenuItem(value: 'INFANT', child: Text('Shishu / Baccha (Infant 0-5 yrs)')),
                ],
                onChanged: (val) {
                  if (val != null) type = val;
                },
                decoration: const InputDecoration(labelText: 'Beneficiary Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lmpCtrl,
                decoration: const InputDecoration(labelText: 'Last Menstrual Period (LMP) Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  if (_patientProfileId == null || nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await _service.createMchProfile({
                      'patientProfileId': _patientProfileId,
                      'beneficiaryName': nameCtrl.text.trim(),
                      'beneficiaryType': type,
                      'lmpDate': lmpCtrl.text.trim(),
                    });
                    _loadMchData();
                  } catch (_) {
                    setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                child: const Center(child: Text('Profile Surakshit Karein', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motherProfiles = _profiles.where((p) => p['beneficiaryType'] == 'PREGNANT_MOTHER' || p['beneficiaryType'] == 'LACTATING_MOTHER').toList();
    final childProfiles = _profiles.where((p) => p['beneficiaryType'] == 'INFANT').toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Maa & Shishu Suraksha (MCH)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryTeal),
            tooltip: 'Naya Profile Jodein',
            onPressed: () => _showAddProfileModal(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.pregnant_woman_rounded), text: 'Maternal Care (Garbhavastha)'),
            Tab(icon: Icon(Icons.child_care_rounded), text: 'U-WIN Teekakaran (Child)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMaternalTab(motherProfiles),
                _buildChildTab(childProfiles),
              ],
            ),
    );
  }

  Widget _buildMaternalTab(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pregnant_woman_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('Koi Garbhavati Mahila profile darj nahi hai.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddProfileModal(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('MCH Profile Jodein', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, idx) {
        final m = list[idx];
        final name = m['beneficiaryName']?.toString() ?? 'Mother';
        final weeks = (m['gestationalAgeWeeks'] as num?)?.toInt() ?? 24;
        final edd = m['expectedDeliveryDate']?.toString() ?? 'N/A';
        final isHighRisk = m['isHighRisk'] == true;
        final redFlags = (m['highRiskFactors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final ancVisits = (m['ancVisitsCompleted'] as num?)?.toInt() ?? 2;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isHighRisk ? const Color(0xFFFECACA) : AppColors.cardBorder),
            boxShadow: AppColors.cardShadow,
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
                          color: isHighRisk ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pregnant_woman_rounded,
                          color: isHighRisk ? AppColors.sosRed : AppColors.primaryTeal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('EDD: $edd', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  if (isHighRisk)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sosLightBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PMSMA High Risk', style: TextStyle(color: AppColors.sosRed, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Gestational Timeline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Garbh Awastha: $weeks Weeks', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryTeal)),
                  Text(weeks <= 12 ? 'Pehla Trimester' : weeks <= 26 ? 'Doosra Trimester' : 'Teesra Trimester', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (weeks / 40.0).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppColors.primaryTeal,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 14),
              // ANC Visits status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ANC Jaanch (Visits Completed):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('$ancVisits / 4 Pura', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal)),
                  ],
                ),
              ),
              if (redFlags.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Savdhani (PMSMA Red Flag Indicators):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sosRed)),
                const SizedBox(height: 4),
                ...redFlags.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.sosRed),
                          const SizedBox(width: 6),
                          Expanded(child: Text(f, style: const TextStyle(fontSize: 11, color: AppColors.sosRed))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildTab(List<Map<String, dynamic>> list) {
    final vaccines = [
      {'name': 'BCG (Tuberculosis)', 'age': 'Janm Par (At Birth)', 'status': 'GIVEN'},
      {'name': 'Hepatitis B (Birth Dose)', 'age': 'Janm ke 24 ghante me', 'status': 'GIVEN'},
      {'name': 'OPV-0 (Oral Polio)', 'age': 'Janm Par', 'status': 'GIVEN'},
      {'name': 'Pentavalent 1 (DPT, Hep B, Hib)', 'age': '6 Hafte (6 Weeks)', 'status': 'GIVEN'},
      {'name': 'Rotavirus 1 & PCV 1', 'age': '6 Hafte', 'status': 'GIVEN'},
      {'name': 'Pentavalent 2 & OPV 2', 'age': '10 Hafte (10 Weeks)', 'status': 'PENDING'},
      {'name': 'Pentavalent 3 & Fractional IPV', 'age': '14 Hafte (14 Weeks)', 'status': 'SCHEDULED'},
      {'name': 'MR 1st Dose (Measles Rubella)', 'age': '9-12 Mahine', 'status': 'UPCOMING'},
      {'name': 'DPT Booster 1 & Vitamin A', 'age': '16-24 Mahine', 'status': 'UPCOMING'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.verified_outlined, color: Color(0xFF166534), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('U-WIN National Immunization Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                    Text('Sarkari Sarvbhaumik Teekakaran Karyakram (UIP)', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...vaccines.map((v) {
          final isGiven = v['status'] == 'GIVEN';
          final isPending = v['status'] == 'PENDING';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(
                isGiven ? Icons.check_circle_rounded : isPending ? Icons.pending_rounded : Icons.schedule_rounded,
                color: isGiven ? Colors.green : isPending ? Colors.orange : Colors.grey,
              ),
              title: Text(v['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Aayu: ${v['age']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isGiven
                      ? Colors.green.shade50
                      : isPending
                          ? Colors.orange.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v['status']!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isGiven
                        ? Colors.green.shade800
                        : isPending
                            ? Colors.orange.shade800
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
