import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/medical_analysis_model.dart';
import '../../services/medical_ai_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/doctor_service.dart';
import '../../services/appointment_service.dart';
import '../doctors/doctor_directory_screen.dart';

class LungXrayScreen extends StatefulWidget {
  final MedicalAiService? medicalAiService;
  final ImagePickerService? imagePickerService;
  final Uint8List? initialImageBytes;
  final String? initialImageName;

  const LungXrayScreen({
    super.key,
    this.medicalAiService,
    this.imagePickerService,
    this.initialImageBytes,
    this.initialImageName,
  });

  @override
  State<LungXrayScreen> createState() => _LungXrayScreenState();
}

class _LungXrayScreenState extends State<LungXrayScreen> {
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
        _errorMessage = 'Please select or upload a chest X-Ray radiograph.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final res = await _aiService.analyzeLungXray(
        imageBytes: _selectedImageBytes!,
        filename: _selectedImageName.isNotEmpty
            ? _selectedImageName
            : (_selectedImageName.endsWith('.png') ? 'chest_xray.png' : 'chest_xray.jpg'),
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
          _isHindi ? 'फेफड़ों का एक्स-रे' : 'Chest X-Ray AI',
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
                  'Upload or Capture Chest X-Ray',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Max 10 MB', style: TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
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
                    backgroundColor: const Color(0xFF2563EB),
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
                    Text('No Chest X-Ray selected', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w600)),
                    SizedBox(height: 2),
                    Text('Capture film radiograph or upload JPEG / PNG image', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
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
              icon: const Icon(Icons.biotech, size: 18),
              label: Text(
                _isHindi ? 'चेस्ट एक्स-रे विश्लेषण करें' : 'Analyze Chest X-Ray',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
          ),
          SizedBox(height: 14),
          Text(
            'Analyzing Pulmonary Radiograph...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Detecting bilateral opacities and infiltrates on hosted model',
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
            _errorMessage ?? 'An error occurred during chest X-Ray analysis.',
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
    final isNormal = res.isNormal;
    final topFinding = res.primaryFinding;

    final badgeColor = isNormal ? const Color(0xFF10B981) : const Color(0xFFDC2626);
    final badgeBg = isNormal ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

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
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNormal ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: badgeColor,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          topFinding.normalizedLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
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
                        _isHindi ? 'दिखने वाले अवलोकन (Radiological Observations):' : 'Preliminary Radiograph Observations:',
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
                        _isHindi ? 'संभावित असामान्यताएं (Possible Abnormalities):' : 'Possible Abnormalities & Pulmonary Findings:',
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
                        _isHindi ? 'चिकित्सक परामर्श सिफारिश:' : 'Pulmonology / Physician Guidance:',
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
              valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
            ),
          ),
          const SizedBox(height: 16),

          // Probabilities
          const Text(
            'Classification Distribution',
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

          // CRITICAL CLINICAL NOTICE (Especially when NORMAL or any pulmonary scan)
          if (res.mandatoryClinicalNotice != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      res.mandatoryClinicalNotice!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // General disclaimer
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
                  label: const Text('Consult Pulmonologist', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
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
