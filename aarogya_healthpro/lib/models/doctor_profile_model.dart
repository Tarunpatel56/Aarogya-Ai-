class DoctorProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String specialization;
  final String medicalLicenseNumber;
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

  const DoctorProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.specialization,
    required this.medicalLicenseNumber,
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
  String get nmcRegistrationNumber => medicalLicenseNumber;

  factory DoctorProfileModel.fromJson(Map<String, dynamic> rawJson) {
    final json = rawJson.containsKey('profile') && rawJson['profile'] is Map<String, dynamic>
        ? rawJson['profile'] as Map<String, dynamic>
        : (rawJson.containsKey('doctor') && rawJson['doctor'] is Map<String, dynamic>
            ? rawJson['doctor'] as Map<String, dynamic>
            : rawJson);

    return DoctorProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      medicalLicenseNumber: json['medicalLicenseNumber']?.toString() ??
          json['nmcRegistrationNumber']?.toString() ??
          '',
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
          const ['English', 'Hindi'],
      consultationModes: (json['consultationModes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['IN_PERSON', 'ONLINE'],
      clinicAddress: json['clinicAddress']?.toString(),
      hospitalAffiliation: json['hospitalAffiliation']?.toString(),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : (json['user'] != null && json['user']['verificationStatus'] == 'VERIFIED'
              ? DateTime.now()
              : null),
      isOnline: json['isOnline'] == true || json['isOnline'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'specialization': specialization,
      'medicalLicenseNumber': medicalLicenseNumber,
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
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, etc.
  final DateTime startTime;
  final DateTime endTime;
  final String status; // 'AVAILABLE' | 'UNAVAILABLE'

  const DoctorAvailabilityModel({
    required this.id,
    required this.doctorProfileId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory DoctorAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilityModel(
      id: json['id']?.toString() ?? '',
      doctorProfileId: json['doctorProfileId']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek'] is int
          ? json['dayOfWeek'] as int
          : int.tryParse(json['dayOfWeek']?.toString() ?? '0') ?? 0,
      startTime: DateTime.parse(json['startTime'].toString()),
      endTime: DateTime.parse(json['endTime'].toString()),
      status: json['status']?.toString() ?? 'AVAILABLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorProfileId': doctorProfileId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
    };
  }
}
