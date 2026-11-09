class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String role;
  final String? effectiveRole;
  final String verificationStatus;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    this.effectiveRole,
    required this.verificationStatus,
    this.isActive = true,
  });

  String get canonicalRole => effectiveRole ?? role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'PATIENT',
      effectiveRole: json['effectiveRole']?.toString() ?? json['role']?.toString(),
      verificationStatus: json['verificationStatus']?.toString() ?? 'PENDING',
      isActive: json['isActive'] == true || json['isActive'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role,
      'effectiveRole': effectiveRole ?? role,
      'verificationStatus': verificationStatus,
      'isActive': isActive,
    };
  }
}
