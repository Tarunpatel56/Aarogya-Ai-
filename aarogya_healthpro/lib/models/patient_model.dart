class PatientModel {
  final String id;
  final String name;
  final String initials;
  final int age;
  final String gender;
  final String abhaId;
  final String wardOrLocation;
  final String primaryDiagnosis;
  final String attendingPhysician;
  final String caregiver;
  final String allergies;
  final String connectedDevice;
  final String lastDeviceSync;
  final int heartRate;
  final String heartRateContext;
  final int spo2;
  final String spo2Status;
  final String bloodPressure;
  final int bloodGlucose;
  final String statusNote;
  final bool isCritical;
  final List<double> hrTrend24h;

  const PatientModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.age,
    required this.gender,
    required this.abhaId,
    required this.wardOrLocation,
    required this.primaryDiagnosis,
    required this.attendingPhysician,
    required this.caregiver,
    required this.allergies,
    required this.connectedDevice,
    required this.lastDeviceSync,
    required this.heartRate,
    required this.heartRateContext,
    required this.spo2,
    required this.spo2Status,
    required this.bloodPressure,
    required this.bloodGlucose,
    required this.statusNote,
    this.isCritical = false,
    required this.hrTrend24h,
  });

  static final List<PatientModel> samplePatients = [
    PatientModel(
      id: 'patient-rahul',
      name: 'Rahul Sharma',
      initials: 'RS',
      age: 48,
      gender: 'M',
      abhaId: '91-4828-1182-3941',
      wardOrLocation: 'Ward 3B',
      primaryDiagnosis: 'Essential Stage II HTN & Post-PCI (Stent LAD) 2023',
      attendingPhysician: 'Dr. Aarav Mehta, MD • Apollo HealthCity Cardiology',
      caregiver: 'Priya Sharma (Wife, +91 98450-22104, Verified)',
      allergies: 'Penicillin (Severe anaphylaxis) + Aspirin 75mg tolerated',
      connectedDevice: 'boAt Wave Pro (Direct BLE Measurement)',
      lastDeviceSync: '2m ago',
      heartRate: 108,
      heartRateContext: 'Walk elevation, 17m ago (boAt Wave Pro)',
      spo2: 98,
      spo2Status: 'Optimal (Stable continuous)',
      bloodPressure: '120/80',
      bloodGlucose: 104,
      statusNote: 'Stable - Evening Telmisartan 40mg logged (19:30 IST)',
      isCritical: false,
      hrTrend24h: [
        68, 64, 61, 58, 60, 65, 74, 82, 88, 92, 85, 78,
        72, 75, 80, 95, 110, 124, 108, 90, 82, 76, 72, 70
      ],
    ),
    PatientModel(
      id: 'patient-sunita',
      name: 'Sunita Devi',
      initials: 'SD',
      age: 62,
      gender: 'F',
      abhaId: '14-9921-4481-2692',
      wardOrLocation: 'Home RPM',
      primaryDiagnosis: 'Post-CABG Day 14 (Outpatient Monitoring) • Type 2 Diabetes & CHF',
      attendingPhysician: 'Dr. Aarav Mehta, MD',
      caregiver: 'Rohan Devi (Son, +91 98451-99881, Verified)',
      allergies: 'Sulfa Drugs (Mild skin rash)',
      connectedDevice: 'Omron Connect + Continuous BLE Oximeter',
      lastDeviceSync: '5m ago',
      heartRate: 124,
      heartRateContext: 'Resting Tachycardia Spike (+45 BPM)',
      spo2: 89,
      spo2Status: 'Critical Dip (< 90%)',
      bloodPressure: '145/95',
      bloodGlucose: 210,
      statusNote: 'Critical telemetry alert - Sustained Tachycardia & SpO2 Dip',
      isCritical: true,
      hrTrend24h: [
        74, 76, 75, 72, 73, 75, 78, 82, 85, 90, 94, 98,
        102, 105, 112, 118, 120, 124, 122, 118, 110, 104, 98, 92
      ],
    ),
    PatientModel(
      id: 'patient-vikram',
      name: 'Vikram Patel',
      initials: 'VP',
      age: 55,
      gender: 'M',
      abhaId: '21-4081-5089-1094',
      wardOrLocation: 'Home RPM',
      primaryDiagnosis: 'Post-NSTEMI • Dyslipidemia',
      attendingPhysician: 'Dr. Aarav Mehta, MD',
      caregiver: 'Kavita Patel (Spouse, +91 99120-44102)',
      allergies: 'No Known Drug Allergies (NKDA)',
      connectedDevice: 'Apple Watch Series 9',
      lastDeviceSync: '41m ago',
      heartRate: 74,
      heartRateContext: 'Resting normal rhythm',
      spo2: 99,
      spo2Status: 'Normal Ambient Air',
      bloodPressure: '124/82',
      bloodGlucose: 112,
      statusNote: 'Missed Dual Antiplatelet Dose Alert resolved via tele-call',
      isCritical: false,
      hrTrend24h: [
        62, 60, 59, 58, 61, 64, 70, 75, 78, 76, 74, 73,
        72, 74, 75, 78, 80, 82, 78, 75, 73, 72, 71, 70
      ],
    ),
  ];
}
