enum MedicineDoseTime {
  morning,
  afternoon,
  evening,
  night,
}

enum MealTiming {
  beforeFood,
  withFood,
  afterFood,
}

enum DoseStatus {
  pending,
  taken,
  skipped,
  snoozed,
}

class MedicineReminder {
  final String id;
  final String medicineName;
  final String dosage;
  final MedicineDoseTime doseTime;
  final MealTiming mealTiming;
  final String timeString; // e.g. "08:00 AM"
  final String? instructions;
  final bool isActive;
  final DoseStatus status;
  final DateTime? lastTakenAt;
  final int remainingPills;
  final int refillThreshold;

  const MedicineReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.doseTime,
    required this.mealTiming,
    required this.timeString,
    this.instructions,
    this.isActive = true,
    this.status = DoseStatus.pending,
    this.lastTakenAt,
    this.remainingPills = 28,
    this.refillThreshold = 5,
  });

  String get doseTimeLabel {
    switch (doseTime) {
      case MedicineDoseTime.morning:
        return 'Morning';
      case MedicineDoseTime.afternoon:
        return 'Afternoon';
      case MedicineDoseTime.evening:
        return 'Evening';
      case MedicineDoseTime.night:
        return 'Night';
    }
  }

  String get mealTimingLabel {
    switch (mealTiming) {
      case MealTiming.beforeFood:
        return 'Before Food';
      case MealTiming.withFood:
        return 'With Food';
      case MealTiming.afterFood:
        return 'After Food';
    }
  }

  MedicineReminder copyWith({
    String? id,
    String? medicineName,
    String? dosage,
    MedicineDoseTime? doseTime,
    MealTiming? mealTiming,
    String? timeString,
    String? instructions,
    bool? isActive,
    DoseStatus? status,
    DateTime? lastTakenAt,
    int? remainingPills,
    int? refillThreshold,
  }) {
    return MedicineReminder(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      doseTime: doseTime ?? this.doseTime,
      mealTiming: mealTiming ?? this.mealTiming,
      timeString: timeString ?? this.timeString,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      lastTakenAt: lastTakenAt ?? this.lastTakenAt,
      remainingPills: remainingPills ?? this.remainingPills,
      refillThreshold: refillThreshold ?? this.refillThreshold,
    );
  }

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id'] as String,
      medicineName: json['medicineName'] as String,
      dosage: json['dosage'] as String? ?? '1 Tablet',
      doseTime: MedicineDoseTime.values.firstWhere(
        (e) => e.name == json['doseTime'],
        orElse: () => MedicineDoseTime.morning,
      ),
      mealTiming: MealTiming.values.firstWhere(
        (e) => e.name == json['mealTiming'],
        orElse: () => MealTiming.afterFood,
      ),
      timeString: json['timeString'] as String? ?? '08:00 AM',
      instructions: json['instructions'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      status: DoseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DoseStatus.pending,
      ),
      lastTakenAt: json['lastTakenAt'] != null
          ? DateTime.tryParse(json['lastTakenAt'].toString())
          : null,
      remainingPills: json['remainingPills'] as int? ?? 28,
      refillThreshold: json['refillThreshold'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineName': medicineName,
      'dosage': dosage,
      'doseTime': doseTime.name,
      'mealTiming': mealTiming.name,
      'timeString': timeString,
      if (instructions != null) 'instructions': instructions,
      'isActive': isActive,
      'status': status.name,
      if (lastTakenAt != null) 'lastTakenAt': lastTakenAt!.toIso8601String(),
      'remainingPills': remainingPills,
      'refillThreshold': refillThreshold,
    };
  }
}
