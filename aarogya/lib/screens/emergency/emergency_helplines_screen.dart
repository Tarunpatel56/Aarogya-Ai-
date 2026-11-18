import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/phone_launcher_util.dart';

class EmergencyHelplineItem {
  final String number;
  final String titleEn;
  final String titleHi;
  final String descEn;
  final String descHi;
  final IconData icon;
  final Color color;
  final bool isPrimary;

  const EmergencyHelplineItem({
    required this.number,
    required this.titleEn,
    required this.titleHi,
    required this.descEn,
    required this.descHi,
    required this.icon,
    required this.color,
    this.isPrimary = false,
  });
}

class EmergencyHelplinesScreen extends StatelessWidget {
  const EmergencyHelplinesScreen({super.key});

  static const List<EmergencyHelplineItem> helplines = [
    EmergencyHelplineItem(
      number: '112',
      titleEn: 'National Emergency Helpline (All-in-One)',
      titleHi: 'राष्ट्रीय आपातकालीन सेवा (पुलिस, एम्बुलेंस, दमकल)',
      descEn: 'Unified emergency response service across India for immediate rescue.',
      descHi: 'तत्काल सहायता हेतु एकीकृत अखिल भारतीय आपातकालीन नंबर।',
      icon: Icons.emergency_rounded,
      color: Color(0xFFDC2626),
      isPrimary: true,
    ),
    EmergencyHelplineItem(
      number: '108',
      titleEn: 'Emergency Medical & Ambulance (Toll Free)',
      titleHi: 'निःशुल्क आपातकालीन एम्बुलेंस सेवा',
      descEn: '24x7 Government emergency ambulance service with ALS/BLS life support.',
      descHi: 'चौबीसों घंटे निःशुल्क सरकारी एम्बुलेंस एवं जीवन रक्षक सहायता।',
      icon: Icons.airport_shuttle_rounded,
      color: Color(0xFFB91C1C),
      isPrimary: true,
    ),
    EmergencyHelplineItem(
      number: '100',
      titleEn: 'Police Emergency Assistance',
      titleHi: 'पुलिस आपातकालीन सहायता',
      descEn: 'Immediate police patrol and crime reporting control room.',
      descHi: 'अपराध नियंत्रण एवं तत्काल पुलिस सहायता कक्ष।',
      icon: Icons.local_police_rounded,
      color: Color(0xFF1E40AF),
    ),
    EmergencyHelplineItem(
      number: '101',
      titleEn: 'Fire & Rescue Department',
      titleHi: 'अग्निशमन एवं बचाव सेवा',
      descEn: 'Fire accident emergency and building disaster rescue operations.',
      descHi: 'आग दुर्घटना एवं आपातकालीन आपदा बचाव दल।',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEA580C),
    ),
    EmergencyHelplineItem(
      number: '1091',
      titleEn: 'Women Helpline (Crisis Intervention)',
      titleHi: 'महिला हेल्पलाइन (संकट निवारण)',
      descEn: '24x7 immediate assistance, legal aid, and safety for women in distress.',
      descHi: 'संकटग्रस्त महिलाओं हेतु 24x7 तत्काल सुरक्षा, परामर्श व कानूनी सहायता।',
      icon: Icons.female_rounded,
      color: Color(0xFF9333EA),
      isPrimary: true,
    ),
    EmergencyHelplineItem(
      number: '181',
      titleEn: 'Women Safety & Domestic Abuse Helpline',
      titleHi: 'महिला सुरक्षा एवं घरेलू हिंसा निवारण',
      descEn: 'Support line for domestic harassment, women safety and shelter coordination.',
      descHi: 'घरेलू उत्पीड़न, महिला सुरक्षा और आश्रय समन्वय हेतु राष्ट्रीय हेल्पलाइन।',
      icon: Icons.shield_rounded,
      color: Color(0xFF7E22CE),
    ),
    EmergencyHelplineItem(
      number: '1098',
      titleEn: 'Childline (Child Abuse & Missing Children)',
      titleHi: 'चाइल्डलाइन (बाल सुरक्षा व सहायता)',
      descEn: 'Emergency care, protection, and rescue for children in distress.',
      descHi: 'संकटग्रस्त बच्चों की सुरक्षा, संरक्षण व त्वरित सहायता हेतु।',
      icon: Icons.child_care_rounded,
      color: Color(0xFFD97706),
    ),
    EmergencyHelplineItem(
      number: '14567',
      titleEn: 'Senior Citizens Elderline',
      titleHi: 'वरिष्ठ नागरिक एल्डरलाइन',
      descEn: 'Healthcare assistance, emotional support, and rescue for elderly citizens.',
      descHi: 'वरिष्ठ नागरिकों हेतु स्वास्थ्य सहायता, कानूनी परामर्श व भावनात्मक संबल।',
      icon: Icons.elderly_rounded,
      color: Color(0xFF0D9488),
    ),
    EmergencyHelplineItem(
      number: '14416',
      titleEn: 'Tele-MANAS Mental Health Support',
      titleHi: 'टेली-मानस मानसिक स्वास्थ्य परामर्श',
      descEn: '24x7 psychological counseling, distress handling, and psychiatric guidance.',
      descHi: 'चौबीसों घंटे निःशुल्क मनोवैज्ञानिक परामर्श एवं मानसिक संबल।',
      icon: Icons.psychology_rounded,
      color: Color(0xFF0284C7),
    ),
    EmergencyHelplineItem(
      number: '1075',
      titleEn: 'National Health Helpline (MOHFW)',
      titleHi: 'राष्ट्रीय स्वास्थ्य हेल्पलाइन (स्वास्थ्य मंत्रालय)',
      descEn: 'Central government public health inquiries, epidemic alerts, and hospitals.',
      descHi: 'केंद्रीय स्वास्थ्य मंत्रालय द्वारा सार्वजनिक स्वास्थ्य एवं अस्पताल जानकारी।',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF059669),
    ),
    EmergencyHelplineItem(
      number: '14555',
      titleEn: 'Ayushman Bharat PMJAY Helpline',
      titleHi: 'आयुष्मान भारत (PMJAY) हेल्पलाइन',
      descEn: 'Card status, empanelled hospital locator, and treatment coverage query.',
      descHi: 'आयुष्मान कार्ड स्थिति, संबद्ध अस्पताल एवं 5 लाख तक के इलाज संबंधी सहायता।',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF047857),
    ),
    EmergencyHelplineItem(
      number: '18001808080',
      titleEn: 'National Blood Helpline (eRaktKosh)',
      titleHi: 'राष्ट्रीय रक्त हेल्पलाइन (ई-रक्तकोष)',
      descEn: 'Real-time blood component availability and emergency donor linkage.',
      descHi: 'रक्त घटक उपलब्धता एवं आपातकालीन रक्तदाता समन्वय केंद्र।',
      icon: Icons.bloodtype_rounded,
      color: Color(0xFFE11D48),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHi = Get.locale?.languageCode == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isHi ? 'राष्ट्रीय आपातकालीन हेल्पलाइन' : 'National Emergency Helplines'),
        backgroundColor: const Color(0xFFB91C1C),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isHi
                        ? 'किसी भी आपात स्थिति में नीचे दिए गए नंबरों पर सीधे टैप करके तत्काल फोन कॉल करें। ये सभी नंबर भारत सरकार द्वारा 24x7 निःशुल्क संचालित हैं।'
                        : 'In any emergency, tap any number below to dial immediately. All numbers are operated 24x7 toll-free by the Government of India.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF991B1B),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...helplines.map((item) => _buildHelplineCard(item, isHi)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHelplineCard(EmergencyHelplineItem item, bool isHi) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPrimary ? item.color.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
          width: item.isPrimary ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => PhoneLauncherUtil.launchPhone(item.number),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 26),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHi ? item.titleHi : item.titleEn,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isHi ? item.descHi : item.descEn,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Call Dial Pill Button
                ElevatedButton.icon(
                  onPressed: () => PhoneLauncherUtil.launchPhone(item.number),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: Text(
                    item.number,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
