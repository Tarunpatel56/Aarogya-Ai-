class LabTestParameter {
  final String testName;
  final String observedValue;
  final String standardRange;
  final String unit;
  final String status; // NORMAL, HIGH, LOW, CRITICAL

  const LabTestParameter({
    required this.testName,
    required this.observedValue,
    required this.standardRange,
    required this.unit,
    required this.status,
  });

  bool get isAbnormal => status != 'NORMAL';
  bool get isHigh => status == 'HIGH';
  bool get isLow => status == 'LOW';
  bool get isCritical => status == 'CRITICAL';

  factory LabTestParameter.fromJson(Map<String, dynamic> json) {
    return LabTestParameter(
      testName: json['testName']?.toString() ?? '',
      observedValue: json['observedValue']?.toString() ?? '',
      standardRange: json['standardRange']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NORMAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'observedValue': observedValue,
      'standardRange': standardRange,
      'unit': unit,
      'status': status,
    };
  }
}

class MedicalReportAnalysisResult {
  final String reportCategory;
  final String? patientNameVisible;
  final String? reportDateVisible;
  final List<LabTestParameter> extractedParameters;
  final List<LabTestParameter> outOfRangeParameters;
  final String findingsSummary;
  final String plainLanguageExplanation;
  final String recommendedSpecialty;
  final List<String> suggestedQuestionsForDoctor;
  final String clinicalDisclaimer;
  final String language;

  const MedicalReportAnalysisResult({
    required this.reportCategory,
    this.patientNameVisible,
    this.reportDateVisible,
    required this.extractedParameters,
    required this.outOfRangeParameters,
    required this.findingsSummary,
    required this.plainLanguageExplanation,
    required this.recommendedSpecialty,
    required this.suggestedQuestionsForDoctor,
    required this.clinicalDisclaimer,
    required this.language,
  });

  factory MedicalReportAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MedicalReportAnalysisResult(
      reportCategory: json['reportCategory']?.toString() ?? 'Diagnostic Laboratory Report',
      patientNameVisible: json['patientNameVisible']?.toString(),
      reportDateVisible: json['reportDateVisible']?.toString(),
      extractedParameters: (json['extractedParameters'] as List<dynamic>?)
              ?.map((e) => LabTestParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      outOfRangeParameters: (json['outOfRangeParameters'] as List<dynamic>?)
              ?.map((e) => LabTestParameter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      findingsSummary: json['findingsSummary']?.toString() ?? '',
      plainLanguageExplanation: json['plainLanguageExplanation']?.toString() ?? '',
      recommendedSpecialty: json['recommendedSpecialty']?.toString() ?? 'General Physician',
      suggestedQuestionsForDoctor: (json['suggestedQuestionsForDoctor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      clinicalDisclaimer: json['clinicalDisclaimer']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
    );
  }
}

