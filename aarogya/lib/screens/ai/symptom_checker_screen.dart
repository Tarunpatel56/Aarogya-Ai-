import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/ai_response_model.dart';
import '../../services/ai_service.dart';
import '../doctors/doctor_directory_screen.dart';

class SymptomCheckerScreen extends StatefulWidget {
  final AiService? aiService;

  const SymptomCheckerScreen({super.key, this.aiService});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  late final AiService _aiService;

  final Set<String> _selectedSymptoms = {};
  final TextEditingController _customSymptomController = TextEditingController();

  String _selectedDuration = '1 to 3 days';
  String _selectedSeverity = 'MODERATE';
  final Set<String> _chronicConditions = {};

  bool _isLoading = false;
  String? _errorMessage;
  AiTriageResult? _result;
  bool _isHindi = false;

  final List<String> _commonSymptomsEn = [
    'Fever',
    'Dry Cough',
    'Productive Cough',
    'Headache',
    'Sore Throat',
    'Chest Tightness',
    'Shortness of Breath',
    'Nausea & Vomiting',
    'Abdominal Pain',
    'Diarrhea',
    'Joint & Body Ache',
    'Skin Rash',
    'Fatigue / Weakness',
    'Dizziness',
    'Loss of Appetite',
  ];

  final List<String> _commonSymptomsHi = [
    'बुखार (Fever)',
    'सूखी खांसी',
    'बलगम वाली खांसी',
    'सिरदर्द (Headache)',
    'गले में खराश',
    'छाती में जकड़न',
    'सांस लेने में कठिनाई',
    'जी मिचलाना व उल्टी',
    'पेट दर्द',
    'दस्त (Diarrhea)',
    'जोड़ों और बदन में दर्द',
    'त्वचा पर दाने / खुजली',
    'अत्यधिक थकान व कमजोरी',
    'चक्कर आना (Dizziness)',
    'भूख न लगना',
  ];

  final List<String> _durationsEn = [
    '< 24 hours',
    '1 to 3 days',
    '4 to 7 days',
    '1 to 2 weeks',
    '> 2 weeks',
  ];

  final List<String> _durationsHi = [
    '24 घंटे से कम',
    '1 से 3 दिन',
    '4 से 7 दिन',
    '1 से 2 सप्ताह',
    '2 सप्ताह से अधिक',
  ];

  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension (BP)',
    'Asthma / Respiratory',
    'Heart Disease',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
  }

  @override
  void dispose() {
    _customSymptomController.dispose();
    super.dispose();
  }

  void _addCustomSymptom() {
    final text = _customSymptomController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _selectedSymptoms.add(text);
        _customSymptomController.clear();
      });
    }
  }

  Future<void> _evaluateSymptoms() async {
    final List<String> allSymptoms = List.from(_selectedSymptoms);
    if (_customSymptomController.text.trim().isNotEmpty) {
      allSymptoms.add(_customSymptomController.text.trim());
    }

    if (allSymptoms.isEmpty) {
      setState(() {
        _errorMessage = _isHindi
            ? 'कृपया कम से कम एक लक्षण चुनें या दर्ज करें।'
            : 'Please select or enter at least one symptom.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final symptomSummary = allSymptoms.join(', ');
      final vitals = _chronicConditions.isNotEmpty
          ? {'chronicConditions': _chronicConditions.toList()}
          : null;

      final res = await _aiService.assessTriage(
        symptoms: symptomSummary,
        duration: _selectedDuration,
        severity: _selectedSeverity,
        vitals: vitals,
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

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toUpperCase()) {
      case 'EMERGENCY':
        return const Color(0xFFBA1A1A);
      case 'HIGH':
        return const Color(0xFFD32F2F);
      case 'MEDIUM':
        return const Color(0xFFE65100);
      case 'LOW':
      default:
        return const Color(0xFF00796B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final symptomsList = _isHindi ? _commonSymptomsHi : _commonSymptomsEn;
    final durationsList = _isHindi ? _durationsHi : _durationsEn;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          _isHindi ? 'एआई लक्षण जांचकर्ता' : 'AI Symptom Checker',
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
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety_outlined, color: AppColors.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHindi ? 'नैदानिक ट्राइएज और जोखिम मूल्यांकन' : 'Clinical Triage & Risk Evaluation',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isHindi
                              ? 'अपने लक्षणों का चयन करें ताकि क्लिनिकल एआई जोखिम का विश्लेषण कर सके।'
                              : 'Select your symptoms to receive evidence-based clinical risk stratification.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 1: Select Symptoms
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
                    _isHindi ? '1. आप क्या लक्षण महसूस कर रहे हैं?' : '1. What symptoms are you experiencing?',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: symptomsList.map((symptom) {
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return FilterChip(
                        label: Text(symptom),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.add(symptom);
                            } else {
                              _selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                        selectedColor: AppColors.primaryTeal.withValues(alpha: 0.18),
                        checkmarkColor: AppColors.primaryTeal,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customSymptomController,
                          decoration: InputDecoration(
                            hintText: _isHindi ? 'अन्य लक्षण लिखें...' : 'Add other symptoms...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onSubmitted: (_) => _addCustomSymptom(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addCustomSymptom,
                        icon: const Icon(Icons.add_circle, color: AppColors.primaryTeal, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: Duration & Severity
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
                    _isHindi ? '2. लक्षण कब से हैं?' : '2. How long have you had them?',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: durationsList.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return ChoiceChip(
                        label: Text(duration),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedDuration = duration),
                        selectedColor: AppColors.mintBg,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isHindi ? '3. लक्षणों की गंभीरता (Severity):' : '3. Symptom Severity:',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['MILD', 'MODERATE', 'SEVERE'].map((sev) {
                      final isSelected = _selectedSeverity == sev;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: OutlinedButton(
                            onPressed: () => setState(() => _selectedSeverity = sev),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? (sev == 'SEVERE'
                                      ? const Color(0xFFBA1A1A).withValues(alpha: 0.15)
                                      : AppColors.primaryTeal.withValues(alpha: 0.15))
                                  : Colors.transparent,
                              side: BorderSide(
                                color: isSelected
                                    ? (sev == 'SEVERE' ? const Color(0xFFBA1A1A) : AppColors.primaryTeal)
                                    : AppColors.cardBorder,
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              sev,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? (sev == 'SEVERE' ? const Color(0xFFBA1A1A) : AppColors.primaryTeal)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isHindi ? '4. क्या आपको पहले से कोई बीमारी है?' : '4. Pre-existing Conditions:',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _commonConditions.map((cond) {
                      final isSelected = _chronicConditions.contains(cond);
                      return FilterChip(
                        label: Text(cond),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _chronicConditions.add(cond);
                            } else {
                              _chronicConditions.remove(cond);
                            }
                          });
                        },
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _evaluateSymptoms,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.analytics_outlined, size: 20),
                label: Text(
                  _isLoading
                      ? (_isHindi ? 'ट्राइएज जांच चल रही है...' : 'Evaluating Clinical Triage...')
                      : (_isHindi ? 'लक्षणों का नैदानिक मूल्यांकन करें' : 'Evaluate Symptoms with Clinical AI'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isHindi ? 'ट्राइएज मूल्यांकन' : 'Triage Assessment',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(_result!.urgencyLevel).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'URGENCY: ${_result!.urgencyLevel}',
                            style: TextStyle(
                              color: _getUrgencyColor(_result!.urgencyLevel),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _result!.summary,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isHindi ? 'अनुशंसित अगला कदम:' : 'Recommended Action:',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _result!.recommendedAction,
                        style: const TextStyle(fontSize: 13, color: AppColors.mintText, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 18, color: AppColors.primaryTeal),
                        const SizedBox(width: 8),
                        Text(
                          _isHindi ? 'सुझाए गए विशेषज्ञ:' : 'Suggested Specialty:',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _result!.suggestedSpecialty,
                            style: const TextStyle(fontSize: 13, color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_result!.redFlags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _isHindi ? 'चेतावनी के संकेत (Red Flags):' : 'Emergency Red Flags to Watch:',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFBA1A1A)),
                      ),
                      const SizedBox(height: 6),
                      ..._result!.redFlags.map(
                        (flag) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('⚠️ ', style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Text(flag, style: const TextStyle(fontSize: 12.5, color: Color(0xFFBA1A1A))),
                              ),
                            ],
                          ),
                        ),
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
                              builder: (_) => DoctorDirectoryScreen(
                                initialSpecialty: _result!.suggestedSpecialty,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: Text(
                          _isHindi ? '${_result!.suggestedSpecialty} अपॉइंटमेंट खोजें' : 'Book with ${_result!.suggestedSpecialty}',
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
                        _result!.disclaimer,
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
