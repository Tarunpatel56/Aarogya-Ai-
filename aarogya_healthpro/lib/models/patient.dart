enum PatientStatus {
  stable,
  warning,
  critical,
}

class PatientVitals {
  final int? heartRate;
  final String? heartRateContext;
  final bool heartRateSpike;

  final int? spo2;
  final String? spo2Status;
  final String? spo2Context;

  final int? bloodGlucose;
  final String? bloodGlucoseContext;

  final int? pulseRate;
  final String? pulseContext;

  final String? bloodPressure;
  final String? bpDevice;
  final String? bpContext;

  const PatientVitals({
    this.heartRate,
    this.heartRateContext,
    this.heartRateSpike = false,
    this.spo2,
    this.spo2Status,
    this.spo2Context,
    this.bloodGlucose,
    this.bloodGlucoseContext,
    this.pulseRate,
    this.pulseContext,
    this.bloodPressure,
    this.bpDevice,
    this.bpContext,
  });
}

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String initials;
  final String abhaId;
  final String wardOrLocation;
  final String primaryDiagnosis;
  final String attendingPhysician;
  final String clinic;
  final String proxyCaregiver;
  final bool proxyVerified;
  final String allergies;
  final String wearableDevice;
  final String lastSyncTime;
  final PatientStatus status;
  final PatientVitals vitals;
  final String statusSummary;
  final String statusTime;
  final bool hasActiveAlert;
  final String? alertSnippet;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.initials,
    required this.abhaId,
    required this.wardOrLocation,
    required this.primaryDiagnosis,
    this.attendingPhysician = 'Dr. Aarav Mehta, MD',
    this.clinic = 'Apollo HealthCity Cardiology',
    this.proxyCaregiver = 'Priya Sharma (Wife, +91 98450-22104)',
    this.proxyVerified = true,
    this.allergies = 'Penicillin (Severe anaphylaxis) + Aspirin 75mg (tolerated)',
    this.wearableDevice = 'boAt Wave Pro',
    this.lastSyncTime = '2m ago via Common Backend',
    required this.status,
    required this.vitals,
    required this.statusSummary,
    this.statusTime = '19:30 IST',
    this.hasActiveAlert = false,
    this.alertSnippet,
  });
}
