import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../services/superadmin_service.dart';
import '../../widgets/superadmin_brand_logo.dart';

class SuperAdminSplashScreen extends StatefulWidget {
  final SuperAdminService? adminService;
  final ValueChanged<bool>? onSessionChecked;

  const SuperAdminSplashScreen({
    super.key,
    this.adminService,
    this.onSessionChecked,
  });

  @override
  State<SuperAdminSplashScreen> createState() => _SuperAdminSplashScreenState();
}

class _SuperAdminSplashScreenState extends State<SuperAdminSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late SuperAdminService _adminService;
  String _statusText = 'Initializing Command Operations...';

  @override
  void initState() {
    super.initState();
    _adminService = widget.adminService ?? SuperAdminService();

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
    if (mounted) setState(() => _statusText = 'Establishing Secure Gateway Link...');
    try {
      await ApiConfig.autoDetectBaseUrl();
    } catch (_) {}

    // 2. Validate cryptographic Super Admin session
    if (mounted) setState(() => _statusText = 'Verifying Infrastructure Credentials...');
    bool hasSession = false;
    try {
      hasSession = await _adminService.isLoggedIn();
    } catch (_) {
      hasSession = false;
    }

    // Minimum splash duration for security handshake recognition
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    if (widget.onSessionChecked != null) {
      widget.onSessionChecked!(hasSession);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background ambient emerald & dark slate glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
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
                color: const Color(0xFF064E3B).withValues(alpha: 0.15),
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
                        const SuperAdminBrandLogo(
                          size: 96,
                          showText: true,
                          showBadge: true,
                          subtitle: 'National Healthcare Command & Tele-ICU Hub',
                        ),
                        const SizedBox(height: 36),

                        // Animated Pulse Indicator
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
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
                              color: Color(0xFF94A3B8),
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

          // Bottom Security & Compliance footer
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
                    Icons.security_rounded,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Zero-Trust Enterprise Access Control & Audit Logged',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
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

