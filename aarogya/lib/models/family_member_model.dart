class FamilyMemberModel {
  final String id;
  final String patientProfileId;
  final String fullName;
  final String relationship;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? allergies;
  final String? medicalHistory;
  final DateTime? createdAt;

  const FamilyMemberModel({
    required this.id,
    required this.patientProfileId,
    required this.fullName,
    required this.relationship,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.allergies,
    this.medicalHistory,
    this.createdAt,
  });

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id']?.toString() ?? '',
      patientProfileId: json['patientProfileId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? 'Family',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      allergies: json['allergies']?.toString(),
      medicalHistory: json['medicalHistory']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientProfileId': patientProfileId,
      'fullName': fullName,
      'relationship': relationship,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (gender != null) 'gender': gender,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (allergies != null) 'allergies': allergies,
      if (medicalHistory != null) 'medicalHistory': medicalHistory,
    };
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      a--;
    }
    return a;
  }
}

