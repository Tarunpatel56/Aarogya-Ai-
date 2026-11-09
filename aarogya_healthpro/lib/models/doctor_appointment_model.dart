class PatientVitalReading {
  final String id;
  final String metricType;
  final double metricValue;
  final double? secondaryValue;
  final String unit;
  final DateTime measuredAt;
  final String? source;

  const PatientVitalReading({
    required this.id,
    required this.metricType,
    required this.metricValue,
    this.secondaryValue,
    required this.unit,
    required this.measuredAt,
    this.source,
  });

  factory PatientVitalReading.fromJson(Map<String, dynamic> json) {
    return PatientVitalReading(
      id: json['id']?.toString() ?? '',
      metricType: json['metricType']?.toString() ?? json['type']?.toString() ?? 'VITAL',
      metricValue: (json['metricValue'] as num?)?.toDouble() ??
          (json['value'] as num?)?.toDouble() ??
          0.0,
      secondaryValue: (json['secondaryValue'] as num?)?.toDouble(),
      unit: json['unit']?.toString() ?? '',
      measuredAt: DateTime.tryParse(json['measuredAt']?.toString() ?? '') ?? DateTime.now(),
      source: json['source']?.toString(),
    );
  }
}

class PatientMedicalRecord {
  final String id;
  final String title;
  final String recordType;
  final String? description;
  final DateTime recordDate;
  final String? issuingDoctor;
  final String? facilityName;

  const PatientMedicalRecord({
    required this.id,
    required this.title,
    required this.recordType,
    this.description,
    required this.recordDate,
    this.issuingDoctor,
    this.facilityName,
  });

  factory PatientMedicalRecord.fromJson(Map<String, dynamic> json) {
    return PatientMedicalRecord(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Medical Document',
      recordType: json['recordType']?.toString() ?? 'GENERAL',
      description: json['description']?.toString(),
      recordDate: DateTime.tryParse(json['recordDate']?.toString() ?? '') ?? DateTime.now(),
      issuingDoctor: json['issuingDoctor']?.toString(),
      facilityName: json['facilityName']?.toString(),
    );
  }
}

class PatientInfoModel {
  final String id;
  final String fullName;
  final String? gender;
  final String? bloodGroup;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? allergies;
  final String? address;
  final String? emergencyContact;
  final List<PatientVitalReading> vitalReadings;
  final List<PatientMedicalRecord> medicalRecords;

  const PatientInfoModel({
    required this.id,
    required this.fullName,
    this.gender,
    this.bloodGroup,
    this.dateOfBirth,
    this.phoneNumber,
    this.allergies,
    this.address,
    this.emergencyContact,
    this.vitalReadings = const [],
    this.medicalRecords = const [],
  });

  factory PatientInfoModel.fromJson(Map<String, dynamic> json) {
    final vitalsRaw = json['vitalReadings'] as List<dynamic>? ?? [];
    final recordsRaw = json['medicalRecords'] as List<dynamic>? ?? [];

    return PatientInfoModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Unknown Patient',
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      phoneNumber: json['phoneNumber']?.toString() ??
          json['user']?['phone']?.toString() ??
          json['user']?['phoneNumber']?.toString(),
      allergies: json['allergies']?.toString(),
      address: json['address']?.toString(),
      emergencyContact: json['emergencyContactPhone']?.toString() ??
          json['emergencyContactName']?.toString(),
      vitalReadings: vitalsRaw
          .map((v) => PatientVitalReading.fromJson(v as Map<String, dynamic>))
          .toList(),
      medicalRecords: recordsRaw
          .map((r) => PatientMedicalRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DoctorAppointmentModel {
  final String id;
  final String patientProfileId;
  final String doctorProfileId;
  final DateTime startTime;
  final DateTime endTime;
  final String mode; // 'IN_PERSON' | 'ONLINE'
  final String status; // 'REQUESTED' | 'CONFIRMED' | 'REJECTED' | 'CANCELLED' | 'COMPLETED' | 'NO_SHOW'
  final String? reason;
  final String? notes;
  final String? cancellationReason;
  final PatientInfoModel? patient;
  final DateTime? createdAt;
  final double consultationFee;

  const DoctorAppointmentModel({
    required this.id,
    required this.patientProfileId,
    required this.doctorProfileId,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.status,
    this.reason,
    this.notes,
    this.cancellationReason,
    this.patient,
    this.createdAt,
    this.consultationFee = 500.0,
  });

  bool get isRequested => status == 'REQUESTED';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isRejected => status == 'REJECTED';
  bool get isNoShow => status == 'NO_SHOW';

  bool get canConfirm => isRequested;
  bool get canReject => isRequested;
  bool get canComplete => isConfirmed;
  bool get canMarkNoShow => isConfirmed;
  bool get canCancel => isRequested || isConfirmed;

  factory DoctorAppointmentModel.fromJson(Map<String, dynamic> json) {
    final fee = (json['doctorProfile']?['consultationFee'] as num?)?.toDouble() ??
        (json['consultationFee'] as num?)?.toDouble() ??
        500.0;

    return DoctorAppointmentModel(
      id: json['id']?.toString() ?? '',
      patientProfileId: json['patientProfileId']?.toString() ?? '',
      doctorProfileId: json['doctorProfileId']?.toString() ?? '',
      startTime: DateTime.parse(json['startTime'].toString()),
      endTime: DateTime.parse(json['endTime'].toString()),
      mode: json['mode']?.toString() ?? json['consultationMode']?.toString() ?? 'IN_PERSON',
      status: json['status']?.toString() ?? 'REQUESTED',
      reason: json['reason']?.toString(),
      notes: json['notes']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      patient: json['patient'] != null
          ? PatientInfoModel.fromJson(json['patient'] as Map<String, dynamic>)
          : (json['patientProfile'] != null
              ? PatientInfoModel.fromJson(json['patientProfile'] as Map<String, dynamic>)
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      consultationFee: fee,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientProfileId': patientProfileId,
      'doctorProfileId': doctorProfileId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'mode': mode,
      'status': status,
      'reason': reason,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt?.toIso8601String(),
      'consultationFee': consultationFee,
    };
  }
}
