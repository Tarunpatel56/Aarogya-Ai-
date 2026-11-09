import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ClinicalBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int alertBadgeCount;

  const ClinicalBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.alertBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F0F172A),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.calendar_today_rounded,
              label: 'Appointments',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.people_alt_outlined,
              label: 'Patients',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.notifications_none_rounded,
              label: 'Updates',
              badgeCount: alertBadgeCount,
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.account_circle_outlined,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: isSelected
                      ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
                      : const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.secondary,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: isSelected ? 4 : -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.criticalRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                fontSize: 10,
                color: isSelected ? AppColors.primary : AppColors.secondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
