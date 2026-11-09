import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/medical_analysis_model.dart';
import '../../services/medical_ai_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/doctor_service.dart';
import '../../services/appointment_service.dart';
import '../doctors/doctor_directory_screen.dart';

class SkinAnalysisScreen extends StatefulWidget {
  final MedicalAiService? medicalAiService;
  final ImagePickerService? imagePickerService;
  final Uint8List? initialImageBytes;
  final String? initialImageName;

  const SkinAnalysisScreen({
    super.key,
    this.medicalAiService,
    this.imagePickerService,
    this.initialImageBytes,
    this.initialImageName,
  });

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen> {
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
        _errorMessage = 'Please select or upload a clear skin photograph.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final res = await _aiService.analyzeSkinImage(
        imageBytes: _selectedImageBytes!,
        filename: _selectedImageName.isNotEmpty
            ? _selectedImageName
            : (_selectedImageName.endsWith('.png') ? 'skin_lesion.png' : 'skin_lesion.jpg'),
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
          _isHindi ? 'त्वचा विश्लेषण' : 'Dermatological Analysis',
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
              if (_selectedImageBytes != null && _result != null) {
                _runAnalysis();
              }
            },
            icon: const Icon(Icons.language, size: 16, color: AppColors.primaryTeal),
            label: Text(
              _isHindi ? 'English' : 'हिंदी',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIntroductionCard(),
            const SizedBox(height: 16),
            _buildImagePickerCard(),
            const SizedBox(height: 16),
            if (_isLoading) _buildLoadingCard(),
            if (_errorMessage != null) _buildErrorCard(),
            if (_result != null) _buildResultCard(_result!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroductionCard() {
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.face_retouching_natural, color: Color(0xFF9333EA), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dermatological AI Screening',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Identifies patterns for Eczema, Acne, Psoriasis, Vitiligo, etc.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload a well-lit, focused macro photograph of the skin lesion or rash to receive preliminary pattern classification.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerCard() {
    final hasImage = _selectedImageBytes != null;
    final int sizeBytes = _selectedImageBytes?.length ?? 0;
    final String formattedSize = sizeBytes < 1024
        ? '$sizeBytes B'
        : sizeBytes < 1024 * 1024
            ? '${(sizeBytes / 1024).toStringAsFixed(1)} KB'
            : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';

    return Container(
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
              const Expanded(
                child: Text(
                  'Upload or Capture Skin Photo',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Max 10 MB', style: TextStyle(fontSize: 10, color: Color(0xFF9333EA), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Capture / Picker Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(true),
                  icon: const Icon(Icons.camera_alt_outlined, size: 17),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Take Photo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(false),
                  icon: const Icon(Icons.photo_library_outlined, size: 17),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Upload Gallery', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Real Image Preview or Placeholder
          if (hasImage) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 140,
                          color: const Color(0xFF1E293B),
                          alignment: Alignment.center,
                          child: const Text('Image preview unavailable', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        );
                      },
                    ),
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.image, color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedImageName,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedSize,
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isLoading ? null : _clearImage,
                          child: const Icon(Icons.close, color: Colors.white70, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _isLoading ? null : () => _pickImage(false),
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('Change Image', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                TextButton.icon(
                  onPressed: _isLoading ? null : _clearImage,
                  icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFDC2626)),
                  label: const Text('Remove', style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626))),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF94A3B8), size: 36),
                    SizedBox(height: 6),
                    Text('No skin photograph selected', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Capture well-lit photo or upload digital image', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Run Analysis Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: (_isLoading || !hasImage) ? null : _runAnalysis,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: Text(
                _isHindi ? 'त्वचा छवि का विश्लेषण करें' : 'Analyze Skin Image',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9333EA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: const [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
          ),
          SizedBox(height: 14),
          Text(
            'Analyzing Skin Lesion...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Evaluating texture, border regularity, and dermatological pigment distribution',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
              SizedBox(width: 8),
              Text(
                'Analysis Failed',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An error occurred during skin analysis.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), height: 1.3),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh, size: 16, color: Color(0xFFDC2626)),
              label: const Text('Retry Analysis', style: TextStyle(color: Color(0xFFDC2626))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(MedicalAnalysisResult res) {
    final topFinding = res.primaryFinding;

    return Container(
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC084FC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bubble_chart_outlined,
                        color: Color(0xFF9333EA),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          topFinding.normalizedLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9333EA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Confidence: ${topFinding.formattedConfidence}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (topFinding.description != null) ...[
            Text(
              topFinding.description!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 14),
          ],

          // Visible Observations Card
          if (res.observations.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF16A34A), size: 17),
                      const SizedBox(width: 8),
                      Text(
                        _isHindi ? 'दिखने वाले लक्षण (Visible Symptoms):' : 'Visible Dermatological Symptoms:',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...res.observations.map(
                    (obs) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(obs, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Possible Abnormalities Card
          if (res.possibleAbnormalities.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem_outlined, color: Color(0xFFD97706), size: 17),
                      const SizedBox(width: 8),
                      Text(
                        _isHindi ? 'संभावित त्वचा स्थितियां (Possible Conditions):' : 'Possible Skin Conditions & Differentials:',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...res.possibleAbnormalities.map(
                    (abn) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(abn, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Doctor Recommendation Card
          if (res.doctorRecommendation != null && res.doctorRecommendation!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, color: Color(0xFF2563EB), size: 17),
                      const SizedBox(width: 8),
                      Text(
                        _isHindi ? 'त्वचा विशेषज्ञ परामर्श सिफारिश:' : 'Dermatologist Consultation Guidance:',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    res.doctorRecommendation!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: topFinding.score,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Differential Classification Probabilities',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          ...res.allPredictions.map((pred) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pred.normalizedLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    pred.formattedConfidence,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Dermatological & Biopsy Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF475569), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    res.clinicalDisclaimer,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorDirectoryScreen(
                          doctorService: DoctorService(apiClient: _aiService.apiClient),
                          appointmentService: AppointmentService(apiClient: _aiService.apiClient),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_search, size: 16),
                  label: const Text('Consult Dermatologist', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _result = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('New Scan', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
