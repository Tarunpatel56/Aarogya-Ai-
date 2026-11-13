import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'abha_management_screen.dart';
import 'blood_bank_finder_screen.dart';
import 'jan_aushadhi_screen.dart';
import 'pmjay_ayushman_screen.dart';
import 'health_registry_screen.dart';
import 'opd_scan_share_screen.dart';
import 'maternal_child_screen.dart';
import 'nearby_healthcare_places_screen.dart';
import '../profile/family_health_screen.dart';

class GovernmentDashboardScreen extends StatelessWidget {
  const GovernmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Government Health Services',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner with National Health Portal Aesthetic
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF004D40).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'GOVERNMENT OF INDIA',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.account_balance_rounded, color: Colors.white70, size: 24),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'National Digital Health Mission\n& Sarkari Yojana Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ABHA ID, e-RaktKosh, Jan Aushadhi, PM-JAY, U-WIN aur sabhi sarkari swasthya suvidhayein ek sthan par.',
                      style: TextStyle(color: Color(0xFFE0F2F1), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Pramukh Sarkari Suvidhayein (Core Services)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              // 1. ABHA & ABDM Card
              _buildServiceCard(
                context,
                title: 'Ayushman Bharat Health Account (ABHA)',
                subtitle: '14-digit ABHA ID banayein, medical records link karein aur consent manage karein.',
                icon: Icons.health_and_safety_rounded,
                iconColor: const Color(0xFF00796B),
                iconBg: const Color(0xFFE0F2F1),
                badgeText: 'ABDM M1/M2/M3',
                badgeColor: Colors.teal.shade50,
                badgeTextColor: Colors.teal.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbhaManagementScreen())),
              ),
              const SizedBox(height: 12),

              // 2. e-RaktKosh Blood Bank Finder
              _buildServiceCard(
                context,
                title: 'e-RaktKosh Blood Bank Finder',
                subtitle: 'Sarkari blood banks me live blood stock, components aur emergency SOS anurodh.',
                icon: Icons.bloodtype_rounded,
                iconColor: AppColors.sosRed,
                iconBg: AppColors.sosLightBg,
                badgeText: 'Verified Stock',
                badgeColor: Colors.red.shade50,
                badgeTextColor: Colors.red.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodBankFinderScreen())),
              ),
              const SizedBox(height: 12),

              // 3. PM Jan Aushadhi (PMBJP)
              _buildServiceCard(
                context,
                title: 'PM Jan Aushadhi Kendra (PMBJP)',
                subtitle: 'Sasti Generic Dawaiyan (70%+ Bachat) aur nazdeeki Jan Aushadhi Kendra locator.',
                icon: Icons.medication_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
                badgeText: '50-80% Bachat',
                badgeColor: Colors.blue.shade50,
                badgeTextColor: Colors.blue.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JanAushadhiScreen())),
              ),
              const SizedBox(height: 12),

              // 4. PM-JAY Ayushman Bharat
              _buildServiceCard(
                context,
                title: 'Ayushman Bharat (PM-JAY)',
                subtitle: '₹5 Lakhs muft cashless ilaaj, patrata jaanch (Eligibility) aur 1,949+ packages.',
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                badgeText: '₹5L Family Cover',
                badgeColor: Colors.amber.shade50,
                badgeTextColor: Colors.amber.shade900,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PmjayAyushmanScreen())),
              ),
              const SizedBox(height: 12),

              // 5. OPD Scan & Share
              _buildServiceCard(
                context,
                title: 'ABDM OPD Scan & Share',
                subtitle: 'Hospital OPD counter par bina line me lage instant digital token prapt karein.',
                icon: Icons.qr_code_scanner_rounded,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFD1FAE5),
                badgeText: 'Instant Token',
                badgeColor: const Color(0xFFECFDF5),
                badgeTextColor: const Color(0xFF065F46),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpdScanShareScreen())),
              ),
              const SizedBox(height: 12),

              // 6. Maa & Shishu (MCH / U-WIN)
              _buildServiceCard(
                context,
                title: 'Maa & Shishu Suraksha (MCH / U-WIN)',
                subtitle: 'Garbhavastha tracking, PMSMA high-risk alerts aur bachho ka U-WIN teekakaran.',
                icon: Icons.pregnant_woman_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFEDE9FE),
                badgeText: 'U-WIN Immunization',
                badgeColor: Colors.purple.shade50,
                badgeTextColor: Colors.purple.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaternalChildScreen())),
              ),
              const SizedBox(height: 12),

              // 7. National Health Registries (HFR & HPR)
              _buildServiceCard(
                context,
                title: 'Health Registries (HFR & HPR)',
                subtitle: 'Rashtriya certified hospital aur NMC verified doctor direct khojein.',
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFDBEAFE),
                badgeText: 'National Directory',
                badgeColor: Colors.indigo.shade50,
                badgeTextColor: Colors.indigo.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthRegistryScreen())),
              ),

              const SizedBox(height: 12),

              // 9. Nearby Healthcare Places (Google Places API New)
              _buildServiceCard(
                context,
                title: 'Nearby Healthcare & Pharmacy Finder',
                subtitle: 'Google Maps Places API dwara nazdeeki hospital, lab, clinic aur medical store khojein.',
                icon: Icons.place_rounded,
                iconColor: const Color(0xFF0F766E),
                iconBg: const Color(0xFFCCFBF1),
                badgeText: 'Google Places API',
                badgeColor: Colors.teal.shade50,
                badgeTextColor: Colors.teal.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyHealthcarePlacesScreen())),
              ),
              const SizedBox(height: 12),

              // 10. Family Health Management & Isolated Profiles
              _buildServiceCard(
                context,
                title: 'Parivaar Swasthya Prabandhan (Family Health)',
                subtitle: 'Ghar ke sadasyo ke alag-alag health profile, ABHA, prescriptions aur records manage karein.',
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFFB45309),
                iconBg: const Color(0xFFFEF3C7),
                badgeText: 'Consent Isolated',
                badgeColor: Colors.amber.shade50,
                badgeTextColor: Colors.amber.shade900,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyHealthScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
