import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/health_monitoring_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/records_screen.dart';
import 'screens/profile_screen.dart';
// import 'screens/auth/patient_login_screen.dart';
import 'core/config/api_config.dart';
import 'services/auth_service.dart';
import 'services/watch_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await ApiConfig.autoDetectBaseUrl();
  runApp(const AarogyaAiApp());
}

class AarogyaAiApp extends StatefulWidget {
  final Widget? home;
  final AuthService? authService;

  const AarogyaAiApp({
    super.key,
    this.home,
    this.authService,
  });

  @override
  State<AarogyaAiApp> createState() => _AarogyaAiAppState();
}

class _AarogyaAiAppState extends State<AarogyaAiApp> {
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aarogya AI 2.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Auth commented out for now — navigate directly to Home screen
      home: widget.home ?? MainNavigationShell(authService: _authService),
    );
  }
}

class AuthGate extends StatefulWidget {
  final AuthService authService;

  const AuthGate({super.key, required this.authService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthChange);
    _restore();
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthChange);
    super.dispose();
  }

  void _onAuthChange() {
    if (mounted) setState(() {});
  }

  Future<void> _restore() async {
    await widget.authService.restoreSession();
    await WatchService().loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    // Auth check commented out — navigate directly to Home screen
    return MainNavigationShell(authService: widget.authService);

    /*
    if (_isRestoring) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.local_hospital_rounded, color: AppColors.primaryTeal, size: 54),
              SizedBox(height: 16),
              CircularProgressIndicator(color: AppColors.primaryTeal),
              SizedBox(height: 12),
              Text(
                'Restoring Secure Aarogya Session...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.authService.isAuthenticated) {
      return MainNavigationShell(authService: widget.authService);
    }

    return PatientLoginScreen(
      authService: widget.authService,
      onLoginSuccess: () {
        setState(() {});
      },
    );
    */
  }
}

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
