import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/medical_analysis_model.dart';
import '../../services/medical_ai_service.dart';
import '../../services/image_picker_service.dart';
import '../doctors/doctor_directory_screen.dart';

class EyeAnalysisScreen extends StatefulWidget {
  final MedicalAiService? medicalAiService;
  final ImagePickerService? imagePickerService;
  final Uint8List? initialImageBytes;
  final String? initialImageName;

  const EyeAnalysisScreen({
    super.key,
    this.medicalAiService,
    this.imagePickerService,
    this.initialImageBytes,
    this.initialImageName,
  });

  @override
  State<EyeAnalysisScreen> createState() => _EyeAnalysisScreenState();
}

class _EyeAnalysisScreenState extends State<EyeAnalysisScreen> {
  late final MedicalAiService _aiService;
  late final ImagePickerService _pickerService;

  Uint8List? _selectedImageBytes;
  String _selectedImageName = '';
  bool _isLoading = false;
  String? _errorMessage;
  MedicalAnalysisResult? _result;
  bool _isHindi = false;

  @override
  void initState() {
    super.initState();
    _aiService = widget.medicalAiService ?? MedicalAiService();
    _pickerService = widget.imagePickerService ?? ImagePickerService();
    _selectedImageBytes = widget.initialImageBytes;
    _selectedImageName = widget.initialImageName ?? '';
  }

  Future<void> _pickImage(bool fromCamera) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final PickedImageData? image = fromCamera
          ? await _pickerService.pickFromCamera()
          : await _pickerService.pickFromGallery();

      if (image == null) return;

      setState(() {
        _selectedImageName = image.name;
        _selectedImageBytes = image.bytes;
        _result = null;
        _errorMessage = null;
      });
    } on ImagePickerException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to select image: ${e.toString()}';
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = '';
      _result = null;
      _errorMessage = null;
    });
  }

  Future<void> _runAnalysis() async {
    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = _isHindi
            ? 'कृपया पहले आंख की स्पष्ट फोटो अपलोड करें।'
            : 'Please select or capture a clear photograph of the eye.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final res = await _aiService.analyzeEyeImage(
        imageBytes: _selectedImageBytes!,
        filename: _selectedImageName.isNotEmpty
            ? _selectedImageName
            : (_selectedImageName.endsWith('.png') ? 'eye_photo.png' : 'eye_photo.jpg'),
        language: _isHindi ? 'hi' : 'en',
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _result = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _isHindi ? 'नेत्र रोग विश्लेषण' : 'Eye Disease AI',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isHindi = !_isHindi;
              });
            },
            icon: const Icon(Icons.language, size: 18, color: AppColors.primaryTeal),
            label: Text(
              _isHindi ? 'English' : 'हिंदी',
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions / Best Practice Card
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF0288D1), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isHindi ? 'नेत्र फोटो कैप्चर निर्देश' : 'Eye Capture Guidelines',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isHindi
                        ? '1. प्राकृतिक प्रकाश में आंख खोलकर फोटो लें।\n2. सीधे पुतली पर फ्लैश न जलाएं।\n3. लालिमा, कॉर्निया और पलकों को स्पष्ट फ्रेम में रखें।'
                        : '1. Capture in bright, natural, diffused lighting.\n2. Avoid harsh direct camera flash into the pupil.\n3. Keep the eye comfortably open and steady.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image Picker Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _pickImage(true),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: Text(_isHindi ? 'कैमरा से फोटो लें' : 'Take Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => _pickImage(false),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: Text(_isHindi ? 'गैलरी से चुनें' : 'Upload Gallery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryTeal,
                            side: const BorderSide(color: AppColors.primaryTeal),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_selectedImageBytes != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.memory(
                            _selectedImageBytes!,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: _isLoading ? null : _clearImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _runAnalysis,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          _isLoading
                              ? (_isHindi ? 'विश्लेषण चल रहा है...' : 'Analyzing Eye Photo...')
                              : (_isHindi ? 'नेत्र विश्लेषण शुरू करें' : 'Analyze Eye Image'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error Display
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCCC7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFCF1322)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFCF1322), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Results Display
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isHindi ? 'विश्लेषण परिणाम' : 'Clinical Screening Result',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Confidence ${_result!.primaryFinding.formattedConfidence}',
                            style: const TextStyle(
                              color: AppColors.primaryTeal,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _result!.primaryFinding.normalizedLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.findingsSummary,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                    ),
                    if (_result!.observations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _isHindi ? 'नैदानिक अवलोकन:' : 'Observable Features:',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      ..._result!.observations.map(
                        (obs) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(obs, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_result!.clinicalExplanation != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _result!.clinicalExplanation!,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.mintText, height: 1.4),
                        ),
                      ),
                    ],
                    if (_result!.doctorRecommendation != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _isHindi ? 'विशेषज्ञ सलाह:' : 'Specialist Recommendation:',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _result!.doctorRecommendation!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DoctorDirectoryScreen(
                                initialSpecialty: 'Ophthalmology',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_search_outlined, size: 18),
                        label: Text(
                          _isHindi ? 'नेत्र रोग विशेषज्ञ (Ophthalmologist) से संपर्क करें' : 'Consult Verified Ophthalmologist',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Mandatory Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _result!.clinicalDisclaimer,
                        style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
