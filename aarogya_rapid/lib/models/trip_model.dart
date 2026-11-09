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
  final String pickupAddress;
  final String pickupLandmark;
  final String distance;
  final String eta;
  final String primaryContactName;
  final String primaryContactPhone;
  final String wearableDevice;
  final int heartRate;
  final int spo2;
  final String bloodPressure;
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
    required this.pickupAddress,
    required this.pickupLandmark,
    required this.distance,
    required this.eta,
    required this.primaryContactName,
    required this.primaryContactPhone,
    this.wearableDevice = 'None Paired',
    this.heartRate = 0,
    this.spo2 = 0,
    this.bloodPressure = 'Awaiting triage',
    this.ecgObservation = 'Field observation pending',
    required this.reportedEmergency,
    this.emergencyDetails = '',
    this.receivingHospital = 'Aarogya Partner Hospital',
    this.hospitalBay = 'Emergency Bay Pending',
    this.assignedDoctor = 'On-Duty Emergency Physician',
    this.doctorAckTime = 'Pending',
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
  });

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    final patient = json['patientProfile'] as Map<String, dynamic>? ?? {};
    final user = patient['user'] as Map<String, dynamic>? ?? {};
    final status = json['status']?.toString() ?? 'ASSIGNED';
    final isCritical = status == 'REQUESTED' || status == 'SEARCHING' || status == 'ASSIGNED';
    final patientName = patient['fullName']?.toString() ?? json['patientName']?.toString() ?? 'Emergency Patient';
    final age = patient['age'] is int ? patient['age'] as int : (patient['dateOfBirth'] != null ? 35 : 0);
    final phone = user['phone']?.toString() ?? patient['emergencyContactPhone']?.toString() ?? json['primaryContactPhone']?.toString() ?? '+91 98765-43210';
    final address = json['pickupAddress']?.toString() ?? 'Current Patient GPS Coordinates';
    final hospitalName = json['hospitalName']?.toString() ?? 'Nearest Trauma Center';
    final etaMins = json['estimatedMinutes']?.toString() ?? '6';

    return EmergencyRequest(
      id: json['id']?.toString() ?? 'EMS-${DateTime.now().millisecondsSinceEpoch}',
      tier: isCritical ? 'Tier 1 Critical' : 'Tier 2 Urgent',
      isCritical: isCritical,
      title: 'CRITICAL EMS SOS DISPATCH',
      triggeredAgo: 'Live',
      patientName: patientName,
      patientGender: patient['gender']?.toString() ?? 'Male',
      patientAge: age,
      abhaId: patient['abhaId']?.toString() ?? 'ABHA-91-8842-1923',
      pickupAddress: address,
      pickupLandmark: 'GPS: ${json['latitude']?.toString() ?? '28.5672'}, ${json['longitude']?.toString() ?? '77.2100'}',
      distance: '2.4 km',
      eta: '$etaMins mins',
      primaryContactName: patient['emergencyContactName']?.toString() ?? patientName,
      primaryContactPhone: phone,
      reportedEmergency: 'Acute Medical Emergency / SOS Triggered',
      emergencyDetails: 'Dispatched via Centralized Aarogya Ecosystem Gateway',
      receivingHospital: hospitalName,
      hospitalBay: 'Emergency Trauma Red Bay',
      assignedDoctor: 'Emergency Duty Officer',
      allergyName: patient['allergies']?.toString() ?? 'None reported',
      sbarSituation: '$patientName ($age yrs): Emergency SOS at $address. En route to $hospitalName.',
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
      patientGender: gender ?? 'Unknown',
      patientAge: age ?? 0,
      abhaId: 'Pending Verification',
      pickupAddress: pickupAddress,
      pickupLandmark: landmark ?? 'Reported location',
      distance: 'Estimating...',
      eta: 'En route calculation',
      primaryContactName: patientName,
      primaryContactPhone: patientPhone ?? 'N/A',
      reportedEmergency: reportedEmergency,
      emergencyDetails: 'Recorded via Paramedic EMS Terminal Intake',
      receivingHospital: 'Nearest Trauma / General Hospital',
      hospitalBay: 'Emergency Bay Allocation in progress',
      assignedDoctor: 'Emergency Duty Officer',
      sbarSituation: '$patientName: $reportedEmergency at $pickupAddress',
    );
  }
}
