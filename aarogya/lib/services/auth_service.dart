import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../models/user_model.dart';
import '../models/patient_profile_model.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient;
  UserModel? _currentUser = const UserModel(
    id: 'demo-patient-001',
    email: 'rahul.sharma@aarogya.ai',
    phone: '+91 98765 43210',
    role: 'PATIENT',
    verificationStatus: 'VERIFIED',
    isActive: true,
  );
  PatientProfileModel? _currentProfile = const PatientProfileModel(
    id: 'demo-profile-001',
    userId: 'demo-patient-001',
    fullName: 'Rahul Sharma',
    abhaId: 'ABHA-9876-5432-1098',
    gender: 'MALE',
    bloodGroup: 'B+',
    emergencyContactName: 'Priya Sharma',
    emergencyContactPhone: '+91 98765 43211',
    allergies: 'None reported',
  );
  bool _isLoading = false;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;
  UserModel? get currentUser => _currentUser;
  PatientProfileModel? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Restores session on app startup
  Future<bool> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _apiClient.tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final userData = await _apiClient.get('/auth/me');
      if (userData is Map<String, dynamic> && userData['user'] != null) {
        _currentUser = UserModel.fromJson(userData['user'] as Map<String, dynamic>);
      }

      try {
        final profileData = await _apiClient.get('/patients/me');
        if (profileData is Map<String, dynamic> && profileData['profile'] != null) {
          _currentProfile = PatientProfileModel.fromJson(profileData['profile'] as Map<String, dynamic>);
        }
      } catch (_) {
        // Profile fetch might be skipped if initial registration
      }

      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
    } catch (_) {
      await _apiClient.tokenStorage.clear();
      _currentUser = null;
      _currentProfile = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Patient Login with Email or Phone
  Future<void> login({String? email, String? phone, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{'password': password};
      if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
      if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();

      final res = await _apiClient.post(
        '/auth/login',
        body: body,
        includeAuth: false,
      );

      final tokens = res['tokens'];
      if (tokens != null) {
        await _apiClient.tokenStorage.saveTokens(
          accessToken: tokens['accessToken'].toString(),
          refreshToken: tokens['refreshToken'].toString(),
        );
      }

      if (res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        await _apiClient.tokenStorage.saveUser(_currentUser!.toJson());
      }

      if (res['profile'] != null) {
        _currentProfile = PatientProfileModel.fromJson(res['profile'] as Map<String, dynamic>);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Request 6-digit OTP code to registered phone
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        '/auth/send-otp',
        body: {'phone': phone.trim()},
        includeAuth: false,
      );
      _isLoading = false;
      notifyListeners();
      return (res is Map<String, dynamic>) ? res : {'success': true};
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Verify 6-digit OTP code and establish user session
  Future<void> verifyOtp({required String phone, required String otp}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        '/auth/verify-otp',
        body: {'phone': phone.trim(), 'otp': otp.trim()},
        includeAuth: false,
      );

      final tokens = res['tokens'];
      if (tokens != null) {
        await _apiClient.tokenStorage.saveTokens(
          accessToken: tokens['accessToken'].toString(),
          refreshToken: tokens['refreshToken'].toString(),
        );
      }

      if (res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        await _apiClient.tokenStorage.saveUser(_currentUser!.toJson());
      }

      if (res['profile'] != null) {
        _currentProfile = PatientProfileModel.fromJson(res['profile'] as Map<String, dynamic>);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Forgot Password request
  Future<void> forgotPassword({String? email, String? phone}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
      if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();

      await _apiClient.post(
        '/auth/forgot-password',
        body: body,
        includeAuth: false,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Patient Registration
  Future<void> registerPatient({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? abhaId,
    String? gender,
    String? bloodGroup,
    DateTime? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? allergies,
    String? address,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
      };
      if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();
      if (abhaId != null && abhaId.trim().isNotEmpty) body['abhaId'] = abhaId.trim();
      if (gender != null && gender.trim().isNotEmpty) body['gender'] = gender.trim();
      if (bloodGroup != null && bloodGroup.trim().isNotEmpty) body['bloodGroup'] = bloodGroup.trim();
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (emergencyContactName != null && emergencyContactName.trim().isNotEmpty) {
        body['emergencyContactName'] = emergencyContactName.trim();
      }
      if (emergencyContactPhone != null && emergencyContactPhone.trim().isNotEmpty) {
        body['emergencyContactPhone'] = emergencyContactPhone.trim();
      }
      if (allergies != null && allergies.trim().isNotEmpty) body['allergies'] = allergies.trim();
      if (address != null && address.trim().isNotEmpty) body['address'] = address.trim();

      final res = await _apiClient.post(
        '/auth/register/patient',
        body: body,
        includeAuth: false,
      );

      final tokens = res['tokens'];
      if (tokens != null) {
        await _apiClient.tokenStorage.saveTokens(
          accessToken: tokens['accessToken'].toString(),
          refreshToken: tokens['refreshToken'].toString(),
        );
      }

      if (res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user'] as Map<String, dynamic>);
        await _apiClient.tokenStorage.saveUser(_currentUser!.toJson());
      }

      if (res['profile'] != null) {
        _currentProfile = PatientProfileModel.fromJson(res['profile'] as Map<String, dynamic>);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Logout current session
  Future<void> logout() async {
    try {
      final refreshToken = await _apiClient.tokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          '/auth/logout',
          body: {'refreshToken': refreshToken},
          includeAuth: true,
        );
      }
    } catch (_) {
      // Continue client cleanup even if network request fails
    } finally {
      await _apiClient.tokenStorage.clear();
      _currentUser = null;
      _currentProfile = null;
      notifyListeners();
    }
  }

  /// Terminate all sessions
  Future<void> logoutAll() async {
    try {
      await _apiClient.post('/auth/logout-all', includeAuth: true);
    } catch (_) {
    } finally {
      await _apiClient.tokenStorage.clear();
      _currentUser = null;
      _currentProfile = null;
      notifyListeners();
    }
  }

  void updateProfileLocally(PatientProfileModel updated) {
    _currentProfile = updated;
    notifyListeners();
  }
}
