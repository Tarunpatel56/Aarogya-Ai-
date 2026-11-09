class DoctorModel {
  final String id;
  final String fullName;
  final String specialization;
  final String qualifications;
  final int experienceYears;
  final double consultationFee;
  final String? bio;
  final List<String> languages;
  final List<String> consultationModes;
  final String? clinicAddress;
  final String? hospitalAffiliation;
  final DateTime? verifiedAt;
  final bool isOnline;

  const DoctorModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.qualifications,
    required this.experienceYears,
    required this.consultationFee,
    this.bio,
    this.languages = const ['English', 'Hindi'],
    this.consultationModes = const ['IN_PERSON', 'ONLINE'],
    this.clinicAddress,
    this.hospitalAffiliation,
    this.verifiedAt,
    this.isOnline = true,
  });

  bool get isVerified => verifiedAt != null;

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      qualifications: json['qualifications']?.toString() ?? '',
      experienceYears: json['experienceYears'] is num
          ? (json['experienceYears'] as num).toInt()
          : int.tryParse(json['experienceYears']?.toString() ?? '0') ?? 0,
      consultationFee: json['consultationFee'] is num
          ? (json['consultationFee'] as num).toDouble()
          : double.tryParse(json['consultationFee']?.toString() ?? '0') ?? 0.0,
      bio: json['bio']?.toString(),
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['English', 'Hindi'],
      consultationModes: (json['consultationModes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['IN_PERSON', 'ONLINE'],
      clinicAddress: json['clinicAddress']?.toString(),
      hospitalAffiliation: json['hospitalAffiliation']?.toString(),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      isOnline: json['isOnline'] == true || json['isOnline'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'specialization': specialization,
      'qualifications': qualifications,
      'experienceYears': experienceYears,
      'consultationFee': consultationFee,
      'bio': bio,
      'languages': languages,
      'consultationModes': consultationModes,
      'clinicAddress': clinicAddress,
      'hospitalAffiliation': hospitalAffiliation,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }
}

class DoctorAvailabilityModel {
  final String id;
  final String doctorProfileId;
  final DateTime startTime;
  final DateTime endTime;
  final String timeZone;
  final String status;
  final bool isRecurring;
  final int? dayOfWeek;

  const DoctorAvailabilityModel({
    required this.id,
    required this.doctorProfileId,
    required this.startTime,
    required this.endTime,
    this.timeZone = 'Asia/Kolkata',
    this.status = 'AVAILABLE',
    this.isRecurring = false,
    this.dayOfWeek,
  });

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityModel(
      id: json['id']?.toString() ?? '',
      doctorProfileId: json['doctorProfileId']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now(),
      timeZone: json['timeZone']?.toString() ?? 'Asia/Kolkata',
      status: json['status']?.toString() ?? 'AVAILABLE',
      isRecurring: json['isRecurring'] == true,
      dayOfWeek: json['dayOfWeek'] is num
          ? (json['dayOfWeek'] as num).toInt()
          : int.tryParse(json['dayOfWeek']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorProfileId': doctorProfileId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'timeZone': timeZone,
      'status': status,
      'isRecurring': isRecurring,
      'dayOfWeek': dayOfWeek,
    };
  }
}
