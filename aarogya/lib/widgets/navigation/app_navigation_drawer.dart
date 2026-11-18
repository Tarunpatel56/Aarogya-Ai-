import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../core/utils/phone_launcher_util.dart';
import '../../screens/emergency/emergency_helplines_screen.dart';
import '../../screens/government/government_dashboard_screen.dart';
import '../../screens/government/pmjay_ayushman_screen.dart';
import '../../screens/government/abha_management_screen.dart';
import '../../screens/government/blood_bank_finder_screen.dart';
import '../../screens/government/jan_aushadhi_screen.dart';
import '../../screens/government/opd_scan_share_screen.dart';
import '../../screens/government/maternal_child_screen.dart';
import '../../screens/hospitals/nearby_hospitals_screen.dart';
import '../../screens/physio/physiotherapy_home_screen.dart';
import '../../screens/prescriptions/patient_prescriptions_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/auth/patient_login_screen.dart';

class AppNavigationDrawer extends StatelessWidget {
  final AuthService? authService;

  const AppNavigationDrawer({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    final isHi = Get.locale?.languageCode == 'hi';
    final user = authService?.currentUser;
    final profile = authService?.currentProfile;
    final displayName = profile?.fullName ?? (user != null ? user.email.split('@').first : (isHi ? 'आरोग्य नागरिक' : 'Aarogya Citizen'));
    final abhaId = profile?.abhaId ?? '91-4521-8890';

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header with Patient Profile
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF042F2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(Icons.person_rounded, size: 34, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? user?.phone ?? 'citizen@aarogya.ai',
                            style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ABHA Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF2DD4BF), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'ABHA: $abhaId',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // EMERGENCY SECTION (Prominent Red)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: ListTile(
              leading: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 28),
              title: Text(
                isHi ? 'आपातकालीन हेल्पलाइन (112 / 108 / 100 / 1091)' : 'Emergency Helplines (112 / 108 / 100 / 1091)',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
              subtitle: Text(
                isHi ? 'पुलिस, एम्बुलेंस, महिला व बाल सुरक्षा तत्काल कॉल' : 'Direct 1-tap call to Police, Medical, Women Safety',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
              ),
              trailing: const Icon(Icons.call_rounded, color: Color(0xFFDC2626), size: 20),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const EmergencyHelplinesScreen());
              },
            ),
          ),

          // Quick Dial 112 & 108 Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => PhoneLauncherUtil.launchPhone('112'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.call_rounded, size: 14),
                    label: const Text('112 Emergency', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => PhoneLauncherUtil.launchPhone('108'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.airport_shuttle_rounded, size: 14),
                    label: const Text('108 Ambulance', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 16),

          // GOVERNMENT SCHEMES HEADER
          _buildSectionHeader(isHi ? 'सरकारी स्वास्थ्य योजनाएं (Government)' : 'Government Health Schemes'),

          _buildDrawerItem(
            icon: Icons.dashboard_customize_rounded,
            title: isHi ? 'सरकारी योजनाएं डैशबोर्ड' : 'Government Schemes Dashboard',
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const GovernmentDashboardScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.credit_card_rounded,
            title: isHi ? 'आयुष्मान भारत (PMJAY)' : 'Ayushman Bharat (PMJAY)',
            color: const Color(0xFF047857),
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const PmjayAyushmanScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.health_and_safety_rounded,
            title: isHi ? 'आभा (ABHA) हेल्थ आईडी' : 'ABHA Health ID (NDHM)',
            color: AppColors.primaryTeal,
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const AbhaManagementScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.bloodtype_rounded,
            title: isHi ? 'ई-रक्तकोष ब्लड बैंक' : 'Blood Bank Finder (eRaktKosh)',
            color: const Color(0xFFDC2626),
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const BloodBankFinderScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.medication_rounded,
            title: isHi ? 'जन औषधि केंद्र (सस्ती दवाएं)' : 'Jan Aushadhi (Generic Medicine)',
            color: const Color(0xFF0D9488),
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const JanAushadhiScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.qr_code_scanner_rounded,
            title: isHi ? 'त्वरित ओपीडी टोकन (Scan & Share)' : 'OPD Instant Token (Scan & Share)',
            color: const Color(0xFF16A34A),
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const OpdScanShareScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.child_care_rounded,
            title: isHi ? 'मातृ एवं शिशु स्वास्थ्य (MCH)' : 'Maternal & Child Health (MCH)',
            color: const Color(0xFFD97706),
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const MaternalChildScreen());
            },
          ),

          const Divider(height: 16),

          // HEALTHCARE SERVICES
          _buildSectionHeader(isHi ? 'स्वास्थ्य सेवाएं (Healthcare)' : 'Healthcare Services'),
          _buildDrawerItem(
            icon: Icons.local_hospital_outlined,
            title: isHi ? 'निकटतम अस्पताल एवं आईसीयू बेड' : 'Nearby Hospitals & ICU Beds',
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const NearbyHospitalsScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.fitness_center_rounded,
            title: isHi ? 'फिजियोथेरेपी एवं पुनर्वास (AI)' : 'Physiotherapy & Rehab (AI)',
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const PhysiotherapyHomeScreen());
            },
          ),
          _buildDrawerItem(
            icon: Icons.description_outlined,
            title: isHi ? 'डिजिटल प्रिस्क्रिप्शन (Rx)' : 'Digital Prescriptions (Rx)',
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => const PatientPrescriptionsScreen());
            },
          ),

          const Divider(height: 16),

          // PREFERENCES & PROFILE
          _buildSectionHeader(isHi ? 'सेटिंग्स व खाता' : 'Settings & Account'),
          _buildDrawerItem(
            icon: Icons.translate_rounded,
            title: isHi ? 'भाषा बदलें (Language: हिन्दी)' : 'Language Preferences (English)',
            color: const Color(0xFF0284C7),
            onTap: () {
              Navigator.of(context).pop();
              Get.to(() => ProfileScreen(authService: authService));
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            title: isHi ? 'लॉग आउट' : 'Log Out',
            color: const Color(0xFF64748B),
            onTap: () async {
              Navigator.of(context).pop();
              await authService?.logout();
              Get.offAll(() => PatientLoginScreen(authService: authService));
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = AppColors.primaryTeal,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
      onTap: onTap,
    );
  }
}
