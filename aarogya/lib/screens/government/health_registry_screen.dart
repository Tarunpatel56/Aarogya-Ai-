import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';

class HealthRegistryScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const HealthRegistryScreen({super.key, this.service});

  @override
  State<HealthRegistryScreen> createState() => _HealthRegistryScreenState();
}

class _HealthRegistryScreenState extends State<HealthRegistryScreen> with SingleTickerProviderStateMixin {
  late final GovernmentHealthService _service;
  late final TabController _tabController;

  bool _isLoadingHfr = true;
  bool _isLoadingHpr = true;
  List<Map<String, dynamic>> _facilities = [];
  List<Map<String, dynamic>> _doctors = [];

  final TextEditingController _hfrSearchCtrl = TextEditingController();
  final TextEditingController _hprSearchCtrl = TextEditingController();

  String _selectedFacilityType = 'ALL';
  final List<String> _facilityTypes = ['ALL', 'HOSPITAL', 'CLINIC', 'DIAGNOSTIC_LAB', 'PHARMACY'];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _tabController = TabController(length: 2, vsync: this);
    _loadHfr();
    _loadHpr();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hfrSearchCtrl.dispose();
    _hprSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHfr() async {
    setState(() => _isLoadingHfr = true);
    try {
      final list = await _service.getHfrFacilities(
        facilityType: _selectedFacilityType,
        search: _hfrSearchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _facilities = list;
          _isLoadingHfr = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHfr = false);
    }
  }

  Future<void> _loadHpr() async {
    setState(() => _isLoadingHpr = true);
    try {
      final list = await _service.getHprPractitioners(
        search: _hprSearchCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _doctors = list;
          _isLoadingHpr = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHpr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'National Health Registries (HFR & HPR)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.local_hospital_rounded), text: 'Hospital Registry (HFR)'),
            Tab(icon: Icon(Icons.person_pin_rounded), text: 'Doctor Registry (HPR)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHfrTab(),
          _buildHprTab(),
        ],
      ),
    );
  }

  Widget _buildHfrTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _hfrSearchCtrl,
                onSubmitted: (_) => _loadHfr(),
                decoration: InputDecoration(
                  hintText: 'Search hospital or clinic name...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryTeal),
                    onPressed: _loadHfr,
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
                  itemCount: _facilityTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final type = _facilityTypes[idx];
                    final isSel = _selectedFacilityType == type;
                    return ChoiceChip(
                      label: Text(type, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: isSel,
                      selectedColor: AppColors.primaryTeal,
                      backgroundColor: AppColors.scaffoldBg,
                      onSelected: (val) {
                        setState(() => _selectedFacilityType = type);
                        _loadHfr();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingHfr
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
              : _facilities.isEmpty
                  ? const Center(child: Text('Koi certified hospital nahi mila.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _facilities.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final f = _facilities[idx];
                        final name = f['facilityName']?.toString() ?? 'Hospital';
                        final hfrId = f['hfrId']?.toString() ?? '';
                        final system = f['systemOfMedicine']?.toString() ?? 'ALLOPATHY';
                        final state = f['state']?.toString() ?? '';
                        final district = f['district']?.toString() ?? '';
                        final isAyushman = f['isAyushmanEmpanelled'] == true;

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
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.verified_outlined, color: AppColors.primaryTeal, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text('HFR ID: $hfrId • $system', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('$district, $state', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              if (isAyushman) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('PM-JAY Ayushman Bharat Empanelled (Cashless)', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHprTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _hprSearchCtrl,
            onSubmitted: (_) => _loadHpr(),
            decoration: InputDecoration(
              hintText: 'Search doctor name or specialization...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryTeal),
                onPressed: _loadHpr,
              ),
              filled: true,
              fillColor: AppColors.scaffoldBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingHpr
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
              : _doctors.isEmpty
                  ? const Center(child: Text('Koi verified doctor nahi mila.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _doctors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final d = _doctors[idx];
                        final name = d['doctorName']?.toString() ?? 'Dr. Specialist';
                        final hprId = d['hprId']?.toString() ?? '';
                        final nmc = d['nmcRegistrationNumber']?.toString() ?? '';
                        final spec = d['specialization']?.toString() ?? 'General Physician';
                        final council = d['stateMedicalCouncil']?.toString() ?? 'NMC';

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
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: AppColors.primaryTeal),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(spec, style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('NMC Verified', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Text('HPR ID: $hprId | Reg: $nmc ($council)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

