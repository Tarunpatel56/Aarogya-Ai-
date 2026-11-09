class EmergencyModel {
  final String id;
  final String patientProfileId;
  final double latitude;
  final double longitude;
  final String? pickupAddress;
  final String? assignedHospitalId;
  final String? hospitalName;
  final String? assignedVehicleNo;
  final String status;
  final int estimatedMinutes;
  final double? driverLatitude;
  final double? driverLongitude;
  final String? patientName;
  final String? patientPhone;
  final String? emergencyHotline;
  final String? driverName;
  final String? driverPhone;
  final DateTime createdAt;

  const EmergencyModel({
    required this.id,
    required this.patientProfileId,
    required this.latitude,
    required this.longitude,
    this.pickupAddress,
    this.assignedHospitalId,
    this.hospitalName,
    this.assignedVehicleNo,
    required this.status,
    required this.estimatedMinutes,
    this.driverLatitude,
    this.driverLongitude,
    this.patientName,
    this.patientPhone,
    this.emergencyHotline,
    this.driverName,
    this.driverPhone,
    required this.createdAt,
  });

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['id']?.toString() ?? '',
      patientProfileId: json['patientProfileId']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 28.5672,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.2100,
      pickupAddress: json['pickupAddress']?.toString(),
      assignedHospitalId: json['assignedHospitalId']?.toString(),
      hospitalName: json['hospitalName']?.toString() ?? 'Emergency Trauma Bay',
      assignedVehicleNo: json['assignedVehicleNo']?.toString() ?? 'DL-01-AMB-2401',
      status: json['status']?.toString() ?? 'REQUESTED',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 8,
      driverLatitude: (json['driverLatitude'] as num?)?.toDouble(),
      driverLongitude: (json['driverLongitude'] as num?)?.toDouble(),
      patientName: json['patientName']?.toString(),
      patientPhone: json['patientPhone']?.toString(),
      emergencyHotline: json['emergencyHotline']?.toString() ?? '102',
      driverName: json['driverName']?.toString() ?? 'Paramedic Lead',
      driverPhone: json['driverPhone']?.toString() ?? '+91-9876543210',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isActive =>
      status == 'REQUESTED' ||
      status == 'SEARCHING' ||
      status == 'ASSIGNED' ||
      status == 'EN_ROUTE' ||
      status == 'PATIENT_ON_BOARD';

  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED' || status == 'REACHED_HOSPITAL';

  EmergencyModel copyWith({
    String? id,
    String? patientProfileId,
    double? latitude,
    double? longitude,
    String? pickupAddress,
    String? assignedHospitalId,
    String? hospitalName,
    String? assignedVehicleNo,
    String? status,
    int? estimatedMinutes,
    double? driverLatitude,
    double? driverLongitude,
    String? patientName,
    String? patientPhone,
    String? emergencyHotline,
    String? driverName,
    String? driverPhone,
    DateTime? createdAt,
  }) {
    return EmergencyModel(
      id: id ?? this.id,
      patientProfileId: patientProfileId ?? this.patientProfileId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      assignedHospitalId: assignedHospitalId ?? this.assignedHospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      assignedVehicleNo: assignedVehicleNo ?? this.assignedVehicleNo,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      emergencyHotline: emergencyHotline ?? this.emergencyHotline,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

