import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'health_monitoring_screen.dart';
import 'ai_assistant_screen.dart';
import 'records_screen.dart';
import 'profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final AuthService? authService;

  const MainNavigationShell({super.key, this.authService});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Responsive frame for wide screens (Web & Desktop)
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Screen content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    HomeScreen(
                      authService: widget.authService,
                      onNavigateToAI: () => setState(() => _currentIndex = 2),
                      onNavigateToHealth: () => setState(() => _currentIndex = 1),
                    ),
                    const HealthMonitoringScreen(),
                    const AIAssistantScreen(),
                    RecordsScreen(authService: widget.authService),
                    ProfileScreen(authService: widget.authService),
                  ],
                ),
              ),

              // Bottom Navigation Bar
              _buildBottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEAEFF2), width: 1.2),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 1,
                icon: Icons.show_chart_rounded,
                label: 'Health',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 2,
                icon: Icons.smart_toy_outlined,
                label: 'AI Assistant',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 3,
                icon: Icons.folder_open_rounded,
                label: 'Records',
              ),
            ),
            Expanded(
              child: _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                label: 'Profile',
              ),
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
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF00675B),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

