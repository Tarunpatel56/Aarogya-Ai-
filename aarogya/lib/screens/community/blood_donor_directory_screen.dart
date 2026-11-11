import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/community_service.dart';

class BloodDonorDirectoryScreen extends StatefulWidget {
  final CommunityService? communityService;

  const BloodDonorDirectoryScreen({super.key, this.communityService});

  @override
  State<BloodDonorDirectoryScreen> createState() => _BloodDonorDirectoryScreenState();
}

class _BloodDonorDirectoryScreenState extends State<BloodDonorDirectoryScreen> {
  late final CommunityService _service;
  bool _isLoading = true;
  List<Map<String, dynamic>> _donors = [];
  String _selectedGroup = 'ALL';
  final TextEditingController _cityController = TextEditingController();

  final List<String> _bloodGroups = ['ALL', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _fetchDonors();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonors() async {
    setState(() => _isLoading = true);
    final data = await _service.getBloodDonors(
      bloodGroup: _selectedGroup == 'ALL' ? null : _selectedGroup,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _donors = data;
        _isLoading = false;
      });
    }
  }

  void _openRegisterDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    String group = 'O+';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Register as Voluntary Donor',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: group,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => group = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: cityCtrl,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Phone *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || cityCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields')),
                        );
                        return;
                      }

                      await _service.registerBloodDonor(
                        fullName: nameCtrl.text.trim(),
                        bloodGroup: group,
                        city: cityCtrl.text.trim(),
                        contactPhone: phoneCtrl.text.trim(),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _fetchDonors();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Thank you! You are now registered as a life-saving blood donor.'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      }
                    },
                    child: const Text('Confirm Registration', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
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
          'Blood Donor Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton.icon(
            onPressed: _openRegisterDialog,
            icon: const Icon(Icons.favorite_rounded, color: Color(0xFFDC2626), size: 18),
            label: const Text(
              'Join',
              style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Box
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            hintText: 'Search city (e.g. Indore, Bhopal)',
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          onSubmitted: (_) => _fetchDonors(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _fetchDonors,
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _bloodGroups.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final bg = _bloodGroups[idx];
                        final isSelected = bg == _selectedGroup;
                        return FilterChip(
                          label: Text(
                            bg,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFFDC2626),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFDC2626),
                          backgroundColor: const Color(0xFFFEF2F2),
                          onSelected: (val) {
                            setState(() => _selectedGroup = bg);
                            _fetchDonors();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Donor List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : _donors.isEmpty
                      ? const Center(
                          child: Text(
                            'No voluntary donors matching criteria.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _donors.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final donor = _donors[index];
                            final name = donor['fullName']?.toString() ?? 'Anonymous Donor';
                            final group = donor['bloodGroup']?.toString() ?? 'O+';
                            final city = donor['city']?.toString() ?? '';
                            final phone = donor['contactPhone']?.toString() ?? '';
                            final isAvailable = donor['isAvailable'] == true;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        group,
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified, color: AppColors.primaryTeal, size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '📍 $city • ${isAvailable ? "Available to Donate" : "Cooldown"}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isAvailable ? const Color(0xFF16A34A) : AppColors.textSecondary,
                                            fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '📞 $phone',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFFEE2E2),
                                      foregroundColor: const Color(0xFFDC2626),
                                    ),
                                    icon: const Icon(Icons.phone),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Contacting $name at $phone')),
                                      );
                                    },
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
