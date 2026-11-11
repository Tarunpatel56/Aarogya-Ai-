import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/community_service.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  final CommunityService? communityService;

  const GovernmentSchemesScreen({super.key, this.communityService});

  @override
  State<GovernmentSchemesScreen> createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
  late final CommunityService _service;
  bool _isLoading = true;
  List<Map<String, dynamic>> _schemes = [];
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'HOSPITALIZATION',
    'SENIOR_CITIZEN',
    'MEDICINES',
    'MATERNITY',
    'FINANCIAL_AID'
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _fetchSchemes();
  }

  Future<void> _fetchSchemes() async {
    setState(() => _isLoading = true);
    final data = await _service.getGovernmentSchemes(
      category: _selectedCategory == 'ALL' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _schemes = data;
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
          'Govt Health Schemes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(
                      cat.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryTeal,
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCategory = cat);
                        _fetchSchemes();
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Main Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : _schemes.isEmpty
                      ? const Center(
                          child: Text(
                            'No schemes found for selected category.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _schemes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final scheme = _schemes[index];
                            return _buildSchemeCard(scheme);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard(Map<String, dynamic> scheme) {
    final title = scheme['title']?.toString() ?? 'Government Scheme';
    final dept = scheme['department']?.toString() ?? 'Government of India';
    final coverage = scheme['coverageAmount']?.toString() ?? 'Cashless Benefit';
    final summary = scheme['shortSummary']?.toString() ?? '';
    final helpline = scheme['helpline']?.toString() ?? '14555';
    final eligibility = (scheme['eligibility'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final benefits = (scheme['benefits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_rounded, color: AppColors.primaryTeal, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dept,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Coverage: $coverage',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 20),
          if (summary.isNotEmpty) ...[
            Text(
              summary,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
          ],

          // Eligibility
          if (eligibility.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Eligibility Criteria:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            ...eligibility.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Key Benefits
          if (benefits.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Benefits:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            ...benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('National Helpline: $helpline')),
                    );
                  },
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: Text('Helpline: $helpline', overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
