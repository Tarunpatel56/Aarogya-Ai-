import 'package:flutter/material.dart';
import '../../services/ambulance_auth_service.dart';
import '../../theme/app_theme.dart';
import 'driver_register_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const DriverLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _emailController = TextEditingController(text: 'driver@aarogya.ai');
  final _passwordController = TextEditingController(text: 'Driver@123');
  final _authService = AmbulanceAuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.login(email: email, password: password);
      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // EMS Fleet Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: SanctuaryColors.emergencyRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: SanctuaryColors.emergencyRed.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aarogya Rapid EMS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: SanctuaryColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ambulance Driver & Paramedic Terminal',
                  style: TextStyle(
                    fontSize: 14,
                    color: SanctuaryColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Error Banner
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SanctuaryColors.emergencyRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SanctuaryColors.emergencyRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: SanctuaryColors.emergencyRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 13, color: SanctuaryColors.emergencyRed),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick Fill Role Selector (Driver / Super Admin)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.airport_shuttle, size: 14, color: SanctuaryColors.primaryTeal),
                      label: const Text('Lead Driver Login', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFFEFF6FF),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      onPressed: () {
                        setState(() {
                          _emailController.text = 'driver@aarogya.ai';
                          _passwordController.text = 'Driver@123';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 14, color: SanctuaryColors.crimsonRose),
                      label: const Text('Super Admin Command', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SanctuaryColors.crimsonRose)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      onPressed: () {
                        setState(() {
                          _emailController.text = 'superadmin@aarogya.ai';
                          _passwordController.text = 'Admin@12345';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Inputs
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Driver Registered Email',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                          hintText: 'driver@aarogya.ai',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Access Password',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          hintText: '••••••••',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SanctuaryColors.emergencyRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Sign In to EMS Terminal',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Link to Register Screen
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an EMS Driver account? ",
                      style: TextStyle(fontSize: 13, color: SanctuaryColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverRegisterScreen(
                              onRegisterSuccess: widget.onLoginSuccess,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Register Here',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: SanctuaryColors.emergencyRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text(
                  'Connected to Shared Aarogya Centralized Backend',
                  style: TextStyle(fontSize: 12, color: SanctuaryColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
