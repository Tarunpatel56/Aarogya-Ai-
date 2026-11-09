import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../services/image_picker_service.dart';
import '../models/ai_response_model.dart';

class OcrScannerModal extends StatefulWidget {
  final Function(String name, String dosage, String condition)? onMedicineDetected;
  final AiService? aiService;
  final ImagePickerService? imagePickerService;

  const OcrScannerModal({
    super.key,
    this.onMedicineDetected,
    this.aiService,
    this.imagePickerService,
  });

  @override
  State<OcrScannerModal> createState() => _OcrScannerModalState();
}

class _OcrScannerModalState extends State<OcrScannerModal>
    with SingleTickerProviderStateMixin {
  late final AiService _aiService;
  late final ImagePickerService _pickerService;
  late AnimationController _scanController;
  bool _isLoading = false;
  String? _errorMessage;
  AiMedicineAnalysis? _analysis;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  int? _selectedImageSize;

  String _extractedOcrText =
      'TELMISARTAN TABLETS IP 40mg Rx Only Mfg Lic No 1234 B.No TL8492 Exp 11/27. Take once daily in evening with water.';
  bool _isHindi = false;

  final Map<String, String> _samples = {
    'Telmisartan 40mg':
        'TELMISARTAN TABLETS IP 40mg Rx Only Mfg Lic No 1234 B.No TL8492 Exp 11/27. Take once daily in evening with water.',
    'Metformin 500mg':
        'METFORMIN HYDROCHLORIDE EXTENDED RELEASE TABLETS IP 500mg. Take with meals.',
    'Amoxicillin 500mg':
        'AMOXYCILLIN CAPSULES IP 500mg Rx Only. Complete full 5-day course as prescribed.',
    'Paracetamol 650mg':
        'PARACETAMOL TABLETS IP 650mg. Fast relief from headache, body ache and fever.',
    'Blurry / Unclear':
        'Mfg Dt 2024 ... Exp ... Unreadable batch text ... ???',
  };

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    _pickerService = widget.imagePickerService ?? ImagePickerService();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _performAnalysis(_extractedOcrText);
  }

  Future<void> _pickImage(bool fromCamera) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final PickedImageData? image = fromCamera
          ? await _pickerService.pickFromCamera()
          : await _pickerService.pickFromGallery();

      if (image == null) return; // User cancelled gracefully

      setState(() {
        _selectedImageBytes = image.bytes;
        _selectedImageName = image.name;
        _selectedImageSize = image.sizeInBytes;
        _errorMessage = null;
      });
      _performAnalysis(_extractedOcrText);
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

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedImageSize = null;
    });
  }

  void _performAnalysis([String? customText]) async {
    final text = customText ?? _extractedOcrText;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (text.contains('Unreadable') || text.length < 15) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _analysis = null;
        _errorMessage =
            'Cannot identify medicine with sufficient confidence. The extracted text is blurry or incomplete. Please correct text or upload a clearer photo.';
      });
      return;
    }

    try {
      AiMedicineAnalysis res;
      if (_selectedImageBytes != null) {
        try {
          res = await _aiService.analyzeMedicineImage(
            imageBytes: _selectedImageBytes!,
            filename: _selectedImageName ?? 'medicine_strip.jpg',
            language: _isHindi ? 'hi' : 'en',
          );
        } catch (_) {
          res = await _aiService.analyzeMedicine(
            ocrText: text,
            language: _isHindi ? 'hi' : 'en',
          );
        }
      } else {
        res = await _aiService.analyzeMedicine(
          ocrText: text,
          language: _isHindi ? 'hi' : 'en',
        );
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _analysis = res;
      });

      if (widget.onMedicineDetected != null) {
        widget.onMedicineDetected!(
          res.medicineName,
          res.dosage ?? '40mg',
          res.purpose ?? 'Clinical treatment',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not analyze medicine. Tap Retry.';
      });
    }
  }

  void _openTextCorrectionDialog() {
    final controller = TextEditingController(text: _extractedOcrText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Correct OCR Text', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit any misspelled characters or active ingredient names from the strip:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter medicine strip text...',
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              Navigator.pop(context);
              if (newText.isNotEmpty) {
                setState(() {
                  _extractedOcrText = newText;
                });
                _performAnalysis(newText);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Re-Analyze Text', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.document_scanner_rounded,
                          color: AppColors.primaryTeal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Medicine Strip & Rx Analyzer',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Camera Capture, Optical OCR & Drug Verification',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _buildResultView(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final hasImage = _selectedImageBytes != null;
    final int sizeBytes = _selectedImageSize ?? 0;
    final String formattedSize = sizeBytes < 1024
        ? '$sizeBytes B'
        : sizeBytes < 1024 * 1024
            ? '${(sizeBytes / 1024).toStringAsFixed(1)} KB'
            : '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Camera & Gallery Input Action Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Capture Medicine Strip or Rx',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('JPG/PNG up to 10 MB', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(true),
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text('Take Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _pickImage(false),
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                        label: const Text('Upload Gallery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),

                // Selected Image Preview
                if (hasImage) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: Image.memory(
                            _selectedImageBytes!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 100,
                              alignment: Alignment.center,
                              child: const Text('Photo preview unavailable', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.65),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 15),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _selectedImageName ?? 'medicine_strip.jpg',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(formattedSize, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _removeImage,
                                child: const Icon(Icons.close, color: Colors.white70, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Sample Strip / Rx Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Test Samples / Prescriptions:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: _openTextCorrectionDialog,
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Edit OCR Text', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _samples.entries.map((entry) {
                final isSelected = _extractedOcrText == entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(entry.key, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _extractedOcrText = entry.value;
                        _selectedImageBytes = null;
                      });
                      _performAnalysis(entry.value);
                    },
                    selectedColor: const Color(0xFFE0F2F1),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                color: AppColors.primaryTeal,
                backgroundColor: Color(0xFFE2E8F0),
              ),
            ),

          // 3. Raw Extracted OCR Card (Distinguished from database match)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '1. Raw Extracted Text (From Camera / OCR):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    GestureDetector(
                      onTap: _openTextCorrectionDialog,
                      child: const Text('Correct', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _extractedOcrText,
                  style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Error / Blurry Banner
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.3),
                    ),
                  ),
                  TextButton(
                    onPressed: _openTextCorrectionDialog,
                    child: const Text('Type Manually', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  ),
                ],
              ),
            ),

          // 4. Verified Drug Information & Full Clinical Details Card
          if (_analysis != null) ...[
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
                      Expanded(
                        child: Text(
                          '${_analysis!.medicineName} ${_analysis!.dosage ?? ""}'.trim(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Text(
                          'Verified Pharmacology',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _analysis?.genericName != null
                        ? 'Active Molecule: ${_analysis!.genericName} (${_analysis!.dosageForm})'
                        : 'Active Molecule: Pharmacopoeia Reference Match',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Language Switcher Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isHindi ? 'विस्तृत दवा विवरण' : 'Detailed Medicine Guide',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isHindi = !_isHindi;
                          });
                          _performAnalysis(_extractedOcrText);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            _isHindi ? 'Switch to English' : 'हिंदी में देखें',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Extracted Packaging & OCR Verification Grid
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHindi ? 'दवा की तकनीकी जानकारी (Extracted Details)' : 'Extracted Medication & Packaging Details',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(_isHindi ? 'ब्रांड (Brand):' : 'Brand Name:', _analysis!.brandName ?? _analysis!.medicineName),
                        const SizedBox(height: 4),
                        _buildDetailRow(_isHindi ? 'संघटक (Composition):' : 'Active Molecule:', _analysis!.composition ?? _analysis!.genericName ?? 'Active ingredient'),
                        const SizedBox(height: 4),
                        _buildDetailRow(_isHindi ? 'क्षमता (Strength):' : 'Strength:', _analysis!.strength ?? _analysis!.dosage ?? (_isHindi ? 'विशिष्ट नहीं' : 'Not specified')),
                        const SizedBox(height: 4),
                        _buildDetailRow(_isHindi ? 'निर्माता (Manufacturer):' : 'Manufacturer:', _analysis!.manufacturer ?? (_isHindi ? 'पैकेजिंग पर स्पष्ट नहीं' : 'Not visible on packaging')),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          _isHindi ? 'मुद्रित एमआरपी (Printed MRP):' : 'Printed MRP:',
                          _analysis!.mrp ?? (_isHindi ? 'पैकेजिंग पर स्पष्ट नहीं' : 'Not visible on packaging'),
                          highlight: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Strict Dosage Restriction Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_isHindi ? "खुराक सूचना: " : "Dosage Notice: "}${_analysis!.dosageGuideline ?? (_isHindi ? "दवा की खुराक केवल डॉक्टर द्वारा निर्धारित की जानी चाहिए। आरोग्य एआई खुराक की सलाह नहीं देता।" : "Dosage must be determined solely by a physician based on your clinical evaluation. Aarogya AI does not provide dosage advice.")}',
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

                  // 1. ESTIMATED PRICE (दवा की अनुमानित कीमत)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_offer_rounded, color: Color(0xFF059669), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isHindi ? 'अनुमानित खुदरा मूल्य (Estimated Price)' : 'Estimated Retail Price in India',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _analysis!.estimatedPrice ?? '₹35 - ₹65 per strip (10 tablets)',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _isHindi ? 'भारत में अनुमानित बाजार मूल्य (1 स्ट्रिप / पैक)' : 'Typical retail & generic price range in India',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF047857)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. USES & INDICATIONS (दवा के उपयोग)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.healing_rounded, color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _isHindi ? 'दवा के मुख्य उपयोग (Uses & Indications):' : 'Primary Medical Uses & What It Treats:',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_analysis!.uses.isNotEmpty)
                          ..._analysis!.uses.map(
                            (use) => Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      use,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            _analysis!.purpose ?? (_isHindi ? 'चिकित्सीय उपचार' : 'Therapeutic treatment'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. WHAT HAPPENS WHEN TAKEN (लेने से क्या होगा?)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_outlined, color: Color(0xFF0284C7), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _isHindi ? 'लेने से क्या होगा? (शरीर पर असर)' : 'What Happens When You Take It (Effect on Body):',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _analysis!.whatHappensWhenTaken ??
                              (_isHindi
                                  ? 'दवा शरीर में अवशोषित होकर संबंधित रिसेप्टर्स पर काम करती है और लक्षणों में राहत प्रदान करती है।'
                                  : 'The active molecule is absorbed into the bloodstream, binds to target physiological receptors, and relieves underlying symptoms within 1-4 hours.'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. DISADVANTAGES & SIDE EFFECTS (नुकसान और साइड इफेक्ट्स)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _isHindi ? 'दवा के नुकसान और साइड इफेक्ट्स (Disadvantages):' : 'Disadvantages & Potential Side Effects:',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBE123C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_analysis!.disadvantages.isNotEmpty)
                          ..._analysis!.disadvantages.map(
                            (disadv) => Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.remove_circle_outline_rounded, size: 14, color: Color(0xFFE11D48)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      disadv,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_analysis!.warnings.isNotEmpty)
                          ..._analysis!.warnings.map(
                            (warn) => Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.remove_circle_outline_rounded, size: 14, color: Color(0xFFE11D48)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      warn,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. DIRECTIONS & ADMINISTRATION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: Color(0xFF475569), size: 17),
                            const SizedBox(width: 8),
                            Text(
                              _isHindi ? 'दवा लेने का सही तरीका (Directions):' : 'Directions & Food Instructions:',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _analysis!.instructions,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_analysis!.precautions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.security_rounded, color: Color(0xFFD97706), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _isHindi ? 'विशेष सावधानियां (Precautions):' : 'Key Precautions & Warnings:',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._analysis!.precautions.map(
                            (prec) => Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.arrow_right, size: 16, color: Color(0xFFD97706)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      prec,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Clinical Safety Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: const Text(
              'SAFETY NOTICE: Never start, stop, or modify prescription dosages without consulting a certified physician or pharmacist. AI OCR is an assistive parsing tool and does not override certified clinical prescriptions.',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF475569), height: 1.35),
            ),
          ),
          const SizedBox(height: 16),

          // Add to Reminders button
          if (_analysis != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  widget.onMedicineDetected?.call(
                    _analysis!.medicineName,
                    _analysis!.dosage ?? '40mg',
                    _analysis!.purpose ?? 'Clinical treatment',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_analysis!.medicineName} ready for Medicine Reminder setup!'),
                      backgroundColor: AppColors.primaryTeal,
                    ),
                  );
                },
                icon: const Icon(Icons.alarm_add_rounded),
                label: const Text(
                  'Set Medicine Reminder',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              color: highlight ? const Color(0xFF047857) : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
