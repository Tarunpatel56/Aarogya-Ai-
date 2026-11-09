enum TriageSeverity {
  criticalRed,
  warningAmber,
  resolved,
}

enum AlertStatus {
  newAlert,
  acknowledged,
  inProgress,
  resolved,
}

class TriageAlert {
  final String id;
  final TriageSeverity severity;
  AlertStatus status;
  final String triggerTime;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String abhaId;
  final String roomOrLocation;
  final String primaryDiagnosis;
  final String attending;
  final String priorityDispatchTier;
  final String headline;
  final String details;
  final String? trustIndexNote;
  final String? gpsLocation;
  final String? emergencyContact;

  // Vitals at triage
  final String? heartRateReadout;
  final String? heartRateBadge;
  final String? heartRateBaseline;
  final String? spo2Readout;
  final String? spo2Badge;
  final String? spo2Limit;
  final String? bloodPressure;

  // Protocol & Dispatch
  final String? protocolDetails;
  final String? dispatchId;
  final String? ambulanceInfo;
  final String? ambulanceEta;
  final bool liveGpsConnected;

  // Resolution info
  final String? resolutionSummary;
  final String? closedTimeAgo;

  TriageAlert({
    required this.id,
    required this.severity,
    required this.status,
    required this.triggerTime,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.abhaId,
    required this.roomOrLocation,
    required this.primaryDiagnosis,
    this.attending = 'Dr. Aarav Mehta',
    this.priorityDispatchTier = 'Tier 1 Critical',
    required this.headline,
    required this.details,
    this.trustIndexNote,
    this.gpsLocation,
    this.emergencyContact,
    this.heartRateReadout,
    this.heartRateBadge,
    this.heartRateBaseline,
    this.spo2Readout,
    this.spo2Badge,
    this.spo2Limit,
    this.bloodPressure,
    this.protocolDetails,
    this.dispatchId,
    this.ambulanceInfo,
    this.ambulanceEta,
    this.liveGpsConnected = false,
    this.resolutionSummary,
    this.closedTimeAgo,
  });
}
