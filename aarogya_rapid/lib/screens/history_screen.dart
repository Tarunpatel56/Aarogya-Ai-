import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  final List<EmergencyRequest> completedTrips;

  const HistoryScreen({
    super.key,
    this.completedTrips = const [],
  });

  @override
  Widget build(BuildContext context) {
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
              style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Aarogya Rapid EMS Unit #KA-01-EA-108',
              style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: SanctuaryColors.hairlineBorder),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Telemetry Stats Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'COMPLETED',
                  value: '${completedTrips.length}',
                  subtitle: 'Transits logged',
                  icon: Icons.done_all,
                  color: SanctuaryColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: 'DUTY STATUS',
                  value: 'Active',
                  subtitle: 'ALS / BLS Ready',
                  icon: Icons.shield_outlined,
                  color: SanctuaryColors.optimalGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  title: 'NETWORK',
                  value: 'Connected',
                  subtitle: 'Aarogya Cloud',
                  icon: Icons.cloud_done_outlined,
                  color: const Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Emergency Dispatches Log',
            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          if (completedTrips.isEmpty) ...[
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
                      Icons.assignment_outlined,
                      size: 36,
                      color: SanctuaryColors.deepSlateNavy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No Past Emergency Trips Recorded',
                    style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Completed patient transits and hospital handover reports will be archived here with clinical audit trails.',
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
            ...completedTrips.map((req) => _buildCompletedTripCard(req)),
          ],
          const SizedBox(height: 24),
        ],
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
        borderRadius: SanctuaryRadius.rMd,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: SanctuaryTypography.labelSm(color: SanctuaryColors.textMuted).copyWith(fontSize: 9),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: SanctuaryTypography.metricDisplay(color: SanctuaryColors.deepSlateNavy).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTripCard(EmergencyRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.id,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanctuaryColors.primaryTeal),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SanctuaryColors.optimalGreenBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Handover Complete', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: SanctuaryColors.optimalGreen)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${req.patientName} • ${req.reportedEmergency}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SanctuaryColors.deepSlateNavy),
          ),
          const SizedBox(height: 3),
          Text(
            'Handed over to ${req.receivingHospital} (${req.hospitalBay})',
            style: const TextStyle(fontSize: 11.5, color: SanctuaryColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
