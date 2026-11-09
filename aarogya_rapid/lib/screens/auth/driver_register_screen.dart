import 'package:flutter/material.dart';
import '../../services/ambulance_auth_service.dart';
import '../../theme/app_theme.dart';

class DriverRegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;

  const DriverRegisterScreen({super.key, required this.onRegisterSuccess});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleController = TextEditingController(text: 'DL-01-AMB-108');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'AMBULANCE_DRIVER'; // 'AMBULANCE_DRIVER' or 'PARAMEDIC'
  final _authService = AmbulanceAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _vehicleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match. Please re-enter.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        staffRole: _selectedRole,
        licenseNumber: _licenseController.text.trim(),
        assignedVehicleNumber: _vehicleController.text.trim().isNotEmpty
            ? _vehicleController.text.trim()
            : 'DL-01-AMB-108',
        certificationLevel: _selectedRole == 'PARAMEDIC' ? 'EMT-Critical Care' : 'Commercial Heavy EMS',
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ EMS Account registered successfully! Live dispatch active.'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
        widget.onRegisterSuccess();
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SanctuaryColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Register EMS Staff',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: SanctuaryColors.primaryDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: SanctuaryColors.emergencyRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create EMS Terminal Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: SanctuaryColors.primaryDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Ambulance Driver & Paramedic Network',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SanctuaryColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Error Alert Banner
                    if (_errorMessage != null) ...[
                      Container(
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
                                style: const TextStyle(fontSize: 12.5, color: SanctuaryColors.emergencyRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Form Container
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
                          // 1. Staff Role Selector
                          const Text(
                            'Select Operational Role *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.directions_car, size: 16),
                                      SizedBox(width: 6),
                                      Text('Driver'),
                                    ],
                                  ),
                                  selected: _selectedRole == 'AMBULANCE_DRIVER',
                                  selectedColor: SanctuaryColors.emergencyRed,
                                  labelStyle: TextStyle(
                                    color: _selectedRole == 'AMBULANCE_DRIVER' ? Colors.white : SanctuaryColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedRole = 'AMBULANCE_DRIVER');
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.medical_services_outlined, size: 16),
                                      SizedBox(width: 6),
                                      Text('Paramedic'),
                                    ],
                                  ),
                                  selected: _selectedRole == 'PARAMEDIC',
                                  selectedColor: SanctuaryColors.emergencyRed,
                                  labelStyle: TextStyle(
                                    color: _selectedRole == 'PARAMEDIC' ? Colors.white : SanctuaryColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedRole = 'PARAMEDIC');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. Full Name
                          const Text(
                            'Full Legal Name *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              hintText: 'e.g. Vikram Singh',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Full name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. Email
                          const Text(
                            'Official Email Address *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              hintText: 'e.g. vikram.driver@aarogya.ai',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || !val.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 4. Phone
                          const Text(
                            'Contact Phone Number',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                              hintText: 'e.g. 9810923812',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. License Number & Vehicle
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'License / Reg No. *',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _licenseController,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                                        hintText: 'DL-EMS-2026',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'License is required';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ambulance No. *',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _vehicleController,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.local_hospital_outlined, size: 18),
                                        hintText: 'DL-01-AMB-108',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 6. Password
                          const Text(
                            'Create Secure Password *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              hintText: 'At least 8 characters',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 8) return 'Password must be at least 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 7. Confirm Password
                          const Text(
                            'Confirm Password *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                              hintText: 'Re-enter password',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Confirm your password';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SanctuaryColors.emergencyRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isLoading ? null : _handleRegister,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Register EMS Account',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back to Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already registered with EMS?',
                          style: TextStyle(fontSize: 13, color: SanctuaryColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: SanctuaryColors.emergencyRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

