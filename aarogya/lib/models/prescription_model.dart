class PrescriptionItemModel {
  final String id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? timing;
  final String? instructions;

  const PrescriptionItemModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    this.durationDays = 5,
    this.timing,
    this.instructions,
  });

  factory PrescriptionItemModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionItemModel(
      id: json['id']?.toString() ?? '',
      medicineName: json['medicineName']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '1 unit',
      frequency: json['frequency']?.toString() ?? 'Daily',
      durationDays: NumberParser.toInt(json['durationDays'], 5),
      timing: json['timing']?.toString(),
      instructions: json['instructions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'durationDays': durationDays,
      'timing': timing,
      'instructions': instructions,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String patientProfileId;
  final String doctorProfileId;
  final String? appointmentId;
  final String diagnosis;
  final String? doctorNotes;
  final String? generalAdvice;
  final DateTime? followUpDate;
  final String? digitalSignature;
  final DateTime createdAt;
  final List<PrescriptionItemModel> items;

  const PrescriptionModel({
    required this.id,
    required this.patientProfileId,
    required this.doctorProfileId,
    this.appointmentId,
    required this.diagnosis,
    this.doctorNotes,
    this.generalAdvice,
    this.followUpDate,
    this.digitalSignature,
    required this.createdAt,
    this.items = const [],
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PrescriptionModel(
      id: json['id']?.toString() ?? '',
      patientProfileId: json['patientProfileId']?.toString() ?? '',
      doctorProfileId: json['doctorProfileId']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString(),
      diagnosis: json['diagnosis']?.toString() ?? '',
      doctorNotes: json['doctorNotes']?.toString(),
      generalAdvice: json['generalAdvice']?.toString(),
      followUpDate: json['followUpDate'] != null ? DateTime.tryParse(json['followUpDate'].toString()) : null,
      digitalSignature: json['digitalSignature']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: rawItems.map((e) => PrescriptionItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class NumberParser {
  static int toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

