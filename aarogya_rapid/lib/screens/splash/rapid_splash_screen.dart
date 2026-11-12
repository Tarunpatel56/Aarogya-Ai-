import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/ambulance_auth_service.dart';
import '../../core/config/api_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rapid_brand_logo.dart';

class RapidSplashScreen extends StatefulWidget {
  final AmbulanceAuthService? authService;
  final ValueChanged<bool>? onSessionChecked;

  const RapidSplashScreen({
    super.key,
    this.authService,
    this.onSessionChecked,
  });

  @override
  State<RapidSplashScreen> createState() => _RapidSplashScreenState();
}

class _RapidSplashScreenState extends State<RapidSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AmbulanceAuthService _authService;
  String _statusText = 'Initializing EMS Dispatch Grid...';

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AmbulanceAuthService();

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
    if (mounted) setState(() => _statusText = 'Connecting to Emergency Dispatch Cloud...');
    try {
      await ApiConfig.autoDetectBaseUrl();
    } catch (_) {}

    // 2. Validate ambulance driver session credentials
    if (mounted) setState(() => _statusText = 'Restoring Driver Fleet Session...');
    bool hasSession = false;
    try {
      hasSession = await _authService.isLoggedIn();
    } catch (_) {
      hasSession = false;
    }

    // Minimum splash duration for brand recognition
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    if (widget.onSessionChecked != null) {
      widget.onSessionChecked!(hasSession);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background ambient emergency crimson & amber glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SanctuaryColors.emergencyRed.withValues(alpha: 0.08),
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
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
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
                        const RapidBrandLogo(
                          size: 96,
                          showText: true,
                          showBadge: true,
                          subtitle: 'Ambulance Dispatch & Rapid Response Fleet',
                        ),
                        const SizedBox(height: 36),

                        // Animated Pulse Indicator
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              SanctuaryColors.emergencyRed,
                            ),
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
                              color: SanctuaryColors.textMuted,
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

          // Bottom Regulatory footer
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
                    Icons.emergency_rounded,
                    size: 14,
                    color: SanctuaryColors.emergencyRed,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'National Emergency Response System (108 / NERS) Integrated',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SanctuaryColors.textMuted,
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
