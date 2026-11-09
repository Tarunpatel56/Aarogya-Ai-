import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'auth/patient_login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final AuthService? authService;

  const OnboardingScreen({super.key, this.authService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AuthService _authService;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Multimodal Clinical AI\nDiagnostic Suite',
      'description':
          'Instant OCR medicine strip parsing with verified MRP & side effects, plus assistive screening for Brain MRI, Chest X-Ray and Dermatological conditions.',
      'icon': Icons.biotech_rounded,
      'badge': 'AI-POWERED ASSISTANT',
      'gradient': const [Color(0xFF005B52), Color(0xFF0F766E)],
      'accentColor': const Color(0xFF10B981),
    },
    {
      'title': 'Continuous Smartwatch\nHealth Telemetry',
      'description':
          'Live BLE integration syncing Heart Rate, SpO2, Blood Pressure and Sleep trends directly from your smartwatch with zero fabricated or simulated readings.',
      'icon': Icons.watch_rounded,
      'badge': 'REAL-TIME WEARABLE SYNC',
      'gradient': const [Color(0xFF0284C7), Color(0xFF0369A1)],
      'accentColor': const Color(0xFF38BDF8),
    },
    {
      'title': '24/7 Emergency SOS &\nDoctor Teleconsultations',
      'description':
          'One-tap GPS emergency ambulance dispatch, verified hospital ICU bed finder, and instant consultations with certified clinical specialists.',
      'icon': Icons.emergency_rounded,
      'badge': 'IMMEDIATE RESPONSE',
      'gradient': const [Color(0xFFE11D48), Color(0xFFBE123C)],
      'accentColor': const Color(0xFFFDA4AF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PatientLoginScreen(authService: _authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _navigateToLogin,
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Slide Hero Illustration Card
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: slide['gradient'] as List<Color>,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (slide['gradient'] as List<Color>)[0]
                                    .withValues(alpha: 0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              slide['icon'] as IconData,
                              size: 96,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: (slide['accentColor'] as Color).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            slide['badge'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: (slide['gradient'] as List<Color>)[0],
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          slide['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          slide['description'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryTeal
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _navigateToLogin();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
