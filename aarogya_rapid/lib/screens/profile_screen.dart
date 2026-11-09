import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      appBar: AppBar(
        backgroundColor: SanctuaryColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'EMS Unit Terminal & Profile',
          style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(fontWeight: FontWeight.w800),
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
          // Paramedic Medic Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SanctuaryColors.surfaceContainerLowest,
              borderRadius: SanctuaryRadius.rLg,
              border: Border.all(color: SanctuaryColors.hairlineBorder),
              boxShadow: SanctuaryColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [SanctuaryColors.primaryTeal, SanctuaryColors.primaryDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'VN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                          Text(
                            'Dr. V. Nambiar',
                            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: SanctuaryColors.optimalGreenBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('ALS Certified', style: TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 9.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Lead Paramedic & Emergency Flight Medic',
                        style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 11.5),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Reg #KMC-89410 • ABDM Practitioner Validated',
                        style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Unit & Vehicle Details
          _buildSectionHeader('Unit & Equipment Telemetry'),
          Container(
            decoration: BoxDecoration(
              color: SanctuaryColors.surfaceContainerLowest,
              borderRadius: SanctuaryRadius.rLg,
              border: Border.all(color: SanctuaryColors.hairlineBorder),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.airport_shuttle,
                  title: 'Vehicle Identifier',
                  value: 'KA-03-HA-1102 (ALS Type D)',
                ),
                const Divider(height: 1, color: SanctuaryColors.hairlineBorder),
                _buildInfoTile(
                  icon: Icons.medical_services_outlined,
                  title: 'Zoll X-Series Monitor / Defib',
                  value: 'Calibrated • 100% Ready',
                ),
                const Divider(height: 1, color: SanctuaryColors.hairlineBorder),
                _buildInfoTile(
                  icon: Icons.air,
                  title: 'Medical Oxygen Reserves',
                  value: '2 x 10L Cylinders (95% PSI)',
                ),
                const Divider(height: 1, color: SanctuaryColors.hairlineBorder),
                _buildInfoTile(
                  icon: Icons.radio,
                  title: 'Emergency Radio Frequency',
                  value: 'NavIC Intercom Ch. 4 (Apollo ER)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pilot & Co-Responder Info
          _buildSectionHeader('Assigned Crew Response Team'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SanctuaryColors.surfaceContainerLowest,
              borderRadius: SanctuaryRadius.rLg,
              border: Border.all(color: SanctuaryColors.hairlineBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.drive_eta, color: SanctuaryColors.primaryTeal, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Pilot & Heavy EMT Driver', style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('K. R. Chettiar', style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontWeight: FontWeight.bold, fontSize: 13.5)),
                      Text('Green Corridor Pilot Certified • 12 Yrs EMS Exp', style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // System Security & Compliance
          _buildSectionHeader('Regulatory Compliance & ABDM Sync'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: SanctuaryRadius.rLg,
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: const [
                Icon(Icons.security, color: SanctuaryColors.optimalGreen, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ABDM Health Information Provider (HIP) & Health Information User (HIU) certified node. Zero patient data cached locally without biometric auth.',
                    style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: SanctuaryTypography.labelSm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11, letterSpacing: 0.4),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SanctuaryColors.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Text(value, style: const TextStyle(color: SanctuaryColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
