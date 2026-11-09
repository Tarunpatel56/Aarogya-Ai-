import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/patient_service.dart';
import '../../services/auth_service.dart';
import '../../models/patient_profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  final PatientProfileModel initialProfile;
  final PatientService? patientService;
  final AuthService? authService;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
    this.patientService,
    this.authService,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _allergiesController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  late PatientService _patientService;
  late AuthService _authService;
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _commonAllergens = ['Penicillin', 'Peanuts', 'Sulfa Drugs', 'Aspirin', 'Dust Mites', 'Latex'];

  @override
  void initState() {
    super.initState();
    _patientService = widget.patientService ?? PatientService();
    _authService = widget.authService ?? AuthService();

    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p.fullName);
    _phoneController = TextEditingController(text: p.emergencyContactPhone ?? '');
    _addressController = TextEditingController(text: p.address ?? '');
    _emergencyNameController = TextEditingController(text: p.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: p.emergencyContactPhone ?? '');
    _allergiesController = TextEditingController(text: p.allergies ?? '');

    _selectedGender = p.gender;
    _selectedBloodGroup = p.bloodGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  void _addOrRemoveAllergen(String allergen) {
    List<String> current = _allergiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (current.contains(allergen)) {
      current.remove(allergen);
    } else {
      current.add(allergen);
    }

    setState(() {
      _allergiesController.text = current.join(', ');
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await _patientService.updateProfile(
        fullName: _nameController.text.trim(),
        gender: _selectedGender,
        bloodGroup: _selectedBloodGroup,
        address: _addressController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        allergies: _allergiesController.text.trim(),
      );

      _authService.updateProfileLocally(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAllergens = _allergiesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Patient Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12.5),
                  ),
                ),

              const Text('Personal Demographics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Name required' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      hint: const Text('Gender'),
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBloodGroup,
                      decoration: InputDecoration(
                        labelText: 'Blood Group',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      hint: const Text('Blood Group'),
                      items: _bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setState(() => _selectedBloodGroup = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Residential Address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              const Text('Allergies & Medical Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Tap common allergens or enter manually below:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonAllergens.map((allergen) {
                  final isSelected = currentAllergens.contains(allergen);
                  return FilterChip(
                    label: Text(allergen),
                    selected: isSelected,
                    onSelected: (_) => _addOrRemoveAllergen(allergen),
                    selectedColor: AppColors.primaryTeal.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.primaryTeal,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies (comma-separated)',
                  hintText: 'e.g. Penicillin, Peanuts',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              const Text('Emergency Responder Protocol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Used for 1-Tap SOS dispatch and hospital admissions.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emergencyNameController,
                decoration: InputDecoration(
                  labelText: 'Primary Emergency Contact Name',
                  hintText: 'Priya Sharma (Spouse / Guardian)',
                  prefixIcon: const Icon(Icons.contact_phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  hintText: '+91 98765 43211',
                  prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

