import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/community_service.dart';

class VaccinationTrackerScreen extends StatefulWidget {
  final CommunityService? communityService;

  const VaccinationTrackerScreen({super.key, this.communityService});

  @override
  State<VaccinationTrackerScreen> createState() => _VaccinationTrackerScreenState();
}

class _VaccinationTrackerScreenState extends State<VaccinationTrackerScreen> {
  late final CommunityService _service;
  bool _isLoading = true;
  List<Map<String, dynamic>> _vaccines = [];
  final Set<String> _completedDoses = {'vac-1', 'vac-2', 'vac-3', 'vac-4'};
  String _selectedCategory = 'ALL';

  final List<String> _categories = ['ALL', 'INFANT', 'CHILD', 'ADOLESCENT', 'ADULT'];

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _fetchVaccines();
  }

  Future<void> _fetchVaccines() async {
    setState(() => _isLoading = true);
    final data = await _service.getVaccinations(
      category: _selectedCategory == 'ALL' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _vaccines = data;
        _isLoading = false;
      });
    }
  }

  void _toggleDose(String id) {
    setState(() {
      if (_completedDoses.contains(id)) {
        _completedDoses.remove(id);
      } else {
        _completedDoses.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Immunization & Vaccines',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Tabs
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
                      cat,
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
                        _fetchVaccines();
                      }
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Progress Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'National Universal Immunization',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_completedDoses.length} of ${_vaccines.length} standard doses recorded',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Vaccine List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : _vaccines.isEmpty
                      ? const Center(
                          child: Text(
                            'No vaccination records found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _vaccines.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final vac = _vaccines[index];
                            final id = vac['id']?.toString() ?? 'vac-$index';
                            final doseName = vac['doseName']?.toString() ?? 'Vaccine Dose';
                            final age = vac['ageRecommended']?.toString() ?? '';
                            final protection = vac['protectionAgainst']?.toString() ?? '';
                            final route = vac['route']?.toString() ?? '';
                            final isCompleted = _completedDoses.contains(id);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCompleted ? const Color(0xFFBBF7D0) : AppColors.cardBorder,
                                ),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                      size: 26,
                                    ),
                                    onPressed: () => _toggleDose(id),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doseName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isCompleted ? const Color(0xFF15803D) : AppColors.textPrimary,
                                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                age,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Shields against: $protection',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Administration: $route',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
}
