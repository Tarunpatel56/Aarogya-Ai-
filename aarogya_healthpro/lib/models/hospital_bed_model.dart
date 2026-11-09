class HospitalBedModel {
  final String id;
  final String hospitalId;
  final String? departmentId;
  final String? departmentName;
  final String bedNumber;
  final String bedType;
  final String status;
  final String? occupiedByPatient;
  final String? notes;
  final DateTime? lastSanitizedAt;

  const HospitalBedModel({
    required this.id,
    required this.hospitalId,
    this.departmentId,
    this.departmentName,
    required this.bedNumber,
    required this.bedType,
    required this.status,
    this.occupiedByPatient,
    this.notes,
    this.lastSanitizedAt,
  });

  bool get isAvailable => status == 'AVAILABLE';
  bool get isIcu => bedType == 'ICU';

  factory HospitalBedModel.fromJson(Map<String, dynamic> json) {
    final dept = json['department'] as Map<String, dynamic>?;
    return HospitalBedModel(
      id: json['id']?.toString() ?? '',
      hospitalId: json['hospitalId']?.toString() ?? '',
      departmentId: json['departmentId']?.toString(),
      departmentName: dept?['name']?.toString() ?? json['departmentName']?.toString() ?? 'General Ward',
      bedNumber: json['bedNumber']?.toString() ?? '',
      bedType: json['bedType']?.toString() ?? 'NORMAL',
      status: json['status']?.toString() ?? 'AVAILABLE',
      occupiedByPatient: json['occupiedByPatient']?.toString(),
      notes: json['notes']?.toString(),
      lastSanitizedAt: json['lastSanitizedAt'] != null
          ? DateTime.tryParse(json['lastSanitizedAt'].toString())
          : null,
    );
  }
}

