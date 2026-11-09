class AiChatResponse {
  final String reply;
  final String? replyHi;
  final String? replyEn;
  final String provider;
  final String model;
  final String disclaimer;

  const AiChatResponse({
    required this.reply,
    this.replyHi,
    this.replyEn,
    required this.provider,
    required this.model,
    required this.disclaimer,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      reply: json['reply'] as String? ?? '',
      replyHi: json['replyHi'] as String?,
      replyEn: json['replyEn'] as String?,
      provider: json['provider'] as String? ?? 'gemini',
      model: json['model'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ??
          'Notice: Aarogya AI guidance is for informational reference only.',
    );
  }
}

class AiMedicineAnalysis {
  final String medicineName;
  final String? brandName;
  final String? genericName;
  final String? composition;
  final String? strength;
  final String? manufacturer;
  final String? mrp;
  final String? dosage;
  final String? dosageGuideline;
  final String dosageForm;
  final String frequency;
  final String? purpose;
  final String instructions;
  final List<String> warnings;
  final List<String> uses;
  final List<String> disadvantages;
  final List<String> precautions;
  final String? whatHappensWhenTaken;
  final String? estimatedPrice;
  final String disclaimer;
  final String provider;
  final String? extractedOcrText;
  final String? language;

  const AiMedicineAnalysis({
    required this.medicineName,
    this.brandName,
    this.genericName,
    this.composition,
    this.strength,
    this.manufacturer,
    this.mrp,
    this.dosage,
    this.dosageGuideline,
    required this.dosageForm,
    required this.frequency,
    this.purpose,
    required this.instructions,
    required this.warnings,
    this.uses = const [],
    this.disadvantages = const [],
    this.precautions = const [],
    this.whatHappensWhenTaken,
    this.estimatedPrice,
    required this.disclaimer,
    required this.provider,
    this.extractedOcrText,
    this.language,
  });

  factory AiMedicineAnalysis.fromJson(Map<String, dynamic> json) {
    final usesList = (json['uses'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['purpose'] != null ? [json['purpose'].toString()] : const <String>[]);
    final disadvList = (json['disadvantages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        (json['warnings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final precList = (json['precautions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];

    return AiMedicineAnalysis(
      medicineName: json['medicineName'] as String? ?? 'Unknown Medicine',
      brandName: json['brandName'] as String?,
      genericName: json['genericName'] as String?,
      composition: json['composition'] as String? ?? json['genericName'] as String?,
      strength: json['strength'] as String? ?? json['dosage'] as String?,
      manufacturer: json['manufacturer'] as String?,
      mrp: json['mrp'] as String?,
      dosage: json['dosage'] as String?,
      dosageGuideline: json['dosageGuideline'] as String?,
      dosageForm: json['dosageForm'] as String? ?? 'Tablet',
      frequency: json['frequency'] as String? ?? 'As directed by physician',
      purpose: json['purpose'] as String?,
      instructions: json['instructions'] as String? ??
          'Take strictly as prescribed by your doctor.',
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      uses: usesList,
      disadvantages: disadvList,
      precautions: precList,
      whatHappensWhenTaken: json['whatHappensWhenTaken'] as String?,
      estimatedPrice: json['estimatedPrice'] as String?,
      disclaimer: json['disclaimer'] as String? ??
          'Notice: Aarogya AI guidance is for informational reference only.',
      provider: json['provider'] as String? ?? 'gemini',
      extractedOcrText: json['extractedOcrText'] as String?,
      language: json['language'] as String?,
    );
  }
}

class AiTriageResult {
  final String urgencyLevel;
  final String summary;
  final String recommendedAction;
  final String suggestedSpecialty;
  final List<String> redFlags;
  final String disclaimer;
  final String provider;

  const AiTriageResult({
    required this.urgencyLevel,
    required this.summary,
    required this.recommendedAction,
    required this.suggestedSpecialty,
    required this.redFlags,
    required this.disclaimer,
    required this.provider,
  });

  factory AiTriageResult.fromJson(Map<String, dynamic> json) {
    return AiTriageResult(
      urgencyLevel: json['urgencyLevel'] as String? ?? 'MEDIUM',
      summary: json['summary'] as String? ?? '',
      recommendedAction: json['recommendedAction'] as String? ?? '',
      suggestedSpecialty: json['suggestedSpecialty'] as String? ?? 'General Physician',
      redFlags: (json['redFlags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      disclaimer: json['disclaimer'] as String? ?? '',
      provider: json['provider'] as String? ?? 'groq',
    );
  }
}
