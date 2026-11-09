enum ImagingModality {
  brainMri,
  chestXray,
  skinLesion,
}

enum ClinicalReviewStatus {
  pendingReview,
  validated,
  overridden,
}

class ClinicalImagingReview {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final ImagingModality modality;
  final DateTime uploadedAt;
  final String aiPreClassification;
  final double aiConfidence;
  final String aiProvider;
  final String mandatoryClinicalNotice;
  final String? imageUrl;
  final ClinicalReviewStatus reviewStatus;
  final String? doctorNotes;
  final String? doctorSignOff;
  final DateTime? signedOffAt;
  final bool isAgreedWithAi;
  final String? overrideDiagnosis;
  final String? prescribedPhysioPlan;
  final List<String> prescribedMedications;

  const ClinicalImagingReview({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.modality,
    required this.uploadedAt,
    required this.aiPreClassification,
    required this.aiConfidence,
    required this.aiProvider,
    required this.mandatoryClinicalNotice,
    this.imageUrl,
    this.reviewStatus = ClinicalReviewStatus.pendingReview,
    this.doctorNotes,
    this.doctorSignOff,
    this.signedOffAt,
    this.isAgreedWithAi = true,
    this.overrideDiagnosis,
    this.prescribedPhysioPlan,
    this.prescribedMedications = const [],
  });

  bool get isPending => reviewStatus == ClinicalReviewStatus.pendingReview;
  bool get isValidated => reviewStatus == ClinicalReviewStatus.validated;
  bool get isOverridden => reviewStatus == ClinicalReviewStatus.overridden;

  String get modalityLabel {
    switch (modality) {
      case ImagingModality.brainMri:
        return 'Brain MRI';
      case ImagingModality.chestXray:
        return 'Chest X-Ray';
      case ImagingModality.skinLesion:
        return 'Dermoscopy / Skin';
    }
  }

  ClinicalImagingReview copyWith({
    String? id,
    String? patientId,
    String? patientName,
    int? patientAge,
    String? patientGender,
    ImagingModality? modality,
    DateTime? uploadedAt,
    String? aiPreClassification,
    double? aiConfidence,
    String? aiProvider,
    String? mandatoryClinicalNotice,
    String? imageUrl,
    ClinicalReviewStatus? reviewStatus,
    String? doctorNotes,
    String? doctorSignOff,
    DateTime? signedOffAt,
    bool? isAgreedWithAi,
    String? overrideDiagnosis,
    String? prescribedPhysioPlan,
    List<String>? prescribedMedications,
  }) {
    return ClinicalImagingReview(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      modality: modality ?? this.modality,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      aiPreClassification: aiPreClassification ?? this.aiPreClassification,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      aiProvider: aiProvider ?? this.aiProvider,
      mandatoryClinicalNotice: mandatoryClinicalNotice ?? this.mandatoryClinicalNotice,
      imageUrl: imageUrl ?? this.imageUrl,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      doctorSignOff: doctorSignOff ?? this.doctorSignOff,
      signedOffAt: signedOffAt ?? this.signedOffAt,
      isAgreedWithAi: isAgreedWithAi ?? this.isAgreedWithAi,
      overrideDiagnosis: overrideDiagnosis ?? this.overrideDiagnosis,
      prescribedPhysioPlan: prescribedPhysioPlan ?? this.prescribedPhysioPlan,
      prescribedMedications: prescribedMedications ?? this.prescribedMedications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'modality': modality.name,
      'uploadedAt': uploadedAt.toIso8601String(),
      'aiPreClassification': aiPreClassification,
      'aiConfidence': aiConfidence,
      'aiProvider': aiProvider,
      'mandatoryClinicalNotice': mandatoryClinicalNotice,
      'imageUrl': imageUrl,
      'reviewStatus': reviewStatus.name,
      'doctorNotes': doctorNotes,
      'doctorSignOff': doctorSignOff,
      'signedOffAt': signedOffAt?.toIso8601String(),
      'isAgreedWithAi': isAgreedWithAi,
      'overrideDiagnosis': overrideDiagnosis,
      'prescribedPhysioPlan': prescribedPhysioPlan,
      'prescribedMedications': prescribedMedications,
    };
  }

  factory ClinicalImagingReview.fromJson(Map<String, dynamic> json) {
    ImagingModality parseModality(String? name) {
      if (name == 'brainMri') return ImagingModality.brainMri;
      if (name == 'chestXray') return ImagingModality.chestXray;
      if (name == 'skinLesion') return ImagingModality.skinLesion;
      return ImagingModality.chestXray;
    }

    ClinicalReviewStatus parseStatus(String? name) {
      if (name == 'validated') return ClinicalReviewStatus.validated;
      if (name == 'overridden') return ClinicalReviewStatus.overridden;
      return ClinicalReviewStatus.pendingReview;
    }

    return ClinicalImagingReview(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      patientAge: json['patientAge'] is int ? json['patientAge'] as int : 45,
      patientGender: json['patientGender'] as String? ?? 'Unknown',
      modality: parseModality(json['modality'] as String?),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : DateTime.now(),
      aiPreClassification: json['aiPreClassification'] as String? ?? 'Normal',
      aiConfidence: (json['aiConfidence'] is num)
          ? (json['aiConfidence'] as num).toDouble()
          : 0.90,
      aiProvider: json['aiProvider'] as String? ?? 'Aarogya Healthcare AI Provider',
      mandatoryClinicalNotice: json['mandatoryClinicalNotice'] as String? ??
          'Assistive clinical inference only.',
      imageUrl: json['imageUrl'] as String?,
      reviewStatus: parseStatus(json['reviewStatus'] as String?),
      doctorNotes: json['doctorNotes'] as String?,
      doctorSignOff: json['doctorSignOff'] as String?,
      signedOffAt: json['signedOffAt'] != null
          ? DateTime.parse(json['signedOffAt'] as String)
          : null,
      isAgreedWithAi: json['isAgreedWithAi'] as bool? ?? true,
      overrideDiagnosis: json['overrideDiagnosis'] as String?,
      prescribedPhysioPlan: json['prescribedPhysioPlan'] as String?,
      prescribedMedications: (json['prescribedMedications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static List<ClinicalImagingReview> defaultSampleReviews() {
    final now = DateTime.now();
    return [
      ClinicalImagingReview(
        id: 'rev-mri-001',
        patientId: 'patient-rahul',
        patientName: 'Rahul Sharma',
        patientAge: 48,
        patientGender: 'Male',
        modality: ImagingModality.brainMri,
        uploadedAt: now.subtract(const Duration(hours: 3)),
        aiPreClassification: 'Pituitary Tumor Detected',
        aiConfidence: 0.942,
        aiProvider: 'Hemgg/brain-tumor-classification (Hugging Face)',
        mandatoryClinicalNotice:
            'MANDATORY CLINICAL NOTICE: Assistive AI prediction. Certified neuro-radiologist correlation and IV gadolinium T1/T2/FLAIR sequences required prior to definitive surgical or oncological treatment planning.',
        reviewStatus: ClinicalReviewStatus.pendingReview,
      ),
      ClinicalImagingReview(
        id: 'rev-lung-002',
        patientId: 'patient-sunita',
        patientName: 'Sunita Devi',
        patientAge: 56,
        patientGender: 'Female',
        modality: ImagingModality.chestXray,
        uploadedAt: now.subtract(const Duration(hours: 7)),
        aiPreClassification: 'Pneumonia (Right Lower Consolidation)',
        aiConfidence: 0.918,
        aiProvider: 'dima806/chest_xray_pneumonia_detection (Hugging Face)',
        mandatoryClinicalNotice:
            'CRITICAL CLINICAL NOTICE: Assistive triage classification. Correlate with auscultatory crackles, CRP/procalcitonin lab markers, and arterial blood gas before antimicrobial escalation.',
        reviewStatus: ClinicalReviewStatus.pendingReview,
      ),
      ClinicalImagingReview(
        id: 'rev-skin-003',
        patientId: 'patient-vikram',
        patientName: 'Vikram Patel',
        patientAge: 42,
        patientGender: 'Male',
        modality: ImagingModality.skinLesion,
        uploadedAt: now.subtract(const Duration(days: 1)),
        aiPreClassification: 'Benign Keratotic Lesion (Seborrheic Keratosis)',
        aiConfidence: 0.885,
        aiProvider: 'Tanishq77/skin-condition-classifier (Hugging Face)',
        mandatoryClinicalNotice:
            'MANDATORY DERMATOLOGY NOTICE: Non-diagnostic triage classification. Lighting variations and skin phototype affect edge detection. Histological punch biopsy or dermoscopic pattern analysis is required if lesion evolves or ulcerates.',
        reviewStatus: ClinicalReviewStatus.validated,
        doctorNotes:
            'Confirmed benign seborrheic keratosis on right dorsal forearm. No dysplastic signs or ulceration. Routine monitoring advised.',
        doctorSignOff: 'Dr. Aarav Mehta, MD (Cardiology/Internal Medicine)',
        signedOffAt: now.subtract(const Duration(hours: 18)),
        isAgreedWithAi: true,
      ),
    ];
  }
}
