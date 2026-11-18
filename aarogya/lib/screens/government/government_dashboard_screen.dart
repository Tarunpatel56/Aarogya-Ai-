import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import '../../features/ayushman/views/ayushman_web_screen.dart';
import '../emergency/emergency_helplines_screen.dart';
import '../community/government_schemes_screen.dart';

class GovernmentDashboardScreen extends StatelessWidget {
  const GovernmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          Get.locale?.languageCode == 'hi' ? 'सरकारी स्वास्थ्य सेवाएं' : 'Government Health Services',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
                    Text(
                      Get.locale?.languageCode == 'hi'
                          ? 'राष्ट्रीय डिजिटल स्वास्थ्य मिशन\nएवं सरकारी योजना केंद्र'
                          : 'National Digital Health Mission\n& Government Schemes Hub',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Get.locale?.languageCode == 'hi'
                          ? 'आभा आईडी, ई-रक्तकोश, जन औषधि, पीएम-जय, यू-विन एवं समस्त सरकारी स्वास्थ्य सेवाएं एक स्थान पर।'
                          : 'ABHA ID, e-RaktKosh, Jan Aushadhi, PM-JAY, U-WIN, and official public healthcare services in one unified platform.',
                      style: const TextStyle(color: Color(0xFFE0F2F1), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                Get.locale?.languageCode == 'hi'
                    ? 'प्रमुख सरकारी स्वास्थ्य सुविधाएं'
                    : 'Core Government Services',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              // Emergency National Helplines Directory Card (1-Tap Dialing)
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'राष्ट्रीय आपातकालीन हेल्पलाइन निर्देशिका'
                    : 'National Emergency Helplines (1-Tap Dial)',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'पुलिस (112/100), एम्बुलेंस (108), महिला सुरक्षा (1091/181), अग्निशमन (101) एवं स्वास्थ्य सहायता।'
                    : 'Police (112/100), Ambulance (108), Women Safety (1091/181), Fire (101) & Health helplines.',
                icon: Icons.emergency_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEE2E2),
                badgeText: Get.locale?.languageCode == 'hi' ? '24x7 तत्काल कॉल' : '24x7 Direct Dial',
                badgeColor: Colors.red.shade50,
                badgeTextColor: Colors.red.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyHelplinesScreen())),
              ),
              const SizedBox(height: 12),

              // Government Schemes Directory & Official Portals
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'सरकारी योजनाएं एवं आधिकारिक वेब पोर्टल'
                    : 'Government Schemes & Official Portals',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'पीएम-जय, आभा, जन औषधि एवं राज्य स्वास्थ्य योजनाओं के लाभ, पात्रता व आधिकारिक वेब पोर्टल।'
                    : 'Explore all national health schemes, eligibility, benefits, and launch official web portals.',
                icon: Icons.policy_rounded,
                iconColor: const Color(0xFF4338CA),
                iconBg: const Color(0xFFEEF2FF),
                badgeText: Get.locale?.languageCode == 'hi' ? 'आधिकारिक पोर्टल' : 'Official Portals',
                badgeColor: Colors.indigo.shade50,
                badgeTextColor: Colors.indigo.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GovernmentSchemesScreen())),
              ),
              const SizedBox(height: 12),

              // 1. ABHA & ABDM Card
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'आयुष्मान भारत स्वास्थ्य खाता (ABHA)'
                    : 'Ayushman Bharat Health Account (ABHA)',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? '14 अंकों का आभा आईडी बनाएं, मेडिकल रिकॉर्ड लिंक करें एवं सहमति प्रबंधित करें।'
                    : 'Create 14-digit ABHA ID, link digital health records & manage consent.',
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
                title: Get.locale?.languageCode == 'hi'
                    ? 'ई-रक्तकोश रक्त बैंक निर्देशिका'
                    : 'e-RaktKosh Blood Bank Finder',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'सरकारी रक्त बैंकों में उपलब्ध रक्त समूह, घटक एवं आपातकालीन अनुरोध।'
                    : 'Live blood stock availability in government blood banks and emergency requests.',
                icon: Icons.bloodtype_rounded,
                iconColor: AppColors.sosRed,
                iconBg: AppColors.sosLightBg,
                badgeText: Get.locale?.languageCode == 'hi' ? 'सत्यापित स्टॉक' : 'Verified Stock',
                badgeColor: Colors.red.shade50,
                badgeTextColor: Colors.red.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodBankFinderScreen())),
              ),
              const SizedBox(height: 12),

              // 3. PM Jan Aushadhi (PMBJP)
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'प्रधानमंत्री जन औषधि केंद्र (PMBJP)'
                    : 'PM Jan Aushadhi Kendra (PMBJP)',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'किफायती जेनेरिक दवाइयां (70%+ बचत) एवं निकटतम केंद्र खोजें।'
                    : 'Affordable generic medicines with up to 80% savings and nearby store locator.',
                icon: Icons.medication_rounded,
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
                badgeText: Get.locale?.languageCode == 'hi' ? '50-80% बचत' : '50-80% Savings',
                badgeColor: Colors.blue.shade50,
                badgeTextColor: Colors.blue.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JanAushadhiScreen())),
              ),
              const SizedBox(height: 12),

              // 4. PM-JAY Ayushman Bharat
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'आयुष्मान भारत (PM-JAY)'
                    : 'Ayushman Bharat (PM-JAY)',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'प्रति परिवार प्रति वर्ष ₹5 लाख तक निःशुल्क उपचार एवं पात्रता जांच।'
                    : 'Free cashless healthcare up to ₹5 Lakhs per family per year and eligibility check.',
                icon: Icons.shield_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                badgeText: Get.locale?.languageCode == 'hi' ? '₹5 लाख बीमा' : '₹5L Family Cover',
                badgeColor: Colors.amber.shade50,
                badgeTextColor: Colors.amber.shade900,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PmjayAyushmanScreen())),
              ),
              const SizedBox(height: 12),

              // 4b. Ayushman Card Download (NHA Official Portal)
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'आयुष्मान कार्ड डाउनलोड'
                    : 'Ayushman Card Download',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'एनएचए आधिकारिक पोर्टल से आयुष्मान कार्ड पीडीएफ डाउनलोड करें एवं देखें।'
                    : 'Download official Ayushman Bharat card PDF from NHA portal and view in-app.',
                icon: Icons.download_for_offline_rounded,
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFEDE9FE),
                badgeText: 'Official NHA Portal',
                badgeColor: Colors.purple.shade50,
                badgeTextColor: Colors.purple.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AyushmanWebScreen())),
              ),
              const SizedBox(height: 12),

              // 5. OPD Scan & Share
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'ओपीडी स्कैन एवं शेयर'
                    : 'ABDM OPD Scan & Share',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'अस्पताल ओपीडी काउंटर पर कतार में लगे बिना तुरंत डिजिटल टोकन प्राप्त करें।'
                    : 'Instant digital OPD token registration at hospital counters without queues.',
                icon: Icons.qr_code_scanner_rounded,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFD1FAE5),
                badgeText: Get.locale?.languageCode == 'hi' ? 'तुरंत टोकन' : 'Instant Token',
                badgeColor: const Color(0xFFECFDF5),
                badgeTextColor: const Color(0xFF065F46),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OpdScanShareScreen())),
              ),
              const SizedBox(height: 12),

              // 6. Maa & Shishu (MCH / U-WIN)
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'मातृ एवं शिशु स्वास्थ्य सुरक्षा (U-WIN)'
                    : 'Maternal & Child Healthcare (U-WIN)',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'गर्भावस्था निगरानी, उच्च जोखिम चेतावनी एवं बच्चों का सार्वभौमिक टीकाकरण।'
                    : 'Pregnancy tracking, high-risk alerts and comprehensive universal immunization.',
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
                title: Get.locale?.languageCode == 'hi'
                    ? 'राष्ट्रीय स्वास्थ्य निर्देशिका (HFR एवं HPR)'
                    : 'Health Registries (HFR & HPR)',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'राष्ट्रीय प्रमाणित अस्पताल एवं एनएमसी सत्यापित चिकित्सक खोजें।'
                    : 'Search certified national healthcare facilities and verified medical practitioners.',
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFDBEAFE),
                badgeText: Get.locale?.languageCode == 'hi' ? 'राष्ट्रीय निर्देशिका' : 'National Directory',
                badgeColor: Colors.indigo.shade50,
                badgeTextColor: Colors.indigo.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthRegistryScreen())),
              ),

              const SizedBox(height: 12),

              // 9. Nearby Healthcare Places (Google Places API New)
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'निकटतम स्वास्थ्य केंद्र एवं औषधि स्टोर'
                    : 'Nearby Healthcare & Pharmacy Finder',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'निकटतम अस्पताल, पैथोलॉजी लैब, क्लिनिक एवं मेडिकल स्टोर खोजें।'
                    : 'Locate nearby hospitals, diagnostic labs, clinics and pharmacies.',
                icon: Icons.place_rounded,
                iconColor: const Color(0xFF0F766E),
                iconBg: const Color(0xFFCCFBF1),
                badgeText: 'Google Places',
                badgeColor: Colors.teal.shade50,
                badgeTextColor: Colors.teal.shade800,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyHealthcarePlacesScreen())),
              ),
              const SizedBox(height: 12),

              // 10. Family Health Management & Isolated Profiles
              _buildServiceCard(
                context,
                title: Get.locale?.languageCode == 'hi'
                    ? 'पारिवारिक स्वास्थ्य प्रबंधन'
                    : 'Family Health Management',
                subtitle: Get.locale?.languageCode == 'hi'
                    ? 'परिवार के सदस्यों के स्वास्थ्य प्रोफ़ाइल, आभा आईडी एवं रिकॉर्ड का सुरक्षित प्रबंधन।'
                    : 'Manage independent health profiles, ABHA IDs, prescriptions and records for dependents.',
                icon: Icons.people_alt_rounded,
                iconColor: const Color(0xFFB45309),
                iconBg: const Color(0xFFFEF3C7),
                badgeText: Get.locale?.languageCode == 'hi' ? 'सुरक्षित प्रबंधन' : 'Isolated Profiles',
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
