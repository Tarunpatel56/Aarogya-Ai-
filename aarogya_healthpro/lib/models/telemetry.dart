class HeartRatePoint {
  final String timeLabel;
  final double bpm;
  final bool isExertion;
  final String? note;

  const HeartRatePoint({
    required this.timeLabel,
    required this.bpm,
    this.isExertion = false,
    this.note,
  });
}

class MedicationItem {
  final String id;
  final String name;
  final String dosage;
  final String timingCategory;
  final String scheduleTime;
  final int adherencePercentage;
  final String statusSubtitle;
  bool isLogged;

  MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.timingCategory,
    required this.scheduleTime,
    required this.adherencePercentage,
    required this.statusSubtitle,
    this.isLogged = false,
  });
}

class ClinicalSoapNote {
  final String id;
  final String date;
  final String encounterType;
  final String doctor;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;
  final String summaryText;
  final String? loincCode;
  final String emrSync;

  const ClinicalSoapNote({
    required this.id,
    required this.date,
    required this.encounterType,
    required this.doctor,
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
    required this.summaryText,
    this.loincCode,
    this.emrSync = 'Apollo HealthCity EMR Sync',
  });
}
