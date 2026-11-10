import 'package:flutter/material.dart';
import '../../services/superadmin_service.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const SuperAdminLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _emailController = TextEditingController(text: 'superadmin@aarogya.ai');
  final _passwordController = TextEditingController(text: 'Admin@12345');
  final _adminService = SuperAdminService();
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
      final success = await _adminService.login(email: email, password: password);
      if (mounted) {
        if (success) {
          widget.onLoginSuccess();
        } else {
          setState(() {
            _errorMessage = 'Invalid Super Admin credentials or permission denied.';
            _isLoading = false;
          });
        }
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
      backgroundColor: const Color(0xFF0F172A), // Dark slate
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shield Logo
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF38BDF8),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aarogya SuperAdmin',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Master Healthcare Verification & Ecosystem Command',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Banner
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7F1D1D).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFFFCA5A5)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Quick Demo Auto-fill Chip
                  ActionChip(
                    avatar: const Icon(Icons.key, size: 14, color: Color(0xFF38BDF8)),
                    label: const Text('Quick Fill Super Admin Access', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                    backgroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                    onPressed: () {
                      setState(() {
                        _emailController.text = 'superadmin@aarogya.ai';
                        _passwordController.text = 'Admin@12345';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Super Admin Email',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF94A3B8)),
                            hintText: 'superadmin@aarogya.ai',
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Master Passphrase',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF94A3B8)),
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF334155)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 2,
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Access SuperAdmin Command',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

