import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/ambulance_dispatch_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final List<EmergencyRequest> completedTrips;

  const HistoryScreen({
    super.key,
    this.completedTrips = const [],
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dispatchService = AmbulanceDispatchService();
  List<EmergencyRequest> _dbTrips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final assigned = await _dispatchService.getAssignedTrips();
    final completed = assigned.where((t) => t.status == 'COMPLETED' || t.status == 'REACHED_HOSPITAL').toList();
    if (mounted) {
      setState(() {
        _dbTrips = completed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine local completed with database completed without duplicates
    final allMap = <String, EmergencyRequest>{};
    for (final t in widget.completedTrips) {
      allMap[t.id] = t;
    }
    for (final t in _dbTrips) {
      allMap[t.id] = t;
    }
    final trips = allMap.values.toList();

    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      appBar: AppBar(
        backgroundColor: SanctuaryColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip & Handover History',
              style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Verified Log of Completed Emergency Transits',
              style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: SanctuaryColors.hairlineBorder),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SanctuaryColors.primaryTeal))
          : RefreshIndicator(
              onRefresh: _fetchHistory,
              color: SanctuaryColors.primaryTeal,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // Telemetry Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'COMPLETED',
                          value: '${trips.length}',
                          subtitle: 'Live verified',
                          icon: Icons.done_all,
                          color: SanctuaryColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'DUTY READY',
                          value: 'Active',
                          subtitle: 'ALS Telemetry',
                          icon: Icons.shield_outlined,
                          color: SanctuaryColors.optimalGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'NETWORK',
                          value: 'Online',
                          subtitle: 'Socket.IO Hub',
                          icon: Icons.cloud_done_outlined,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Text(
                        'Completed Emergency Dispatches',
                        style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${trips.length} Total',
                        style: const TextStyle(fontSize: 11.5, color: SanctuaryColors.textMuted, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (trips.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                      decoration: BoxDecoration(
                        color: SanctuaryColors.surfaceContainerLowest,
                        borderRadius: SanctuaryRadius.rLg,
                        border: Border.all(color: SanctuaryColors.hairlineBorder),
                        boxShadow: SanctuaryColors.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_toggle_off_rounded,
                              size: 40,
                              color: SanctuaryColors.deepSlateNavy,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Completed Transits Logged',
                            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Completed emergency ambulance runs, hospital trauma handovers, and patient transport logs will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: SanctuaryColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...trips.map((req) => _buildTripHistoryCard(req)),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                title,
                style: SanctuaryTypography.labelSm(color: SanctuaryColors.textMuted).copyWith(fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            subtitle,
            style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHistoryCard(EmergencyRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SanctuaryColors.optimalGreenBg,
                  borderRadius: SanctuaryRadius.rFull,
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '#${req.id}',
                  style: const TextStyle(fontSize: 11, color: SanctuaryColors.textMuted, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${req.createdAt.hour.toString().padLeft(2, '0')}:${req.createdAt.minute.toString().padLeft(2, '0')} IST',
                style: const TextStyle(fontSize: 11, color: SanctuaryColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${req.patientName} (${req.patientGender}, ${req.patientAge}y)',
            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Emergency: ${req.reportedEmergency}',
            style: const TextStyle(fontSize: 12, color: SanctuaryColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.local_hospital_outlined, size: 14, color: SanctuaryColors.primaryTeal),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Handed over at ${req.receivingHospital}',
                  style: const TextStyle(fontSize: 11.5, color: SanctuaryColors.primaryTeal, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
