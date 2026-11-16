import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'language_controller.dart';

/// Interactive Language Toggle Button [ EN | हिन्दी ]
class LanguageSelectorWidget extends StatelessWidget {
  final bool compact;

  const LanguageSelectorWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final langCtrl = Get.put(LanguageController());

    return Obx(() {
      final isHindi = langCtrl.isHindi;

      if (compact) {
        return InkWell(
          onTap: () => langCtrl.toggleLanguage(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isHindi ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHindi ? const Color(0xFF14B8A6) : const Color(0xFFCBD5E1),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 14,
                  color: isHindi ? Colors.white : const Color(0xFF0F766E),
                ),
                const SizedBox(width: 5),
                Text(
                  isHindi ? 'हिन्दी' : 'English',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHindi ? Colors.white : const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Full Toggle [ English | हिन्दी ]
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTab(
              label: 'English',
              isActive: !isHindi,
              onTap: () => langCtrl.changeLanguage('en'),
            ),
            _buildTab(
              label: 'हिन्दी',
              isActive: isHindi,
              onTap: () => langCtrl.changeLanguage('hi'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
