class PhysioSessionReport {
  final String id;
  final String patientId;
  final String exerciseId;
  final String exerciseTitle;
  final int targetReps;
  final int completedReps;
  final int durationSeconds;
  final double formAccuracyScore; // 0 - 100%
  final double minJointAngle;
  final double maxJointAngle;
  final double avgJointAngle;
  final List<String> detectedPostureErrors;
  final int painRatingVAS; // 0-10
  final String difficultyFeedback;
  final String completionStatus; // 'COMPLETED', 'PARTIAL', 'DISCONTINUED'
  final DateTime completedAt;
  final bool syncedToDoctorPortal;

  const PhysioSessionReport({
    required this.id,
    required this.patientId,
    required this.exerciseId,
    required this.exerciseTitle,
    required this.targetReps,
    required this.completedReps,
    required this.durationSeconds,
    required this.formAccuracyScore,
    required this.minJointAngle,
    required this.maxJointAngle,
    required this.avgJointAngle,
    required this.detectedPostureErrors,
    required this.painRatingVAS,
    required this.difficultyFeedback,
    required this.completionStatus,
    required this.completedAt,
    this.syncedToDoctorPortal = false,
  });

  factory PhysioSessionReport.fromJson(Map<String, dynamic> json) {
    return PhysioSessionReport(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? '',
      exerciseTitle: json['exerciseTitle']?.toString() ?? 'Exercise Session',
      targetReps: (json['targetReps'] as num?)?.toInt() ?? 10,
      completedReps: (json['completedReps'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      formAccuracyScore: (json['formAccuracyScore'] as num?)?.toDouble() ?? 85.0,
      minJointAngle: (json['minJointAngle'] as num?)?.toDouble() ?? 0.0,
      maxJointAngle: (json['maxJointAngle'] as num?)?.toDouble() ?? 180.0,
      avgJointAngle: (json['avgJointAngle'] as num?)?.toDouble() ?? 90.0,
      detectedPostureErrors: (json['detectedPostureErrors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      painRatingVAS: (json['painRatingVAS'] as num?)?.toInt() ?? 0,
      difficultyFeedback: json['difficultyFeedback']?.toString() ?? 'Just Right',
      completionStatus: json['completionStatus']?.toString() ?? 'COMPLETED',
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
      syncedToDoctorPortal: json['syncedToDoctorPortal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'exerciseId': exerciseId,
        'exerciseTitle': exerciseTitle,
        'targetReps': targetReps,
        'completedReps': completedReps,
        'durationSeconds': durationSeconds,
        'formAccuracyScore': formAccuracyScore,
        'minJointAngle': minJointAngle,
        'maxJointAngle': maxJointAngle,
        'avgJointAngle': avgJointAngle,
        'detectedPostureErrors': detectedPostureErrors,
        'painRatingVAS': painRatingVAS,
        'difficultyFeedback': difficultyFeedback,
        'completionStatus': completionStatus,
        'completedAt': completedAt.toIso8601String(),
        'syncedToDoctorPortal': syncedToDoctorPortal,
      };
}

