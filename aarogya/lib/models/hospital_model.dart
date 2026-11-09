class HospitalModel {
  final String id;
  final String name;
  final String licenseNumber;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String contactPhone;
  final String emergencyPhone;
  final int availableIcuBeds;
  final int totalIcuBeds;
  final int availableNormalBeds;
  final int totalNormalBeds;
  final bool hasEmergencyBay;
  final bool hasTraumaCenter;
  final double? distanceKm;
  final int? occupancyRateIcu;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.licenseNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.contactPhone,
    required this.emergencyPhone,
    required this.availableIcuBeds,
    required this.totalIcuBeds,
    required this.availableNormalBeds,
    required this.totalNormalBeds,
    required this.hasEmergencyBay,
    required this.hasTraumaCenter,
    this.distanceKm,
    this.occupancyRateIcu,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Hospital',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 28.5672,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.2100,
      contactPhone: json['contactPhone']?.toString() ?? '',
      emergencyPhone: json['emergencyPhone']?.toString() ?? '102',
      availableIcuBeds: (json['availableIcuBeds'] as num?)?.toInt() ?? 0,
      totalIcuBeds: (json['totalIcuBeds'] as num?)?.toInt() ?? 0,
      availableNormalBeds: (json['availableNormalBeds'] as num?)?.toInt() ?? 0,
      totalNormalBeds: (json['totalNormalBeds'] as num?)?.toInt() ?? 0,
      hasEmergencyBay: json['hasEmergencyBay'] == true,
      hasTraumaCenter: json['hasTraumaCenter'] == true,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      occupancyRateIcu: (json['occupancyRateIcu'] as num?)?.toInt(),
    );
  }
}

