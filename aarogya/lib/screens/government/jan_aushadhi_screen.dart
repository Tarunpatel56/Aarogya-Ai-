import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';

class JanAushadhiScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const JanAushadhiScreen({super.key, this.service});

  @override
  State<JanAushadhiScreen> createState() => _JanAushadhiScreenState();
}

class _JanAushadhiScreenState extends State<JanAushadhiScreen> with SingleTickerProviderStateMixin {
  late final GovernmentHealthService _service;
  late final TabController _tabController;

  bool _isLoadingMedicines = true;
  bool _isLoadingKendras = true;
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _kendras = [];

  final TextEditingController _medicineSearchCtrl = TextEditingController();
  final TextEditingController _kendraSearchCtrl = TextEditingController();

  String _selectedCategory = 'ALL';
  final List<String> _categories = ['ALL', 'PAIN_FEVER', 'DIABETES', 'HYPERTENSION', 'GASTRO', 'ANTIBIOTIC', 'CARDIAC'];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _tabController = TabController(length: 2, vsync: this);
    _loadMedicines();
    _loadKendras();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _medicineSearchCtrl.dispose();
    _kendraSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoadingMedicines = true);
    try {
      final list = await _service.getJanAushadhiMedicines(
        query: _medicineSearchCtrl.text.trim(),
        category: _selectedCategory,
      );
      if (mounted) {
        setState(() {
          _medicines = list;
          _isLoadingMedicines = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMedicines = false);
    }
  }

  Future<void> _loadKendras() async {
    setState(() => _isLoadingKendras = true);
    try {
      final list = await _service.getJanAushadhiKendras();
      if (mounted) {
        setState(() {
          _kendras = list;
          _isLoadingKendras = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingKendras = false);
    }
  }

  Future<void> _showAiExplanation(String drugName, String composition) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
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
                          'AI Dawa Samjhein ($drugName)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _service.explainMedicineGeneric(
                  medicineName: drugName,
                  composition: composition,
                  language: 'hi',
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primaryTeal),
                          SizedBox(height: 12),
                          Text('AI Clinical Vishleshan aur Sasti Dawa ki jankari nikaal rahe hain...', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(child: Text('Samasya aayi: ${snapshot.error ?? "No data"}'));
                  }

                  final data = snapshot.data!;
                  final hindiPlain = data['plainLanguageHindi']?.toString() ?? 'Generic medicine same salt and effectiveness provide karti hai.';
                  final dosage = data['dosageAndTimingHindi']?.toString() ?? 'Doctor ke nirdesh anusaar lein.';
                  final savings = data['savingsTip']?.toString() ?? 'PM Jan Aushadhi par 50%-80% ki bachat hoti hai.';

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dawa ka Kaam aur Prayog:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                              const SizedBox(height: 4),
                              Text(hindiPlain, style: const TextStyle(fontSize: 13, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Khurak aur Sahi Tarika:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                              const SizedBox(height: 4),
                              Text(dosage, style: const TextStyle(fontSize: 13, height: 1.4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.savings_outlined, color: Color(0xFFB45309), size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(savings, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                              ),
                            ],
                          ),
                        ),
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

  void _makeCall(String? phone) {
    if (phone == null || phone.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jan Aushadhi Kendra helpline: $phone'),
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
          'PM Jan Aushadhi (PMBJP)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
            Tab(icon: Icon(Icons.medication_rounded), text: 'Generic Dawa Catalog'),
            Tab(icon: Icon(Icons.storefront_rounded), text: 'Jan Aushadhi Kendras'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMedicinesTab(),
          _buildKendrasTab(),
        ],
      ),
    );
  }

  Widget _buildMedicinesTab() {
    return Column(
      children: [
        // Search & Category Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _medicineSearchCtrl,
                onSubmitted: (_) => _loadMedicines(),
                decoration: InputDecoration(
                  hintText: 'Search generic or branded medicine (e.g. Dolo, Paracetamol)...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryTeal),
                    onPressed: _loadMedicines,
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
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSel = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                      selected: isSel,
                      selectedColor: AppColors.primaryTeal,
                      backgroundColor: AppColors.scaffoldBg,
                      onSelected: (val) {
                        setState(() => _selectedCategory = cat);
                        _loadMedicines();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Medicines List
        Expanded(
          child: _isLoadingMedicines
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
              : _medicines.isEmpty
                  ? const Center(child: Text('Koi generic dawa nahi mili.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _medicines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) => _buildMedicineCard(_medicines[idx]),
                    ),
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> med) {
    final genericName = med['genericName']?.toString() ?? 'Generic Salt';
    final brand = med['brandedEquivalent']?.toString() ?? 'Market Brand';
    final composition = med['composition']?.toString() ?? '';
    final janPrice = (med['janAushadhiPrice'] as num?)?.toDouble() ?? 10.0;
    final marketPrice = (med['marketPrice'] as num?)?.toDouble() ?? 50.0;
    final savings = (((marketPrice - janPrice) / marketPrice) * 100).round();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  genericName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$savings% Bachat!',
                  style: const TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Branded Vikalp: $brand (${composition.isNotEmpty ? composition : genericName})',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PM Jan Aushadhi Mulya', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('₹${janPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryTeal)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Market Branded Mulya', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '₹${marketPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showAiExplanation(genericName, composition),
              icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryTeal),
              label: const Text('AI Dawa Guide (Hindi)', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKendrasTab() {
    final filtered = _kendras.where((k) {
      final q = _kendraSearchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = (k['name'] ?? '').toString().toLowerCase();
      final city = (k['city'] ?? '').toString().toLowerCase();
      final pin = (k['pincode'] ?? '').toString().toLowerCase();
      return name.contains(q) || city.contains(q) || pin.contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _kendraSearchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search Jan Aushadhi Kendra by city or pincode...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
              filled: true,
              fillColor: AppColors.scaffoldBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingKendras
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
              : filtered.isEmpty
                  ? const Center(child: Text('Koi Jan Aushadhi Kendra nahi mila.', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final k = filtered[idx];
                        final name = k['name']?.toString() ?? 'Jan Aushadhi Kendra';
                        final address = k['address']?.toString() ?? '';
                        final phone = k['contactPhone']?.toString() ?? '';
                        final hours = k['operatingHours']?.toString() ?? '9:00 AM - 9:00 PM';

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
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.storefront_rounded, color: Color(0xFFD97706), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Samay: $hours', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _makeCall(phone),
                                    icon: const Icon(Icons.call, size: 14),
                                    label: Text('Sampark Karein ($phone)', style: const TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryTeal,
                                      side: const BorderSide(color: AppColors.primaryTeal),
                                    ),
                                  ),
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
}
