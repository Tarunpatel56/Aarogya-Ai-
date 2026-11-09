import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/doctor_auth_service.dart';
import '../../core/api/api_exception.dart';

class DoctorRegisterScreen extends StatefulWidget {
  final DoctorAuthService authService;
  final VoidCallback onRegisterSuccess;

  const DoctorRegisterScreen({
    super.key,
    required this.authService,
    required this.onRegisterSuccess,
  });

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _addressController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedSpecialization = 'Cardiology';
  final List<String> _specializations = [
    'Cardiology',
    'General Medicine',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Pulmonology',
    'Gynecology',
    'Oncology',
  ];

  bool _inPersonMode = true;
  bool _onlineMode = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _hospitalController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final modes = <String>[];
    if (_inPersonMode) modes.add('IN_PERSON');
    if (_onlineMode) modes.add('ONLINE');

    if (modes.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one consultation mode (In-Person or Online)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.registerDoctor(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        specialization: _selectedSpecialization,
        medicalLicenseNumber: _licenseController.text.trim(),
        qualifications: _qualificationsController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 1,
        consultationFee: double.tryParse(_feeController.text.trim()) ?? 500.0,
        bio: _bioController.text.trim(),
        consultationModes: modes,
        hospitalAffiliation: _hospitalController.text.trim(),
        clinicAddress: _addressController.text.trim(),
      );

      if (mounted) {
        widget.onRegisterSuccess();
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Registration failed. Please check network connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Physician Registration'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Register Your Medical Practice',
                  style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your credentials will be placed into the verification pipeline upon submission.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Name
                const Text('Full Name (with Prefix)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Dr. Rajesh Verma'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 14),

                // Email & Phone
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('doctor@clinic.in'),
                            validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('+91 9876543210'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Phone number required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Password
                const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Min 8 characters').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 8 ? 'Password must be at least 8 characters' : null,
                ),
                const SizedBox(height: 14),

                // Specialization & Medical License
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Specialization', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSpecialization,
                            items: _specializations
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSpecialization = val);
                            },
                            decoration: _inputDecoration(''),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Medical License #', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _licenseController,
                            decoration: _inputDecoration('MCI-12345'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'License number required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Qualifications & Experience
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Qualifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _qualificationsController,
                            decoration: _inputDecoration('MBBS, MD (Cardio)'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Qualifications required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Exp (Years)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _experienceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('10'),
                            validator: (v) => v == null || int.tryParse(v) == null ? 'Valid number' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Consultation Fee & Hospital Affiliation
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fee (INR ₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _feeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration('700'),
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Valid fee' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hospital / Clinic Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _hospitalController,
                            decoration: _inputDecoration('Apollo Hospital'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Clinic Address
                const Text('Clinic Physical Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration('Suite 401, Health Hub, Bengaluru'),
                ),
                const SizedBox(height: 14),

                // Consultation Modes Checkboxes
                const Text('Supported Consultation Modes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Checkbox(
                      value: _inPersonMode,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _inPersonMode = v ?? false),
                    ),
                    const Text('In-Person Physical Visit', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    Checkbox(
                      value: _onlineMode,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _onlineMode = v ?? false),
                    ),
                    const Text('Online / Teleconsultation', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 14),

                // Bio
                const Text('Professional Bio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _bioController,
                  maxLines: 2,
                  decoration: _inputDecoration('Specialist with extensive focus on preventative heart care...'),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Provider Registration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderHairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderHairline),
      ),
    );
  }
}
