import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/community_service.dart';

class MedicineSafetyScreen extends StatefulWidget {
  final CommunityService? communityService;

  const MedicineSafetyScreen({super.key, this.communityService});

  @override
  State<MedicineSafetyScreen> createState() => _MedicineSafetyScreenState();
}

class _MedicineSafetyScreenState extends State<MedicineSafetyScreen> {
  late final CommunityService _service;
  final TextEditingController _searchCtrl = TextEditingController(text: 'Crosin');
  bool _isLoading = false;
  Map<String, dynamic>? _safetyInfo;

  final List<Map<String, String>> _popularMedicines = [
    {'name': 'Crosin / Dolo', 'query': 'Crosin', 'tag': 'Bukhar & Dard'},
    {'name': 'Pan-D', 'query': 'Pan-D', 'tag': 'Gas & Acidity'},
    {'name': 'Combiflam', 'query': 'Combiflam', 'tag': 'Badan Dard'},
    {'name': 'Meftal-Spas', 'query': 'Meftal-Spas', 'tag': 'Pet Dard'},
    {'name': 'Azithral 500', 'query': 'Azithral', 'tag': 'Gale & Chest'},
    {'name': 'Cetirizine', 'query': 'Cetirizine', 'tag': 'Sardi & Allergy'},
    {'name': 'Electral ORS', 'query': 'ORS', 'tag': 'Dehydration'},
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _searchMedicine();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchMedicine([String? customQuery]) async {
    final query = (customQuery ?? _searchCtrl.text).trim();
    if (query.isEmpty) return;

    if (customQuery != null) {
      _searchCtrl.text = customQuery;
    }

    setState(() => _isLoading = true);
    final data = await _service.getMedicineSafety(query);
    if (mounted) {
      setState(() {
        _safetyInfo = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Dawa Safety Guide (दवा मार्गदर्शिका)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Dawa ka naam likhein (e.g. Crosin, Pan-D, Combiflam)',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.medication_rounded, size: 22, color: AppColors.primaryTeal),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _searchMedicine(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white, size: 22),
                    onPressed: () => _searchMedicine(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Search Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularMedicines.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = _popularMedicines[idx];
                    final isCurrent = _searchCtrl.text.toLowerCase().contains(item['query']!.toLowerCase());
                    return InkWell(
                      onTap: () => _searchMedicine(item['query']),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent ? AppColors.primaryTeal.withValues(alpha: 0.12) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent ? AppColors.primaryTeal : const Color(0xFFE2E8F0),
                            width: isCurrent ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['name']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                color: isCurrent ? AppColors.primaryTeal : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${item['tag']})',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isCurrent ? AppColors.primaryTeal : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36.0),
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                )
              else if (_safetyInfo != null)
                _buildMedicineCard(_safetyInfo!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> info) {
    final drugName = info['drugName']?.toString() ?? 'Medicine';
    final generic = info['genericName']?.toString() ?? drugName;
    final category = info['therapeuticClass']?.toString() ?? 'Pharmaceutical';
    final simpleUses = (info['simpleUsesHindi'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        (info['standardIndications'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        ['Symptomatic relief as directed by physician'];
    final safeDosage = info['safeDosageHindi']?.toString() ?? info['foodInstructions']?.toString() ?? 'Take with water as directed.';
    final warnings = (info['severeWarnings'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        ['Follow doctor prescription carefully. Do not exceed recommended dose.'];
    final savings = info['genericSavingsHindi']?.toString();
    final sideEffects = (info['commonSideEffects'] as List<dynamic>?)?.join(', ') ?? 'Mild nausea or dizziness';
    final alcohol = info['alcoholInteraction']?.toString() ?? 'Avoid concurrent alcohol consumption.';
    final food = info['foodInstructions']?.toString() ?? 'Take with a glass of water.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Header Card
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.medication_rounded, color: Color(0xFF0284C7), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drugName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Generic Salt: $generic',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Section 1: Yeh Dawa Kis Kaam Aati Hai?
              _buildSectionTitle('🩺 Yeh Dawa Kis Kaam Aati Hai? (Primary Uses)', const Color(0xFF16A34A)),
              const SizedBox(height: 8),
              ...simpleUses.map((use) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            use,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // Section 2: Kese aur Kab Khana Hai?
              _buildSectionTitle('⏰ Kese aur Kab Khana Hai? (Safe Usage & Timing)', const Color(0xFF0284C7)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        safeDosage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF0C4A6E),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Khas Savdhaniyan (Warnings)
              _buildSectionTitle('⚠️ Khas Savdhaniyan (Critical Warnings)', const Color(0xFFDC2626)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: warnings
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    w,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF991B1B),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Section 4: PM Jan Aushadhi Savings
              if (savings != null && savings.isNotEmpty) ...[
                _buildSectionTitle('💰 Sasti Generic Dawa (PM Jan Aushadhi)', const Color(0xFF059669)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.currency_rupee_rounded, color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          savings,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF065F46),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section 5: Side Effects & Interactions
              _buildInfoRow('🩺 Aam Side Effects (Common Effects)', sideEffects),
              const SizedBox(height: 8),
              _buildInfoRow('🍷 Sharab (Alcohol) Interaction', alcohol),
              const SizedBox(height: 8),
              _buildInfoRow('🍽️ Khana aur Paani (Food Timing)', food),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Medical Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Yeh jankari sirf aapki samajh ke liye hai. Nayi dawa shuru karne se pehle apne doctor ya registered pharmacist se salah zaroor lein.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: accent,
      ),
    );
  }

  Widget _buildInfoRow(String title, String details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          details,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
        ),
      ],
    );
  }
}
