enum AlertSeverity { criticalRed, warningAmber, resolvedGreen }

enum AlertStatus { newAlert, acknowledged, inProgress, resolved }

class TriageAlertModel {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String abhaId;
  final String roomOrLocation;
  final String primaryDx;
  final String attendingPhysician;
  final AlertSeverity severity;
  final AlertStatus status;
  final String triggerTime;
  final String triggerDevice;
  final String tierLevel;
  final int heartRate;
  final String hrContext;
  final int spo2;
  final String spo2Context;
  final String? bloodPressure;
  final String eventDetection;
  final String backendProtocol;
  final String dispatchCode;
  final String? gpsLocation;
  final String? emergencyContact;
  final String? routingStatus;
  final String? resolutionSummary;
  final String? resolvedTimeAgo;

  const TriageAlertModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.abhaId,
    required this.roomOrLocation,
    required this.primaryDx,
    required this.attendingPhysician,
    required this.severity,
    required this.status,
    required this.triggerTime,
    required this.triggerDevice,
    required this.tierLevel,
    required this.heartRate,
    required this.hrContext,
    required this.spo2,
    required this.spo2Context,
    this.bloodPressure,
    required this.eventDetection,
    required this.backendProtocol,
    required this.dispatchCode,
    this.gpsLocation,
    this.emergencyContact,
    this.routingStatus,
    this.resolutionSummary,
    this.resolvedTimeAgo,
  });

  static final List<TriageAlertModel> sampleAlerts = [
    const TriageAlertModel(
      id: 'alert-sunita-01',
      patientId: 'patient-sunita',
      patientName: 'Sunita Devi',
      patientAge: 62,
      patientGender: 'F',
      abhaId: '14-9921-4481-2692',
      roomOrLocation: 'Room 204 / Home RPM',
      primaryDx: 'Post-CABG Day 14 (Outpatient Monitoring)',
      attendingPhysician: 'Dr. Aarav Mehta',
      severity: AlertSeverity.criticalRed,
      status: AlertStatus.newAlert,
      triggerTime: '10:41 IST (5 mins ago)',
      triggerDevice: 'Continuous reading via continuous BLE pulse oximeter',
      tierLevel: 'Tier 1 Critical',
      heartRate: 124,
      hrContext: '+45 BPM Spike • Tachycardia (Baseline 72-78 BPM)',
      spo2: 89,
      spo2Context: 'Critical Dip (Threshold alarm limit < 90%)',
      eventDetection:
          'Sustained Tachycardia & SpO2 Dip. Continuous BLE telemetry verified at 10:41 IST. Signal Index: 92.4% (Motion artifact ruled out).',
      backendProtocol:
          'Tier 1 Escalation: Senior Cardiologist + Rapid Response Team Notification initiated automatically.',
      dispatchCode: 'DISPATCHED: ICU - RRT-40244',
    ),
    const TriageAlertModel(
      id: 'alert-rahul-02',
      patientId: 'patient-rahul',
      patientName: 'Rahul Sharma',
      patientAge: 48,
      patientGender: 'M',
      abhaId: '91-4828-1182-3941',
      roomOrLocation: 'Indiranagar, Bengaluru',
      primaryDx: 'Essential Hypertension & Post-MI rehab',
      attendingPhysician: 'Dr. Aarav Mehta',
      severity: AlertSeverity.warningAmber,
      status: AlertStatus.inProgress,
      triggerTime: '10:18 IST (28 mins ago)',
      triggerDevice: 'Remote Monitoring Device ID: AR-DET-092',
      tierLevel: 'Patient Triggered SOS Alert',
      heartRate: 108,
      hrContext: 'Elevated Post-Walk',
      spo2: 98,
      spo2Context: 'Safe Ambient Air',
      bloodPressure: '130/85',
      eventDetection:
          'Patient Triggered SOS Alert from wearable. Emergency Contact Notified: Wife (+91 98450-22104).',
      backendProtocol:
          'Acknowledged by Dr. Aarav Mehta at 10:19 IST. Paramedic en-route (Aarogya Rapid Ambulance KA-03-HA-1102), ETA: 8 mins.',
      dispatchCode: 'DISPATCHED: AMB-KA03HA1102',
      gpsLocation: 'Indiranagar, 12th Main, Bengaluru',
      emergencyContact: 'Wife (+91 98450-XXXXX)',
      routingStatus: 'Live GPS Telemetry Connected',
    ),
    const TriageAlertModel(
      id: 'alert-vikram-03',
      patientId: 'patient-vikram',
      patientName: 'Vikram Patel',
      patientAge: 55,
      patientGender: 'M',
      abhaId: '21-4081-5089-1094',
      roomOrLocation: 'Home RPM',
      primaryDx: 'Post-NSTEMI • Dyslipidemia',
      attendingPhysician: 'Dr. Aarav Mehta',
      severity: AlertSeverity.resolvedGreen,
      status: AlertStatus.resolved,
      triggerTime: '09:30 IST',
      triggerDevice: 'Medication Adherence Monitor',
      tierLevel: 'Adherence Deviation',
      heartRate: 74,
      hrContext: 'Normal Sinus',
      spo2: 99,
      spo2Context: 'Optimal Ambient Air',
      eventDetection: 'Missed Dual Antiplatelet Dose Alert',
      backendProtocol:
          'Patient confirmed taking dose at 09:59 IST after tele-call. Closed by Clinical Concierge.',
      dispatchCode: 'AUDIT-LOG-V9941',
      resolutionSummary:
          'Patient confirmed taking dose at 09:59 IST after tele-call. Closed by Clinical Concierge.',
      resolvedTimeAgo: 'Closed 41m ago',
    ),
  ];
}
