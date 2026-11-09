class MedicalPrediction {
  final String label;
  final String normalizedLabel;
  final double score;
  final String? description;

  const MedicalPrediction({
    required this.label,
    required this.normalizedLabel,
    required this.score,
    this.description,
  });

  String get formattedConfidence => '${(score * 100).toStringAsFixed(1)}%';

  factory MedicalPrediction.fromJson(Map<String, dynamic> json) {
    return MedicalPrediction(
      label: json['label']?.toString() ?? '',
      normalizedLabel: json['normalizedLabel']?.toString() ?? json['label']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ??
          (json['confidence'] as num?)?.toDouble() ??
          0.0,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'normalizedLabel': normalizedLabel,
      'score': score,
      if (description != null) 'description': description,
    };
  }
}

class MedicalAnalysisResult {
  final String analysisType;
  final String provider;
  final String model;
  final MedicalPrediction primaryFinding;
  final List<MedicalPrediction> allPredictions;
  final String findingsSummary;
  final String clinicalDisclaimer;
  final String? mandatoryClinicalNotice;
  final DateTime analyzedAt;
  final List<String> observations;
  final List<String> possibleAbnormalities;
  final String? clinicalExplanation;
  final String? doctorRecommendation;
  final String? language;

  const MedicalAnalysisResult({
    required this.analysisType,
    required this.provider,
    required this.model,
    required this.primaryFinding,
    required this.allPredictions,
    required this.findingsSummary,
    required this.clinicalDisclaimer,
    this.mandatoryClinicalNotice,
    required this.analyzedAt,
    this.observations = const [],
    this.possibleAbnormalities = const [],
    this.clinicalExplanation,
    this.doctorRecommendation,
    this.language,
  });

  bool get isNormal {
    final lower = primaryFinding.normalizedLabel.toLowerCase();
    return lower.contains('normal') ||
        lower.contains('no tumor') ||
        lower.contains('सामान्य') ||
        lower.contains('कोई ट्यूमर नहीं');
  }

  factory MedicalAnalysisResult.fromJson(Map<String, dynamic> json) {
    final primaryMap = json['primaryFinding'] is Map<String, dynamic>
        ? json['primaryFinding'] as Map<String, dynamic>
        : <String, dynamic>{};

    final predictionsList = (json['allPredictions'] as List?)
            ?.map((e) => MedicalPrediction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    DateTime parsedDate;
    try {
      parsedDate = json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final obs = (json['observations'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final abn = (json['possibleAbnormalities'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final exp = json['clinicalExplanation']?.toString();
    final rec = json['doctorRecommendation']?.toString();
    final lang = json['language']?.toString();

    return MedicalAnalysisResult(
      analysisType: json['analysisType']?.toString() ?? 'UNKNOWN',
      provider: json['provider']?.toString() ?? 'Aarogya Medical AI',
      model: json['model']?.toString() ?? '',
      primaryFinding: MedicalPrediction.fromJson(primaryMap),
      allPredictions: predictionsList,
      findingsSummary: json['findingsSummary']?.toString() ?? '',
      clinicalDisclaimer: json['clinicalDisclaimer']?.toString() ??
          'AI medical analysis is an assistive screening aid and requires certified clinical review.',
      mandatoryClinicalNotice: json['mandatoryClinicalNotice']?.toString(),
      analyzedAt: parsedDate,
      observations: obs,
      possibleAbnormalities: abn,
      clinicalExplanation: exp,
      doctorRecommendation: rec,
      language: lang,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysisType': analysisType,
      'provider': provider,
      'model': model,
      'primaryFinding': primaryFinding.toJson(),
      'allPredictions': allPredictions.map((p) => p.toJson()).toList(),
      'findingsSummary': findingsSummary,
      'clinicalDisclaimer': clinicalDisclaimer,
      if (mandatoryClinicalNotice != null)
        'mandatoryClinicalNotice': mandatoryClinicalNotice,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }
}

