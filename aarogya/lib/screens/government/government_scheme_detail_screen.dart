import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/phone_launcher_util.dart';
import 'government_portal_webview_screen.dart';

class GovernmentSchemeDetailScreen extends StatelessWidget {
  final String titleEn;
  final String titleHi;
  final String tagEn;
  final String tagHi;
  final String overviewEn;
  final String overviewHi;
  final List<String> benefitsEn;
  final List<String> benefitsHi;
  final List<String> eligibilityEn;
  final List<String> eligibilityHi;
  final List<String> documentsEn;
  final List<String> documentsHi;
  final String officialPortalUrl;
  final String helplineNumber;
  final String helplineNameEn;
  final String helplineNameHi;
  final IconData icon;
  final Color themeColor;

  const GovernmentSchemeDetailScreen({
    super.key,
    required this.titleEn,
    this.titleHi = '',
    this.tagEn = 'National Health Initiative',
    this.tagHi = 'राष्ट्रीय स्वास्थ्य पहल',
    required this.overviewEn,
    this.overviewHi = '',
    this.benefitsEn = const [],
    this.benefitsHi = const [],
    this.eligibilityEn = const [
      'All Indian citizens holding valid identification documents.',
      'Must satisfy scheme-specific criteria where applicable.',
    ],
    this.eligibilityHi = const [
      'वैध पहचान पत्र धारक सभी भारतीय नागरिक पात्र हैं।',
      'जहां लागू हो वहां योजना विशिष्ट मानदंडों को पूरा करना आवश्यक है।',
    ],
    this.documentsEn = const [
      'Aadhaar Card / Government Photo ID',
      'Ration Card / Income Certificate (if applicable)',
      'Active Mobile Number linked to Aadhaar',
    ],
    this.documentsHi = const [
      'आधार कार्ड / सरकारी फोटो पहचान पत्र',
      'राशन कार्ड / आय प्रमाण पत्र (यदि लागू हो)',
      'आधार से जुड़ा सक्रिय मोबाइल नंबर',
    ],
    this.officialPortalUrl = 'https://beneficiary.nha.gov.in',
    required this.helplineNumber,
    this.helplineNameEn = 'National Healthcare Helpline',
    this.helplineNameHi = 'राष्ट्रीय स्वास्थ्य हेल्पलाइन',
    this.icon = Icons.health_and_safety_rounded,
    this.themeColor = AppColors.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    final isHi = Get.locale?.languageCode == 'hi';
    final effectiveTitle = isHi && titleHi.isNotEmpty ? titleHi : titleEn;
    final effectiveTag = isHi && tagHi.isNotEmpty ? tagHi : tagEn;
    final effectiveOverview = isHi && overviewHi.isNotEmpty ? overviewHi : overviewEn;
    final effectiveBenefits = (isHi && benefitsHi.isNotEmpty)
        ? benefitsHi
        : (benefitsEn.isNotEmpty ? benefitsEn : benefitsHi);
    final effectiveEligibility = (isHi && eligibilityHi.isNotEmpty)
        ? eligibilityHi
        : eligibilityEn;
    final effectiveDocuments = (isHi && documentsHi.isNotEmpty)
        ? documentsHi
        : documentsEn;
    final effectiveHelplineName =
        isHi && helplineNameHi.isNotEmpty ? helplineNameHi : helplineNameEn;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(effectiveTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
            tooltip: '$effectiveHelplineName: $helplineNumber',
            onPressed: () => PhoneLauncherUtil.launchPhone(helplineNumber),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, themeColor.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              effectiveTag,
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              effectiveTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    effectiveOverview,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      // Helpline Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => PhoneLauncherUtil.launchPhone(helplineNumber),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: themeColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: Text(
                            '${isHi ? "हेल्पलाइन" : "Helpline"} $helplineNumber',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Web Portal Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.to(() => GovernmentPortalWebViewScreen(
                                  title: titleEn,
                                  titleHi: titleHi,
                                  portalUrl: officialPortalUrl,
                                  helplineNumber: helplineNumber,
                                  helplineName: effectiveHelplineName,
                                ));
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.language_rounded, size: 18),
                          label: Text(
                            isHi ? 'वेब पोर्टल' : 'Web Portal',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Benefits Section
            _buildSection(
              title: isHi ? 'प्रमुख लाभ एवं विशेषताएं' : 'Key Benefits & Coverage',
              icon: Icons.verified_rounded,
              items: effectiveBenefits,
              bulletColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),

            // Eligibility Section
            _buildSection(
              title: isHi ? 'पात्रता मानदंड' : 'Eligibility Criteria',
              icon: Icons.checklist_rounded,
              items: effectiveEligibility,
              bulletColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 16),

            // Required Documents Section
            _buildSection(
              title: isHi ? 'आवश्यक दस्तावेज' : 'Required Documents',
              icon: Icons.folder_shared_rounded,
              items: effectiveDocuments,
              bulletColor: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 24),

            // Bottom Full-width Official Portal Action
            ElevatedButton.icon(
              onPressed: () {
                Get.to(() => GovernmentPortalWebViewScreen(
                      title: titleEn,
                      titleHi: titleHi,
                      portalUrl: officialPortalUrl,
                      helplineNumber: helplineNumber,
                      helplineName: effectiveHelplineName,
                    ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(
                isHi ? 'आधिकारिक सरकारी पोर्टल खोलें' : 'Open Official Government Portal',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                isHi ? 'राष्ट्रीय स्वास्थ्य प्राधिकरण एवं स्वास्थ्य मंत्रालय भारत सरकार' : 'National Health Authority & Ministry of Health & Family Welfare',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color bulletColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: bulletColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5, right: 10),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: bulletColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
