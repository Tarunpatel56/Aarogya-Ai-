class ClinicalCoPilotInsight {
  final String clinicalSummary;
  final String riskAssessment; // 'STABLE' | 'OBSERVATION_REQUIRED' | 'CRITICAL'
  final List<String> suggestedInterventions;
  final List<String> vitalAnomalies;
  final String provider;
  final String model;

  const ClinicalCoPilotInsight({
    required this.clinicalSummary,
    required this.riskAssessment,
    required this.suggestedInterventions,
    required this.vitalAnomalies,
    required this.provider,
    required this.model,
  });

  factory ClinicalCoPilotInsight.fromJson(Map<String, dynamic> json) {
    return ClinicalCoPilotInsight(
      clinicalSummary: json['clinicalSummary'] as String? ??
          'Patient vitals and clinical history reviewed.',
      riskAssessment: json['riskAssessment'] as String? ?? 'STABLE',
      suggestedInterventions: (json['suggestedInterventions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      vitalAnomalies: (json['vitalAnomalies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      provider: json['provider'] as String? ?? 'groq',
      model: json['model'] as String? ?? '',
    );
  }
}
