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

  @override
  void initState() {
    super.initState();
    _service = widget.communityService ?? CommunityService();
    _fetchCamps();
  }

  Future<void> _fetchCamps() async {
    setState(() => _isLoading = true);
    final data = await _service.getHealthCamps();
    if (mounted) {
      setState(() {
        _camps = data;
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
          'Community Health Camps',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
            : _camps.isEmpty
                ? const Center(
                    child: Text(
                      'No upcoming health camps scheduled.',
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isFree ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isFree ? '100% FREE CAMP' : 'SUBSIDIZED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isFree ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.event_available_rounded, color: AppColors.primaryTeal, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  startDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryTeal,
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  timings,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
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
                                        SnackBar(content: Text('Helpline for $title: $phone')),
                                      );
                                    },
                                    icon: const Icon(Icons.phone, size: 16),
                                    label: Text('Call Organizer: $phone', overflow: TextOverflow.ellipsis),
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
    );
  }
}
