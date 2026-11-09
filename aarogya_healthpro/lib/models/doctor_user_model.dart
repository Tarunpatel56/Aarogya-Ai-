class DoctorUserModel {
  final String id;
  final String email;
  final String role;
  final String? phoneNumber;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? createdAt;

  const DoctorUserModel({
    required this.id,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.createdAt,
  });

  factory DoctorUserModel.fromJson(Map<String, dynamic> json) {
    return DoctorUserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'DOCTOR',
      phoneNumber: json['phoneNumber']?.toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      isPhoneVerified: json['isPhoneVerified'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
