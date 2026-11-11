import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onNavigateToAI;
  final VoidCallback onOpenOcrScanner;
  final VoidCallback onOpenDoctorDirectory;
  final VoidCallback? onOpenVoiceAssistant;
  final VoidCallback? onOpenBrainMri;
  final VoidCallback? onOpenLungXray;
  final VoidCallback? onOpenSkinAnalysis;
  final VoidCallback? onOpenEyeAnalysis;
  final VoidCallback? onOpenSymptomChecker;
  final VoidCallback? onOpenReportAnalyzer;
  final VoidCallback? onOpenPhysio;
  final VoidCallback? onOpenNearbyHospitals;
  final VoidCallback? onOpenPrescriptions;

  const HomeQuickActions({
    super.key,
    required this.onNavigateToAI,
    required this.onOpenOcrScanner,
    required this.onOpenDoctorDirectory,
    this.onOpenVoiceAssistant,
    this.onOpenBrainMri,
    this.onOpenLungXray,
    this.onOpenSkinAnalysis,
    this.onOpenEyeAnalysis,
    this.onOpenSymptomChecker,
    this.onOpenReportAnalyzer,
    this.onOpenPhysio,
    this.onOpenNearbyHospitals,
    this.onOpenPrescriptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: const [
                  Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.primaryTeal,
                    size: 19,
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Quick Healthcare Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'AI Powered',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (onOpenVoiceAssistant != null) ...[
          GestureDetector(
            onTap: onOpenVoiceAssistant,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF042F2C), Color(0xFF0F766E)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.elevatedShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: Color(0xFF5EEAD4), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Talk-to-Talk Voice Assistant',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bol ke baat karein • Hindi & English voice mode',
                          style: TextStyle(fontSize: 11, color: Color(0xFFCCFBF1)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Live Voice',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF042F2C)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            // Tile 1: Ask Aarogya
            Expanded(
              child: _buildActionTile(
                icon: Icons.chat_bubble_outline_rounded,
                iconBg: const Color(0xFF00665B),
                iconColor: Colors.white,
                title: 'Ask Aarogya',
                subtitle: 'AI Assistant',
                onTap: onNavigateToAI,
              ),
            ),
            const SizedBox(width: 10),

            // Tile 2: Scan Rx / Strip
            Expanded(
              child: _buildActionTile(
                icon: Icons.crop_free_rounded,
                iconBg: const Color(0xFFEDE9FE),
                iconColor: const Color(0xFF6D28D9),
                title: 'Scan Medicine',
                subtitle: 'OCR Reader',
                onTap: onOpenOcrScanner,
              ),
            ),
            const SizedBox(width: 10),

            // Tile 3: Find Doctors
            Expanded(
              child: _buildActionTile(
                icon: Icons.person_search_outlined,
                iconBg: const Color(0xFFE0F2F1),
                iconColor: AppColors.primaryTeal,
                title: 'Find Doctors',
                subtitle: 'Book Visit',
                onTap: onOpenDoctorDirectory,
              ),
            ),
          ],
        ),
        if (onOpenBrainMri != null ||
            onOpenLungXray != null ||
            onOpenSkinAnalysis != null ||
            onOpenEyeAnalysis != null ||
            onOpenSymptomChecker != null ||
            onOpenReportAnalyzer != null ||
            onOpenPhysio != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              if (onOpenBrainMri != null)
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.psychology_outlined,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Brain MRI',
                    subtitle: 'Tumor AI',
                    onTap: onOpenBrainMri!,
                  ),
                ),
              if (onOpenBrainMri != null && onOpenLungXray != null)
                const SizedBox(width: 8),
              if (onOpenLungXray != null)
                Expanded(
                  child: _buildActionTile(
                    icon: Icons.air,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    title: 'Chest X-Ray',
                    subtitle: 'Lungs AI',
                    onTap: onOpenLungXray!,
                  ),
                ),
            ],
          ),
          if (onOpenSkinAnalysis != null || onOpenEyeAnalysis != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onOpenSkinAnalysis != null)
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.face_retouching_natural,
                      iconBg: const Color(0xFFFAF5FF),
                      iconColor: const Color(0xFF9333EA),
                      title: 'Skin Lesion',
                      subtitle: 'Derma AI',
                      onTap: onOpenSkinAnalysis!,
                    ),
                  ),
                if (onOpenSkinAnalysis != null && onOpenEyeAnalysis != null)
                  const SizedBox(width: 8),
                if (onOpenEyeAnalysis != null)
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.remove_red_eye_outlined,
                      iconBg: const Color(0xFFE0F2F1),
                      iconColor: const Color(0xFF00897B),
                      title: 'Eye AI',
                      subtitle: 'Ocular Scan',
                      onTap: onOpenEyeAnalysis!,
                    ),
                  ),
              ],
            ),
          ],
          if (onOpenSymptomChecker != null ||
              onOpenReportAnalyzer != null ||
              onOpenPhysio != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onOpenSymptomChecker != null)
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.health_and_safety_outlined,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF00796B),
                      title: 'Symptom Triage',
                      subtitle: 'Clinical AI',
                      onTap: onOpenSymptomChecker!,
                    ),
                  ),
                if (onOpenSymptomChecker != null &&
                    onOpenReportAnalyzer != null)
                  const SizedBox(width: 8),
                if (onOpenReportAnalyzer != null)
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.biotech_outlined,
                      iconBg: const Color(0xFFE1F5FE),
                      iconColor: const Color(0xFF0288D1),
                      title: 'Lab Report',
                      subtitle: 'Doc Analyzer',
                      onTap: onOpenReportAnalyzer!,
                    ),
                  ),
                if (onOpenReportAnalyzer != null && onOpenPhysio != null)
                  const SizedBox(width: 8),
                if (onOpenPhysio != null)
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.accessibility_new_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Physio',
                      subtitle: 'Rehab Plans',
                      onTap: onOpenPhysio!,
                    ),
                  ),
              ],
            ),
          ],
          if (onOpenNearbyHospitals != null || onOpenPrescriptions != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onOpenNearbyHospitals != null)
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.local_hospital_outlined,
                      iconBg: const Color(0xFFFEF2F2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Nearby Hospitals',
                      subtitle: 'Live ICU Beds',
                      onTap: onOpenNearbyHospitals!,
                    ),
                  ),
                if (onOpenNearbyHospitals != null && onOpenPrescriptions != null)
                  const SizedBox(width: 8),
                if (onOpenPrescriptions != null)
                  Expanded(
                    child: _buildActionTile(
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF0F766E),
                      title: 'Digital Prescriptions',
                      subtitle: 'Doctor Orders & Meds',
                      onTap: onOpenPrescriptions!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
