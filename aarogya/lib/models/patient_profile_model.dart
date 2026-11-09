import 'family_member_model.dart';

class PatientProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String? gender;
  final String? bloodGroup;
  final String? abhaId;
  final String? allergies;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final DateTime? dateOfBirth;
  final double? height;
  final double? weight;
  final String? existingConditions;
  final String? currentMedications;
  final List<FamilyMemberModel> familyMembers;

  const PatientProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.gender,
    this.bloodGroup,
    this.abhaId,
    this.allergies,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.existingConditions,
    this.currentMedications,
    this.familyMembers = const [],
  });

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    var rawFamily = json['familyMembers'];
    List<FamilyMemberModel> members = [];
    if (rawFamily is List) {
      members = rawFamily
          .map((m) => FamilyMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return PatientProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      gender: json['gender']?.toString(),
      bloodGroup: json['bloodGroup']?.toString(),
      abhaId: json['abhaId']?.toString(),
      allergies: json['allergies']?.toString(),
      address: json['address']?.toString(),
      emergencyContactName: json['emergencyContactName']?.toString(),
      emergencyContactPhone: json['emergencyContactPhone']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      height: (json['height'] is num) ? (json['height'] as num).toDouble() : null,
      weight: (json['weight'] is num) ? (json['weight'] as num).toDouble() : null,
      existingConditions: json['existingConditions']?.toString(),
      currentMedications: json['currentMedications']?.toString(),
      familyMembers: members,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'abhaId': abhaId,
      'allergies': allergies,
      'address': address,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (existingConditions != null) 'existingConditions': existingConditions,
      if (currentMedications != null) 'currentMedications': currentMedications,
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

  PatientProfileModel copyWith({
    String? fullName,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? existingConditions,
    String? currentMedications,
    List<FamilyMemberModel>? familyMembers,
  }) {
    return PatientProfileModel(
      id: id,
      userId: userId,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      abhaId: abhaId,
      allergies: allergies ?? this.allergies,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      existingConditions: existingConditions ?? this.existingConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      familyMembers: familyMembers ?? this.familyMembers,
    );
  }
}
