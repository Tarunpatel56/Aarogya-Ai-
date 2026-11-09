import '../core/api/api_client.dart';
import '../models/patient_profile_model.dart';
import '../models/family_member_model.dart';
import '../models/medical_record_model.dart';

class PatientService {
  final ApiClient _apiClient;

  PatientService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve authenticated patient's profile
  Future<PatientProfileModel> getProfile() async {
    final res = await _apiClient.get('/patients/me');
    final profileData = res is Map<String, dynamic> && res.containsKey('profile')
        ? res['profile']
        : res;
    return PatientProfileModel.fromJson(profileData as Map<String, dynamic>);
  }

  /// Update permitted profile fields
  Future<PatientProfileModel> updateProfile({
    String? fullName,
    String? phone,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName.trim();
    if (phone != null) body['phone'] = phone.trim();
    if (gender != null) body['gender'] = gender.trim();
    if (bloodGroup != null) body['bloodGroup'] = bloodGroup.trim();
    if (allergies != null) body['allergies'] = allergies.trim();
    if (address != null) body['address'] = address.trim();
    if (emergencyContactName != null) {
      body['emergencyContactName'] = emergencyContactName.trim();
    }
    if (emergencyContactPhone != null) {
      body['emergencyContactPhone'] = emergencyContactPhone.trim();
    }

    final res = await _apiClient.patch('/patients/me', body: body);
    final profileData = res is Map<String, dynamic> && res.containsKey('profile')
        ? res['profile']
        : res;
    return PatientProfileModel.fromJson(profileData as Map<String, dynamic>);
  }

  /// Retrieve patient's authorized medical records as raw maps (backward compatible)
  Future<List<Map<String, dynamic>>> getMedicalRecords({
    String? recordType,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (recordType != null && recordType.isNotEmpty) {
      query['recordType'] = recordType;
    }

    final res = await _apiClient.get('/patients/me/medical-records', queryParams: query);
    if (res is Map<String, dynamic> && res['records'] is List) {
      return (res['records'] as List).map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// Retrieve patient's authorized medical records as strongly typed models
  Future<List<MedicalRecordModel>> getMedicalRecordModels({
    String? recordType,
    int limit = 50,
    int offset = 0,
  }) async {
    final rawList = await getMedicalRecords(
      recordType: recordType,
      limit: limit,
      offset: offset,
    );
    return rawList.map((e) => MedicalRecordModel.fromJson(e)).toList();
  }

  /// Upload / create a new verified medical record
  Future<MedicalRecordModel> createMedicalRecord({
    required String recordType,
    required String title,
    String? description,
    DateTime? recordDate,
    String? issuingDoctor,
    String? facilityName,
  }) async {
    final body = <String, dynamic>{
      'recordType': recordType,
      'title': title.trim(),
    };
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (recordDate != null) {
      body['recordDate'] = recordDate.toIso8601String();
    }
    if (issuingDoctor != null && issuingDoctor.trim().isNotEmpty) {
      body['issuingDoctor'] = issuingDoctor.trim();
    }
    if (facilityName != null && facilityName.trim().isNotEmpty) {
      body['facilityName'] = facilityName.trim();
    }

    final res = await _apiClient.post('/patients/me/medical-records', body: body);
    final data = res is Map<String, dynamic> && res.containsKey('record')
        ? res['record']
        : res;
    return MedicalRecordModel.fromJson(data as Map<String, dynamic>);
  }

  /// List all registered family members
  Future<List<FamilyMemberModel>> getFamilyMembers() async {
    final res = await _apiClient.get('/patients/me/family-members');
    if (res is Map<String, dynamic> && res['familyMembers'] is List) {
      return (res['familyMembers'] as List)
          .map((m) => FamilyMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Add a new family member
  Future<FamilyMemberModel> addFamilyMember({
    required String fullName,
    required String relationship,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? medicalHistory,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName.trim(),
      'relationship': relationship.trim(),
    };
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth.toIso8601String();
    if (gender != null && gender.trim().isNotEmpty) body['gender'] = gender.trim();
    if (bloodGroup != null && bloodGroup.trim().isNotEmpty) body['bloodGroup'] = bloodGroup.trim();
    if (allergies != null && allergies.trim().isNotEmpty) body['allergies'] = allergies.trim();
    if (medicalHistory != null && medicalHistory.trim().isNotEmpty) {
      body['medicalHistory'] = medicalHistory.trim();
    }

    final res = await _apiClient.post('/patients/me/family-members', body: body);
    final data = res is Map<String, dynamic> && res.containsKey('familyMember')
        ? res['familyMember']
        : res;
    return FamilyMemberModel.fromJson(data as Map<String, dynamic>);
  }

  /// Delete a family member
  Future<void> deleteFamilyMember(String id) async {
    await _apiClient.delete('/patients/me/family-members/$id');
  }
}
