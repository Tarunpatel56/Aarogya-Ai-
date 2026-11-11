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
  final TextEditingController _searchCtrl = TextEditingController(text: 'Paracetamol');
  bool _isLoading = false;
  Map<String, dynamic>? _safetyInfo;

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

  Future<void> _searchMedicine() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

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
          'Medicine Safety Guide',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                        hintText: 'Enter medicine (e.g. Metformin, Amoxicillin)',
                        prefixIcon: const Icon(Icons.medication_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      onSubmitted: (_) => _searchMedicine(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: _searchMedicine,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  ),
                )
              else if (_safetyInfo != null) ...[
                // Main Info Card
                Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.healing_rounded, color: Color(0xFF0284C7), size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _safetyInfo!['drugName']?.toString() ?? 'Medicine',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Generic: ${_safetyInfo!['genericName'] ?? ""}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Class: ${_safetyInfo!['therapeuticClass'] ?? ""}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Indications
                      const Text(
                        'Primary Indications:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      ...((_safetyInfo!['standardIndications'] as List<dynamic>?)?.map((i) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 14),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        i.toString(),
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )) ??
                          []),
                      const SizedBox(height: 14),

                      // Severe Warnings
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Critical Safety Warnings:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...((_safetyInfo!['severeWarnings'] as List<dynamic>?)?.map((w) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '• ${w.toString()}',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)),
                                      ),
                                    )) ??
                                []),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Side Effects & Alcohol
                      _buildSafetyRow('Common Side Effects', (_safetyInfo!['commonSideEffects'] as List<dynamic>?)?.join(', ') ?? 'Mild nausea'),
                      const SizedBox(height: 8),
                      _buildSafetyRow('Alcohol Interaction', _safetyInfo!['alcoholInteraction']?.toString() ?? 'Avoid concurrent alcohol'),
                      const SizedBox(height: 8),
                      _buildSafetyRow('Food & Timing Instructions', _safetyInfo!['foodInstructions']?.toString() ?? 'Take with water'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Disclaimer Card
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
                          'Always consult a qualified doctor or licensed pharmacist before initiating, altering, or terminating any drug therapy.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyRow(String title, String details) {
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
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

