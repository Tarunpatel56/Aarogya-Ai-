import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/community_service.dart';

class HealthCampsScreen extends StatefulWidget {
  final CommunityService? communityService;

  const HealthCampsScreen({super.key, this.communityService});

  @override
  State<HealthCampsScreen> createState() => _HealthCampsScreenState();
}

class _HealthCampsScreenState extends State<HealthCampsScreen> {
  late final CommunityService _service;
  bool _isLoading = true;
  List<Map<String, dynamic>> _camps = [];
  String _selectedCategory = 'ALL';
  final TextEditingController _cityController = TextEditingController();

  final List<String> _categories = [
    'ALL',
    'GENERAL_CHECKUP',
    'MATERNITY',
    'IMMUNIZATION',
    'BLOOD_DONATION',
    'EYE_SCREENING',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _fetchCamps();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchCamps() async {
    setState(() => _isLoading = true);
    final data = await _service.getHealthCamps(
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      category: _selectedCategory == 'ALL' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _camps = data;
        _isLoading = false;
      });
    }
  }

  void _openPostCampDialog() {
    final titleCtrl = TextEditingController();
    final organizerCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: 'Next Sunday');
    final timingsCtrl = TextEditingController(text: '09:00 AM - 04:00 PM');
    final phoneCtrl = TextEditingController();
    final servicesCtrl = TextEditingController(text: 'Free Blood Sugar, BP Checkup, Doctor Consultation');
    String category = 'GENERAL_CHECKUP';
    bool isFree = true;

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
                      'Announce a Health Camp',
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
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Camp Title * (e.g. Free Eye Screening Camp)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: organizerCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Organizer / Hospital *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: _categories.where((c) => c != 'ALL').map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: venueCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Venue / Address *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Date *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: timingsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Timings',
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
                    labelText: 'Contact Phone / Helpline *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: servicesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Services Offered (Comma separated)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('100% Free Public Camp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('No registration fee for patients', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: isFree,
                  activeThumbColor: AppColors.primaryTeal,
                  onChanged: (val) => setModalState(() => isFree = val),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty || venueCtrl.text.trim().isEmpty || cityCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields (*) to post camp')),
                        );
                        return;
                      }

                      final services = servicesCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                      await _service.submitHealthCamp(
                        title: titleCtrl.text.trim(),
                        organizer: organizerCtrl.text.trim().isEmpty ? 'Aarogya Partner' : organizerCtrl.text.trim(),
                        category: category,
                        venue: venueCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        startDate: dateCtrl.text.trim(),
                        timings: timingsCtrl.text.trim(),
                        servicesOffered: services.isEmpty ? ['Free Health Screening'] : services,
                        contactPhone: phoneCtrl.text.trim(),
                        isFree: isFree,
                        sourceType: 'DOCTOR_PARTNER',
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        _fetchCamps();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Health Camp successfully posted to community feed!'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      }
                    },
                    child: const Text('Publish Health Camp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(String? sourceType) {
    if (sourceType == 'GOVT_RECURRING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.account_balance_rounded, size: 12, color: Color(0xFF15803D)),
            SizedBox(width: 4),
            Text(
              'Govt Recurring Camp',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
            ),
          ],
        ),
      );
    } else if (sourceType == 'DOCTOR_PARTNER') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.medical_services_rounded, size: 12, color: Color(0xFF1D4ED8)),
            SizedBox(width: 4),
            Text(
              'Doctor / Hospital Partner',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified_rounded, size: 12, color: Color(0xFFB45309)),
          SizedBox(width: 4),
          Text(
            'Admin Verified',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Community Health Camps',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton.icon(
            onPressed: _openPostCampDialog,
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryTeal, size: 18),
            label: const Text(
              'Post Camp',
              style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and Category Filter
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
                            hintText: 'Filter by city (e.g. Indore, Bhopal)',
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          onSubmitted: (_) => _fetchCamps(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _fetchCamps,
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = cat == _selectedCategory;
                        return FilterChip(
                          label: Text(
                            cat.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryTeal,
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (val) {
                            setState(() => _selectedCategory = cat);
                            _fetchCamps();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Camps List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : _camps.isEmpty
                      ? const Center(
                          child: Text(
                            'No upcoming health camps scheduled for this selection.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _camps.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final camp = _camps[index];
                            final title = camp['title']?.toString() ?? 'Community Health Camp';
                            final organizer = camp['organizer']?.toString() ?? 'Health Foundation';
                            final venue = camp['venue']?.toString() ?? '';
                            final city = camp['city']?.toString() ?? '';
                            final startDate = camp['startDate']?.toString() ?? '';
                            final timings = camp['timings']?.toString() ?? '09:00 AM - 04:00 PM';
                            final phone = camp['contactPhone']?.toString() ?? '';
                            final isFree = camp['isFree'] != false;
                            final sourceType = camp['sourceType']?.toString() ?? 'ADMIN_VERIFIED';
                            final services = (camp['servicesOffered'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [];

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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSourceBadge(sourceType),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isFree ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isFree ? '100% FREE' : 'SUBSIDIZED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isFree ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Organized by: $organizer',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.primaryTeal),
                                      const SizedBox(width: 4),
                                      Text(
                                        startDate,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        timings,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '$venue, $city',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (services.isNotEmpty) ...[
                                    const Divider(height: 20),
                                    const Text(
                                      'Services Available:',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 6),
                                    ...services.map(
                                      (s) => Padding(
                                        padding: const EdgeInsets.only(bottom: 3),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_outline, color: AppColors.primaryTeal, size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                s,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Calling Camp Helpline: $phone')),
                                            );
                                          },
                                          icon: const Icon(Icons.phone, size: 16),
                                          label: Text('Call Helpline: $phone', overflow: TextOverflow.ellipsis),
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
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
