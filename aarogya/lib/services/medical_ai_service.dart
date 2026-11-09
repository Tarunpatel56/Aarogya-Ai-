import '../core/api/api_client.dart';
import '../models/medical_analysis_model.dart';

class MedicalAiService {
  final ApiClient _apiClient;

  MedicalAiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;

  /// Upload Brain MRI scan for neural tumor detection
  Future<MedicalAnalysisResult> analyzeBrainMri({
    required List<int> imageBytes,
    String filename = 'brain_mri.png',
    String language = 'en',
  }) async {
    final response = await _apiClient.postMultipart(
      '/ai/mri-analysis?language=$language',
      fileBytes: imageBytes,
      filename: filename,
    );

    if (response is Map<String, dynamic>) {
      return MedicalAnalysisResult.fromJson(response);
    }
    throw Exception('Invalid response format received from MRI analysis service');
  }

  /// Upload Chest X-Ray radiograph for pulmonary pneumonia screening
  Future<MedicalAnalysisResult> analyzeLungXray({
    required List<int> imageBytes,
    String filename = 'chest_xray.jpg',
    String language = 'en',
  }) async {
    final response = await _apiClient.postMultipart(
      '/ai/lung-analysis?language=$language',
      fileBytes: imageBytes,
      filename: filename,
    );

    if (response is Map<String, dynamic>) {
      return MedicalAnalysisResult.fromJson(response);
    }
    throw Exception('Invalid response format received from Lung X-Ray analysis service');
  }

  /// Upload skin lesion photograph for dermatological classification
  Future<MedicalAnalysisResult> analyzeSkinImage({
    required List<int> imageBytes,
    String filename = 'skin_lesion.jpg',
    String language = 'en',
  }) async {
    final response = await _apiClient.postMultipart(
      '/ai/skin-analysis?language=$language',
      fileBytes: imageBytes,
      filename: filename,
    );

    if (response is Map<String, dynamic>) {
      return MedicalAnalysisResult.fromJson(response);
    }
    throw Exception('Invalid response format received from Skin analysis service');
  }

  /// Upload eye photograph for ophthalmology & ocular condition screening
  Future<MedicalAnalysisResult> analyzeEyeImage({
    required List<int> imageBytes,
    String filename = 'eye_photo.jpg',
    String language = 'en',
  }) async {
    final response = await _apiClient.postMultipart(
      '/ai/eye-analysis?language=$language',
      fileBytes: imageBytes,
      filename: filename,
    );

    if (response is Map<String, dynamic>) {
      return MedicalAnalysisResult.fromJson(response);
    }
    throw Exception('Invalid response format received from Eye analysis service');
  }
}
