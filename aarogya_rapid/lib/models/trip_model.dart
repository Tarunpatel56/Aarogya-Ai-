class Medication {
  final String name;
  final String dosage;
  final String timing;
  final String category;

  const Medication({
    required this.name,
    required this.dosage,
    required this.timing,
    required this.category,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name']?.toString() ?? 'Medication',
      dosage: json['dosage']?.toString() ?? 'As advised',
      timing: json['timing']?.toString() ?? 'Daily',
      category: json['category']?.toString() ?? 'General',
    );
  }
}

class EmergencyRequest {
  final String id;
  final String tier;
  final bool isCritical;
  final String title;
  final String triggeredAgo;
  final String patientName;
  final String patientGender;
  final int patientAge;
  final String abhaId;
  final String bloodGroup;
  final String pickupAddress;
  final String pickupLandmark;
  final double latitude;
  final double longitude;
  final double? driverLatitude;
  final double? driverLongitude;
  final String status;
  final String? assignedVehicleNo;
  final String distance;
  final String eta;
  final String primaryContactName;
  final String primaryContactPhone;
  final String wearableDevice;
  final int heartRate;
  final int spo2;
  final String bloodPressure;
  final int steps;
  final String ecgObservation;
  final String reportedEmergency;
  final String emergencyDetails;
  final String receivingHospital;
  final String hospitalBay;
  final String assignedDoctor;
  final String doctorAckTime;
  final String allergyName;
  final String allergyReaction;
  final String allergyContraindications;
  final List<String> diagnoses;
  final List<Medication> medications;
  final String sbarSituation;
  final String sbarBackground;
  final String sbarAssessment;
  final String sbarRecommendation;
  final String enrouteInterventions;
  final DateTime createdAt;

  const EmergencyRequest({
    required this.id,
    required this.tier,
    required this.isCritical,
    required this.title,
    required this.triggeredAgo,
    required this.patientName,
    required this.patientGender,
    required this.patientAge,
    required this.abhaId,
    this.bloodGroup = 'O+',
    required this.pickupAddress,
    required this.pickupLandmark,
    this.latitude = 28.5672,
    this.longitude = 77.2100,
    this.driverLatitude,
    this.driverLongitude,
    this.status = 'REQUESTED',
    this.assignedVehicleNo,
    required this.distance,
    required this.eta,
    required this.primaryContactName,
    required this.primaryContactPhone,
    this.wearableDevice = 'Fire-Boltt Watch Live',
    this.heartRate = 78,
    this.spo2 = 98,
    this.bloodPressure = '120/80 mmHg',
    this.steps = 3400,
    this.ecgObservation = 'Field observation normal',
    required this.reportedEmergency,
    this.emergencyDetails = '',
    this.receivingHospital = 'Aarogya Partner Hospital',
    this.hospitalBay = 'Trauma Resuscitation Bay 1',
    this.assignedDoctor = 'Duty Emergency Physician',
    this.doctorAckTime = 'Confirmed',
    this.allergyName = 'None reported',
    this.allergyReaction = 'None',
    this.allergyContraindications = 'None',
    this.diagnoses = const [],
    this.medications = const [],
    this.sbarSituation = '',
    this.sbarBackground = '',
    this.sbarAssessment = '',
    this.sbarRecommendation = '',
    this.enrouteInterventions = '',
    required this.createdAt,
  });

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    final patient = json['patientProfile'] as Map<String, dynamic>? ?? {};
    final user = patient['user'] as Map<String, dynamic>? ?? {};
    final status = json['status']?.toString() ?? 'REQUESTED';
    final isCritical = status == 'REQUESTED' || status == 'SEARCHING' || status == 'ASSIGNED' || status == 'EN_ROUTE';

    final patientName = patient['fullName']?.toString() ??
        json['patientName']?.toString() ??
        'Emergency Patient';

    final age = patient['age'] is int
        ? patient['age'] as int
        : (patient['dateOfBirth'] != null ? 35 : (json['patientAge'] is int ? json['patientAge'] as int : 32));

    final phone = user['phone']?.toString() ??
        patient['emergencyContactPhone']?.toString() ??
        patient['phone']?.toString() ??
        json['primaryContactPhone']?.toString() ??
        json['patientPhone']?.toString() ??
        '+91 98765-43210';

    final address = json['pickupAddress']?.toString() ?? 'Current Patient GPS Coordinates';
    final hospitalName = json['hospitalName']?.toString() ?? 'AIIMS Emergency Trauma Bay';
    final etaMins = (json['estimatedMinutes'] as num?)?.toInt() ?? 6;

    final lat = (json['latitude'] as num?)?.toDouble() ?? 28.5672;
    final lng = (json['longitude'] as num?)?.toDouble() ?? 77.2100;
    final dLat = (json['driverLatitude'] as num?)?.toDouble();
    final dLng = (json['driverLongitude'] as num?)?.toDouble();

    // Vitals extraction from vitalsSnapshot or smartwatch telemetry
    final vitals = json['vitalsSnapshot'] as Map<String, dynamic>? ?? {};
    final hr = (vitals['heartRate'] as num?)?.toInt() ??
        (vitals['hr'] as num?)?.toInt() ??
        (json['heartRate'] as num?)?.toInt() ??
        82;
    final sp = (vitals['spo2'] as num?)?.toInt() ??
        (vitals['spO2'] as num?)?.toInt() ??
        (json['spo2'] as num?)?.toInt() ??
        97;
    final bp = vitals['bloodPressure']?.toString() ??
        vitals['bp']?.toString() ??
        json['bloodPressure']?.toString() ??
        '124/82 mmHg';
    final st = (vitals['steps'] as num?)?.toInt() ??
        (json['steps'] as num?)?.toInt() ??
        4210;
    final dev = vitals['wearableDevice']?.toString() ??
        vitals['device']?.toString() ??
        json['wearableDevice']?.toString() ??
        'Fire-Boltt Watch Live';
    final ecg = vitals['ecgObservation']?.toString() ??
        json['ecgObservation']?.toString() ??
        'Sinus Rhythm • Wearable Monitored';

    final allergies = patient['allergies']?.toString() ?? json['allergyName']?.toString() ?? 'None reported';
    final bloodGroup = patient['bloodGroup']?.toString() ?? json['bloodGroup']?.toString() ?? 'B+';

    final parsedCreatedAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    return EmergencyRequest(
      id: json['id']?.toString() ?? 'EMS-${DateTime.now().millisecondsSinceEpoch}',
      tier: isCritical ? 'Tier 1 Critical' : 'Tier 2 Urgent',
      isCritical: isCritical,
      title: 'CRITICAL EMS SOS DISPATCH',
      triggeredAgo: 'Live',
      patientName: patientName,
      patientGender: patient['gender']?.toString() ?? json['patientGender']?.toString() ?? 'Male',
      patientAge: age,
      abhaId: patient['abhaId']?.toString() ?? json['abhaId']?.toString() ?? 'ABHA-91-8842-1923',
      bloodGroup: bloodGroup,
      pickupAddress: address,
      pickupLandmark: 'GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      latitude: lat,
      longitude: lng,
      driverLatitude: dLat,
      driverLongitude: dLng,
      status: status,
      assignedVehicleNo: json['assignedVehicleNo']?.toString(),
      distance: '2.1 km',
      eta: '$etaMins mins',
      primaryContactName: patient['emergencyContactName']?.toString() ?? patientName,
      primaryContactPhone: phone,
      wearableDevice: dev,
      heartRate: hr,
      spo2: sp,
      bloodPressure: bp,
      steps: st,
      ecgObservation: ecg,
      reportedEmergency: 'Acute Medical Emergency / SOS Triggered',
      emergencyDetails: 'Dispatched via Centralized Aarogya Ecosystem Gateway',
      receivingHospital: hospitalName,
      hospitalBay: 'Emergency Trauma Red Bay',
      assignedDoctor: 'Emergency Duty Officer',
      doctorAckTime: 'Acknowledged',
      allergyName: allergies,
      allergyReaction: 'None reported',
      allergyContraindications: 'None',
      sbarSituation: '$patientName ($age yrs): Emergency SOS at $address. En route to $hospitalName.',
      createdAt: parsedCreatedAt,
    );
  }

  factory EmergencyRequest.manualIntake({
    required String patientName,
    required String pickupAddress,
    required String reportedEmergency,
    String? patientPhone,
    String? landmark,
    bool isCritical = true,
    int? age,
    String? gender,
    double latitude = 28.5672,
    double longitude = 77.2100,
  }) {
    final now = DateTime.now();
    final id = 'EMS-${now.millisecondsSinceEpoch.toString().substring(7)}';
    return EmergencyRequest(
      id: id,
      tier: isCritical ? 'Tier 1 Critical' : 'Tier 2 Urgent',
      isCritical: isCritical,
      title: isCritical ? 'CRITICAL EMERGENCY INTAKE' : 'URGENT DISPATCH INTAKE',
      triggeredAgo: 'Just now',
      patientName: patientName,
      patientGender: gender ?? 'Male',
      patientAge: age ?? 30,
      abhaId: 'ABHA-EMS-MANUAL',
      bloodGroup: 'Unknown',
      pickupAddress: pickupAddress,
      pickupLandmark: landmark ?? 'GPS: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      latitude: latitude,
      longitude: longitude,
      status: 'ASSIGNED',
      distance: '1.8 km',
      eta: '5 mins',
      primaryContactName: patientName,
      primaryContactPhone: patientPhone ?? 'N/A',
      wearableDevice: 'Field Intake',
      heartRate: 85,
      spo2: 97,
      bloodPressure: '120/80 mmHg',
      steps: 0,
      reportedEmergency: reportedEmergency,
      emergencyDetails: 'Recorded via Paramedic EMS Terminal Intake',
      receivingHospital: 'Nearest Trauma / General Hospital',
      hospitalBay: 'Emergency Bay Allocation in progress',
      assignedDoctor: 'Emergency Duty Officer',
      sbarSituation: '$patientName: $reportedEmergency at $pickupAddress',
      createdAt: now,
    );
  }

  EmergencyRequest copyWith({
    String? id,
    String? tier,
    bool? isCritical,
    String? title,
    String? triggeredAgo,
    String? patientName,
    String? patientGender,
    int? patientAge,
    String? abhaId,
    String? bloodGroup,
    String? pickupAddress,
    String? pickupLandmark,
    double? latitude,
    double? longitude,
    double? driverLatitude,
    double? driverLongitude,
    String? status,
    String? assignedVehicleNo,
    String? distance,
    String? eta,
    String? primaryContactName,
    String? primaryContactPhone,
    String? wearableDevice,
    int? heartRate,
    int? spo2,
    String? bloodPressure,
    int? steps,
    String? ecgObservation,
    String? reportedEmergency,
    String? emergencyDetails,
    String? receivingHospital,
    String? hospitalBay,
    String? assignedDoctor,
    String? doctorAckTime,
    String? allergyName,
    String? allergyReaction,
    String? allergyContraindications,
    List<String>? diagnoses,
    List<Medication>? medications,
    String? sbarSituation,
    String? sbarBackground,
    String? sbarAssessment,
    String? sbarRecommendation,
    String? enrouteInterventions,
    DateTime? createdAt,
  }) {
    return EmergencyRequest(
      id: id ?? this.id,
      tier: tier ?? this.tier,
      isCritical: isCritical ?? this.isCritical,
      title: title ?? this.title,
      triggeredAgo: triggeredAgo ?? this.triggeredAgo,
      patientName: patientName ?? this.patientName,
      patientGender: patientGender ?? this.patientGender,
      patientAge: patientAge ?? this.patientAge,
      abhaId: abhaId ?? this.abhaId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLandmark: pickupLandmark ?? this.pickupLandmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      status: status ?? this.status,
      assignedVehicleNo: assignedVehicleNo ?? this.assignedVehicleNo,
      distance: distance ?? this.distance,
      eta: eta ?? this.eta,
      primaryContactName: primaryContactName ?? this.primaryContactName,
      primaryContactPhone: primaryContactPhone ?? this.primaryContactPhone,
      wearableDevice: wearableDevice ?? this.wearableDevice,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      steps: steps ?? this.steps,
      ecgObservation: ecgObservation ?? this.ecgObservation,
      reportedEmergency: reportedEmergency ?? this.reportedEmergency,
      emergencyDetails: emergencyDetails ?? this.emergencyDetails,
      receivingHospital: receivingHospital ?? this.receivingHospital,
      hospitalBay: hospitalBay ?? this.hospitalBay,
      assignedDoctor: assignedDoctor ?? this.assignedDoctor,
      doctorAckTime: doctorAckTime ?? this.doctorAckTime,
      allergyName: allergyName ?? this.allergyName,
      allergyReaction: allergyReaction ?? this.allergyReaction,
      allergyContraindications: allergyContraindications ?? this.allergyContraindications,
      diagnoses: diagnoses ?? this.diagnoses,
      medications: medications ?? this.medications,
      sbarSituation: sbarSituation ?? this.sbarSituation,
      sbarBackground: sbarBackground ?? this.sbarBackground,
      sbarAssessment: sbarAssessment ?? this.sbarAssessment,
      sbarRecommendation: sbarRecommendation ?? this.sbarRecommendation,
      enrouteInterventions: enrouteInterventions ?? this.enrouteInterventions,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
