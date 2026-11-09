class AppointmentModel {
  final String id;
  final String patientProfileId;
  final String doctorProfileId;
  final DateTime startTime;
  final DateTime endTime;
  final String mode;
  final String status;
  final String? reason;
  final String? doctorNotes;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? doctorName;
  final String? doctorSpecialization;
  final String? doctorClinicAddress;
  final double? consultationFee;
  final String? patientName;

  const AppointmentModel({
    required this.id,
    required this.patientProfileId,
    required this.doctorProfileId,
    required this.startTime,
    required this.endTime,
    required this.mode,
    required this.status,
    this.reason,
    this.doctorNotes,
    this.cancellationReason,
    this.cancelledAt,
    this.doctorName,
    this.doctorSpecialization,
    this.doctorClinicAddress,
    this.consultationFee,
    this.patientName,
  });

  bool get isRequested => status == 'REQUESTED';
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isNoShow => status == 'NO_SHOW';

  bool get canCancel => isRequested || isConfirmed;

  String get formattedDate =>
      '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year}';

  String get formattedTime {
    final startH = startTime.hour.toString().padLeft(2, '0');
    final startM = startTime.minute.toString().padLeft(2, '0');
    final endH = endTime.hour.toString().padLeft(2, '0');
    final endM = endTime.minute.toString().padLeft(2, '0');
    return '$startH:$startM – $endH:$endM';
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    String? docName;
    String? docSpec;
    String? docAddress;
    double? fee;
    if (json['doctorProfile'] is Map<String, dynamic>) {
      final doc = json['doctorProfile'] as Map<String, dynamic>;
      docName = doc['fullName']?.toString();
      docSpec = doc['specialization']?.toString();
      docAddress = doc['clinicAddress']?.toString();
      if (doc['consultationFee'] != null) {
        fee = double.tryParse(doc['consultationFee'].toString());
      }
    }

    String? patName;
    if (json['patientProfile'] is Map<String, dynamic>) {
      final pat = json['patientProfile'] as Map<String, dynamic>;
      patName = pat['fullName']?.toString();
    }

    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      patientProfileId: json['patientProfileId']?.toString() ?? '',
      doctorProfileId: json['doctorProfileId']?.toString() ?? '',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now(),
      mode: json['mode']?.toString() ?? 'IN_PERSON',
      status: json['status']?.toString() ?? 'REQUESTED',
      reason: json['reason']?.toString(),
      doctorNotes: json['doctorNotes']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      doctorName: docName,
      doctorSpecialization: docSpec,
      doctorClinicAddress: docAddress,
      consultationFee: fee,
      patientName: patName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientProfileId': patientProfileId,
      'doctorProfileId': doctorProfileId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'mode': mode,
      'status': status,
      'reason': reason,
      'doctorNotes': doctorNotes,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }
}
