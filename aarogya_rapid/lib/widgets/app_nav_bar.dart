import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RapidBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingRequestsCount;

  const RapidBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.pendingRequestsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        border: const Border(
          top: BorderSide(color: SanctuaryColors.hairlineBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.notifications_active_outlined,
              activeIcon: Icons.notifications_active,
              label: 'Requests',
              badgeCount: pendingRequestsCount,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.navigation_outlined,
              activeIcon: Icons.navigation,
              label: 'Active Trip',
              isPulsing: true,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.history_toggle_off_rounded,
              activeIcon: Icons.history_rounded,
              label: 'History',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
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
    required IconData activeIcon,
    required String label,
    int? badgeCount,
    bool isPulsing = false,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: SanctuaryRadius.rFull,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : Colors.transparent,
          borderRadius: SanctuaryRadius.rFull,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? SanctuaryColors.deepSlateNavy : SanctuaryColors.textSecondary,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: const BoxDecoration(
                        color: SanctuaryColors.crimsonRose,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (!isSelected && isPulsing)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: SanctuaryColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? SanctuaryColors.deepSlateNavy : SanctuaryColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
