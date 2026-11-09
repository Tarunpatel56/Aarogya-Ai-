import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/medical_report_model.dart';
import '../../services/ai_service.dart';
import '../../services/image_picker_service.dart';
import '../doctors/doctor_directory_screen.dart';

class MedicalReportAnalyzerScreen extends StatefulWidget {
  final AiService? aiService;
  final ImagePickerService? imagePickerService;

  const MedicalReportAnalyzerScreen({
    super.key,
    this.aiService,
    this.imagePickerService,
  });

  @override
  State<MedicalReportAnalyzerScreen> createState() => _MedicalReportAnalyzerScreenState();
}

class _MedicalReportAnalyzerScreenState extends State<MedicalReportAnalyzerScreen> {
  late final AiService _aiService;
  late final ImagePickerService _pickerService;

  Uint8List? _selectedImageBytes;
  String _selectedImageName = '';
  final TextEditingController _textReportController = TextEditingController();

  bool _isTextMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  MedicalReportAnalysisResult? _result;
  bool _isHindi = false;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    _pickerService = widget.imagePickerService ?? ImagePickerService();
  }

  @override
  void dispose() {
    _textReportController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    setState(() => _errorMessage = null);
    try {
      final PickedImageData? image = fromCamera
          ? await _pickerService.pickFromCamera()
          : await _pickerService.pickFromGallery();

      if (image == null) return;

      setState(() {
        _selectedImageBytes = image.bytes;
        _selectedImageName = image.name;
        _result = null;
        _errorMessage = null;
      });
    } on ImagePickerException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to select image: ${e.toString()}');
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
    if (!_isTextMode && _selectedImageBytes == null) {
      setState(() {
        _errorMessage = _isHindi
            ? 'कृपया पहले लैब रिपोर्ट की फोटो अपलोड करें।'
            : 'Please select or capture a photo of your laboratory report.';
      });
      return;
    }

    if (_isTextMode && _textReportController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = _isHindi
            ? 'कृपया रिपोर्ट का विवरण या टेक्स्ट दर्ज करें।'
            : 'Please paste or enter the lab report text to analyze.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final language = _isHindi ? 'hi' : 'en';
      MedicalReportAnalysisResult res;

      if (_isTextMode) {
        res = await _aiService.analyzeMedicalReportText(
          reportText: _textReportController.text.trim(),
          language: language,
        );
      } else {
        res = await _aiService.analyzeMedicalReportImage(
          imageBytes: _selectedImageBytes!,
          filename: _selectedImageName.isNotEmpty ? _selectedImageName : 'lab_report.jpg',
          language: language,
        );
      }

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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFBA1A1A);
      case 'HIGH':
        return const Color(0xFFD32F2F);
      case 'LOW':
        return const Color(0xFFE65100);
      case 'NORMAL':
      default:
        return const Color(0xFF00796B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _isHindi ? 'मेडिकल रिपोर्ट विश्लेषक' : 'AI Medical Report Analyzer',
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
            // Mode selector (Photo vs Text)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          _isHindi ? 'रिपोर्ट फोटो अपलोड' : 'Upload Report Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: !_isTextMode ? FontWeight.bold : FontWeight.normal,
                            color: !_isTextMode ? AppColors.primaryTeal : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      selected: !_isTextMode,
                      selectedColor: AppColors.mintBg,
                      onSelected: (_) => setState(() => _isTextMode = false),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          _isHindi ? 'टेक्स्ट पेस्ट करें' : 'Paste Report Text',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _isTextMode ? FontWeight.bold : FontWeight.normal,
                            color: _isTextMode ? AppColors.primaryTeal : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      selected: _isTextMode,
                      selectedColor: AppColors.mintBg,
                      onSelected: (_) => setState(() => _isTextMode = true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Card
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
                  if (!_isTextMode) ...[
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
                              height: 200,
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
                    ],
                  ] else ...[
                    Text(
                      _isHindi ? 'लैब रिपोर्ट विवरण दर्ज करें:' : 'Paste Laboratory Report Text / Biomarkers:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textReportController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: _isHindi
                            ? 'उदा. Hemoglobin: 11.2 g/dL (Range: 13-17)\nFasting Sugar: 145 mg/dL\nCholesterol: 230 mg/dL'
                            : 'e.g. Hemoglobin: 11.2 g/dL (Reference: 13.0 - 17.0)\nFasting Blood Sugar: 145 mg/dL (Reference: 70 - 100)\nSerum Creatinine: 1.4 mg/dL',
                        hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
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
                          : const Icon(Icons.document_scanner_outlined, size: 20),
                      label: Text(
                        _isLoading
                            ? (_isHindi ? 'रिपोर्ट विश्लेषण जारी है...' : 'Extracting & Analyzing Report...')
                            : (_isHindi ? 'रिपोर्ट का विश्लेषण करें' : 'Analyze Medical Report'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error display
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
                      child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFCF1322), fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Results Display
            if (_result != null) ...[
              // Summary & Category Card
              Container(
                padding: const EdgeInsets.all(18),
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
                            color: AppColors.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.biotech_outlined, color: AppColors.primaryTeal, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result!.reportCategory,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (_result!.reportDateVisible != null)
                                Text(
                                  'Date: ${_result!.reportDateVisible}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _result!.findingsSummary,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isHindi ? 'मरीज के लिए स्पष्टीकरण:' : 'What This Means for You:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.mintText),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _result!.plainLanguageExplanation,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.mintText, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Out-of-Range Parameters Alert Card
              if (_result!.outOfRangeParameters.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFCCC7)),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFCF1322), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isHindi ? 'सीमा से बाहर मान (Out-of-Range):' : 'Out-of-Range Biomarkers:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFCF1322)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._result!.outOfRangeParameters.map(
                        (param) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      param.testName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    Text(
                                      'Standard: ${param.standardRange} ${param.unit}',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${param.observedValue} ${param.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _getStatusColor(param.status),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(param.status),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      param.status,
                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Complete Biomarkers Table
              if (_result!.extractedParameters.isNotEmpty) ...[
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
                      Text(
                        _isHindi ? 'सभी निकाले गए बायोमार्कर:' : 'Complete Extracted Biomarkers:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(1.8),
                          2: FlexColumnWidth(1.8),
                          3: FlexColumnWidth(1.3),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: AppColors.mintBg.withValues(alpha: 0.5)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_isHindi ? 'जांच' : 'Test', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_isHindi ? 'परिणाम' : 'Value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_isHindi ? 'संदर्भ' : 'Ref Range', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(_isHindi ? 'स्थिति' : 'Status', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                              ),
                            ],
                          ),
                          ..._result!.extractedParameters.map(
                            (param) => TableRow(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(param.testName, style: const TextStyle(fontSize: 12)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${param.observedValue} ${param.unit}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(param.standardRange, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    param.status,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(param.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Next Steps & Questions for Doctor
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
                    if (_result!.suggestedQuestionsForDoctor.isNotEmpty) ...[
                      Text(
                        _isHindi ? 'डॉक्टर से क्या पूछें:' : 'Questions to Ask Your Doctor:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      const SizedBox(height: 8),
                      ..._result!.suggestedQuestionsForDoctor.map(
                        (q) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💬 ', style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Text(q, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorDirectoryScreen(
                                initialSpecialty: _result!.recommendedSpecialty,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_search_outlined, size: 18),
                        label: Text(
                          _isHindi
                              ? '${_result!.recommendedSpecialty} डॉक्टर से परामर्श करें'
                              : 'Consult Verified ${_result!.recommendedSpecialty}',
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

              // Disclaimer
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
                    Icon(Icons.info_outline, size: 20, color: Colors.amber.shade900),
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
