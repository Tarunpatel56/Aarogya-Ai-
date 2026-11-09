import '../models/clinical_imaging_review_model.dart';
import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';

class ClinicalImagingService {
  final ApiClient? apiClient;
  List<ClinicalImagingReview> _reviews = [];

  ClinicalImagingService({this.apiClient, List<ClinicalImagingReview>? initialReviews}) {
    _reviews = initialReviews != null
        ? List<ClinicalImagingReview>.from(initialReviews)
        : ClinicalImagingReview.defaultSampleReviews();
  }

  /// Get current reviews, filtered optionally by modality and review status
  List<ClinicalImagingReview> getReviews({
    ImagingModality? modality,
    ClinicalReviewStatus? status,
  }) {
    var result = List<ClinicalImagingReview>.from(_reviews);

    if (modality != null) {
      result = result.where((r) => r.modality == modality).toList();
    }

    if (status != null) {
      result = result.where((r) => r.reviewStatus == status).toList();
    }

    return result;
  }

  /// Fetch a single review by its ID
  Future<ClinicalImagingReview> getReviewById(String id) async {
    final review = _reviews.firstWhere(
      (r) => r.id == id,
      orElse: () => throw ApiException(message: 'Imaging review not found', statusCode: 404),
    );
    return review;
  }

  /// Complete doctor sign-off: validate or clinical override
  Future<ClinicalImagingReview> validateReview({
    required String id,
    required String doctorName,
    required String notes,
    required bool agreesWithAi,
    String? overrideDiagnosis,
    String? prescribedPhysioPlan,
    List<String>? prescribedMedications,
  }) async {
    final index = _reviews.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw ApiException(message: 'Imaging study not found', statusCode: 404);
    }

    final current = _reviews[index];
    final updated = current.copyWith(
      reviewStatus: agreesWithAi
          ? ClinicalReviewStatus.validated
          : ClinicalReviewStatus.overridden,
      isAgreedWithAi: agreesWithAi,
      doctorNotes: notes.trim(),
      doctorSignOff: doctorName.trim(),
      signedOffAt: DateTime.now(),
      overrideDiagnosis: agreesWithAi ? null : overrideDiagnosis?.trim(),
      prescribedPhysioPlan: prescribedPhysioPlan?.trim(),
      prescribedMedications: prescribedMedications ?? current.prescribedMedications,
    );

    _reviews[index] = updated;
    return updated;
  }

  /// Add new imaging study to queue (e.g. from patient upload or hospital PACs)
  void addReview(ClinicalImagingReview review) {
    _reviews.insert(0, review);
  }
}
