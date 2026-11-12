import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/doctor_auth_service.dart';
import '../../core/config/api_config.dart';
import '../../widgets/healthpro_brand_logo.dart';
import '../doctor_navigation_shell.dart';
import '../auth/doctor_login_screen.dart';

class DoctorSplashScreen extends StatefulWidget {
  final DoctorAuthService? authService;

  const DoctorSplashScreen({super.key, this.authService});

  @override
  State<DoctorSplashScreen> createState() => _DoctorSplashScreenState();
}

class _DoctorSplashScreenState extends State<DoctorSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late DoctorAuthService _authService;
  String _statusText = 'Initializing Clinical Environment...';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? DoctorAuthService();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // 1. Probe active backend servers
    if (mounted) setState(() => _statusText = 'Connecting to Hospital Gateway...');
    try {
      await ApiConfig.autoDetectBaseUrl();
    } catch (_) {}

    // 2. Validate doctor session credentials
    if (mounted) setState(() => _statusText = 'Verifying Clinical Credentials...');
    bool hasSession = false;
    try {
      hasSession = await _authService.restoreSession();
    } catch (_) {
      hasSession = false;
    }

    // Minimum splash duration for brand recognition
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    if (hasSession && _authService.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => MainNavigationShell(authService: _authService),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => DoctorLoginScreen(
            authService: _authService,
            onLoginSuccess: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MainNavigationShell(authService: _authService),
                ),
              );
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background ambient indigo & cyan glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Brand Logo
                        const HealthProBrandLogo(
                          size: 96,
                          showText: true,
                          showBadge: true,
                          subtitle: 'Clinical Practice & Teleconsultation Portal',
                        ),
                        const SizedBox(height: 36),

                        // Animated Pulse Indicator
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dynamic Status Caption
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _statusText,
                            key: ValueKey<String>(_statusText),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Regulatory & NHA Compliance footer
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'ABDM M1, M2 & M3 National Health Stack Compliant',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
