class MedicalRecordModel {
  final String id;
  final String patientProfileId;
  final String recordType;
  final String title;
  final String? description;
  final DateTime recordDate;
  final String? issuingDoctor;
  final String? facilityName;
  final Map<String, dynamic>? documentMetadata;
  final DateTime? createdAt;

  const MedicalRecordModel({
    required this.id,
    required this.patientProfileId,
    required this.recordType,
    required this.title,
    this.description,
    required this.recordDate,
    this.issuingDoctor,
    this.facilityName,
    this.documentMetadata,
    this.createdAt,
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    return MedicalRecordModel(
      id: json['id']?.toString() ?? '',
      patientProfileId: json['patientProfileId']?.toString() ?? '',
      recordType: json['recordType']?.toString() ?? 'OTHER',
      title: json['title']?.toString() ?? 'Medical Document',
      description: json['description']?.toString(),
      recordDate: json['recordDate'] != null
          ? DateTime.tryParse(json['recordDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      issuingDoctor: json['issuingDoctor']?.toString(),
      facilityName: json['facilityName']?.toString(),
      documentMetadata: json['documentMetadata'] is Map<String, dynamic>
          ? json['documentMetadata'] as Map<String, dynamic>
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientProfileId': patientProfileId,
      'recordType': recordType,
      'title': title,
      if (description != null) 'description': description,
      'recordDate': recordDate.toIso8601String(),
      if (issuingDoctor != null) 'issuingDoctor': issuingDoctor,
      if (facilityName != null) 'facilityName': facilityName,
      if (documentMetadata != null) 'documentMetadata': documentMetadata,
    };
  }

  String get formattedType {
    switch (recordType) {
      case 'PRESCRIPTION':
        return 'Prescription';
      case 'LAB_REPORT':
        return 'Lab Test';
      case 'DISCHARGE_SUMMARY':
        return 'Discharge Summary';
      case 'IMAGING':
        return 'Diagnostic Imaging';
      case 'VACCINATION':
        return 'Vaccination Record';
      default:
        return 'Clinical Document';
    }
  }
}
