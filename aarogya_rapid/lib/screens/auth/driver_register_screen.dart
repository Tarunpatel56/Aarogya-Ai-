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

  // Uploaded Document references
  String? _dlFileName;
  String? _rcFileName;
  String? _certFileName;
  String? _idFileName;

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

  Map<String, dynamic>? _buildDocumentsPayload() {
    final docs = <String, dynamic>{};
    if (_dlFileName != null) {
      docs['drivingLicense'] = {
        'fileName': _dlFileName,
        'docType': 'COMMERCIAL_DRIVING_LICENSE',
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': '1.8 MB',
      };
    }
    if (_rcFileName != null) {
      docs['vehicleRc'] = {
        'fileName': _rcFileName,
        'docType': 'AMBULANCE_REGISTRATION_CERTIFICATE',
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': '2.1 MB',
      };
    }
    if (_certFileName != null) {
      docs['certification'] = {
        'fileName': _certFileName,
        'docType': _selectedRole == 'PARAMEDIC' ? 'ALS_PARAMEDIC_CERT' : 'COMMERCIAL_HEAVY_EMS_CERT',
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': '950 KB',
      };
    }
    if (_idFileName != null) {
      docs['identityProof'] = {
        'fileName': _idFileName,
        'docType': 'GOVERNMENT_ID_AADHAAR',
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': '1.1 MB',
      };
    }
    return docs.isNotEmpty ? docs : null;
  }

  void _simulateAttachAllDocs() {
    final name = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim().replaceAll(' ', '_')
        : 'Pilot';
    setState(() {
      _dlFileName = 'DL_${name}_2026.pdf';
      _rcFileName = 'Ambulance_RC_DL01AMB108.pdf';
      _certFileName = _selectedRole == 'PARAMEDIC' ? 'ALS_Advanced_Paramedic_Cert.pdf' : 'EMS_Heavy_Vehicle_Cert.pdf';
      _idFileName = 'Govt_Aadhaar_Card_$name.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ 4 Compliance Documents attached (DL, RC, Cert, ID)'),
        backgroundColor: SanctuaryColors.optimalGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _pickOrToggleDoc(String key, String defaultName) {
    setState(() {
      switch (key) {
        case 'DL':
          _dlFileName = _dlFileName == null ? defaultName : null;
          break;
        case 'RC':
          _rcFileName = _rcFileName == null ? defaultName : null;
          break;
        case 'CERT':
          _certFileName = _certFileName == null ? defaultName : null;
          break;
        case 'ID':
          _idFileName = _idFileName == null ? defaultName : null;
          break;
      }
    });
  }

  Future<void> _handleRegisterWithDocuments() async {
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
      final documents = _buildDocumentsPayload();
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
        documents: documents,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ EMS Account & Documents registered! Pending Super Admin Approval.'),
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
          'Register Ambulance Pilot / Paramedic',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: SanctuaryColors.primaryDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Super Admin Verification Enforced',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'New pilots must upload compliance documents or use Quick Pass. Duty activates upon Super Admin approval.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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

                    // Standard Form Container
                    Container(
                      padding: const EdgeInsets.all(18),
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
                                      Text('Ambulance Pilot'),
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
                                      Text('ALS Paramedic'),
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
                            'Pilot Email Address *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SanctuaryColors.primaryDark),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              hintText: 'e.g. vikram.pilot@aarogya.ai',
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
                            'Mobile Phone Number *',
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
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Mobile number is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 5. License & Vehicle
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'License / Badge *',
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
                                      'Ambulance Plate *',
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
                          const SizedBox(height: 20),

                          // ==========================================
                          // 📑 COMPLIANCE DOCUMENTS UPLOAD SECTION
                          // ==========================================
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SanctuaryColors.hairlineBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.folder_shared_outlined, color: SanctuaryColors.primaryDark, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Upload Compliance Documents',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: SanctuaryColors.primaryDark),
                                        ),
                                      ],
                                    ),
                                    TextButton(
                                      onPressed: _simulateAttachAllDocs,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Attach All (Demo)',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Super Admin verification ke liye in documents ko upload karein ya attach karein:',
                                  style: TextStyle(fontSize: 10.5, color: SanctuaryColors.textSecondary),
                                ),
                                const SizedBox(height: 10),

                                // Doc 1: Driving License
                                _buildDocumentUploadTile(
                                  title: '1. Commercial Driving License (DL)',
                                  subtitle: 'Heavy Vehicle / EMS Certified Badge',
                                  icon: Icons.drive_eta_outlined,
                                  fileName: _dlFileName,
                                  onTap: () => _pickOrToggleDoc('DL', 'DL_Heavy_Commercial_2026.pdf'),
                                ),
                                const SizedBox(height: 8),

                                // Doc 2: Ambulance RC
                                _buildDocumentUploadTile(
                                  title: '2. Ambulance Registration (RC & Fitness)',
                                  subtitle: 'Govt. Vehicle Fitness & Siren Permit',
                                  icon: Icons.airport_shuttle_outlined,
                                  fileName: _rcFileName,
                                  onTap: () => _pickOrToggleDoc('RC', 'Ambulance_RC_DL01AMB108.pdf'),
                                ),
                                const SizedBox(height: 8),

                                // Doc 3: Paramedic / BLS Cert
                                _buildDocumentUploadTile(
                                  title: '3. Paramedic / ALS / BLS Certificate',
                                  subtitle: 'Emergency Medical Technician Credential',
                                  icon: Icons.health_and_safety_outlined,
                                  fileName: _certFileName,
                                  onTap: () => _pickOrToggleDoc('CERT', 'ALS_EMT_Certification.pdf'),
                                ),
                                const SizedBox(height: 8),

                                // Doc 4: Identity Proof
                                _buildDocumentUploadTile(
                                  title: '4. Govt Identity Proof (Aadhaar / Voter)',
                                  subtitle: 'National ID verification proof',
                                  icon: Icons.badge_outlined,
                                  fileName: _idFileName,
                                  onTap: () => _pickOrToggleDoc('ID', 'Govt_Aadhaar_ID_Proof.pdf'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

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

                          // Primary Submit Button (With Documents)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SanctuaryColors.emergencyRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isLoading ? null : _handleRegisterWithDocuments,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Submit for Super Admin Verification',
                                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
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

  Widget _buildDocumentUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final bool isUploaded = fileName != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUploaded ? const Color(0xFFBBF7D0) : SanctuaryColors.hairlineBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded ? Icons.check_circle : icon,
              size: 20,
              color: isUploaded ? SanctuaryColors.optimalGreen : SanctuaryColors.primaryDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isUploaded ? SanctuaryColors.optimalGreen : SanctuaryColors.primaryDark,
                    ),
                  ),
                  Text(
                    isUploaded ? 'Attached: $fileName' : subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUploaded ? const Color(0xFF15803D) : SanctuaryColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isUploaded ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isUploaded ? 'Attached' : 'Upload',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUploaded ? SanctuaryColors.optimalGreen : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
