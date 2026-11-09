import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/doctor_user_model.dart';
import '../models/doctor_profile_model.dart';

class DoctorAuthService extends ChangeNotifier {
  final ApiClient _apiClient;
  DoctorUserModel? _currentUser;
  DoctorProfileModel? _currentProfile;
  bool _isLoading = false;

  DoctorAuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;
  DoctorUserModel? get currentUser => _currentUser;
  DoctorProfileModel? get currentProfile => _currentProfile;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  /// Restores doctor session on app startup
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
        final user = DoctorUserModel.fromJson(userData['user'] as Map<String, dynamic>);
        if (user.role != 'DOCTOR' &&
            user.role != 'HOSPITAL_ADMIN' &&
            user.role != 'PLATFORM_ADMIN' &&
            user.role != 'SUPER_ADMIN') {
          // Reject patient and driver accounts in HealthPro
          await _apiClient.tokenStorage.clear();
          _isLoading = false;
          notifyListeners();
          return false;
        }
        _currentUser = user;
      }

      try {
        final profileData = await _apiClient.get('/doctors/me');
        final pData = profileData is Map<String, dynamic> && profileData.containsKey('profile')
            ? profileData['profile']
            : (profileData is Map<String, dynamic> && profileData.containsKey('doctor')
                ? profileData['doctor']
                : profileData);
        if (pData is Map<String, dynamic>) {
          _currentProfile = DoctorProfileModel.fromJson(pData);
        }
      } catch (_) {
        // Profile fetch might fail if not yet created
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

  /// Doctor Login
  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email.trim(),
          'password': password,
        },
        includeAuth: false,
      );

      final userData = res['user'];
      if (userData != null) {
        final user = DoctorUserModel.fromJson(userData as Map<String, dynamic>);
        if (user.role != 'DOCTOR' &&
            user.role != 'HOSPITAL_ADMIN' &&
            user.role != 'PLATFORM_ADMIN' &&
            user.role != 'SUPER_ADMIN') {
          throw const ApiException(
            statusCode: 403,
            message: 'Access denied: This portal is exclusively for verified medical doctors and hospital administrators.',
            code: 'ROLE_FORBIDDEN',
          );
        }
        _currentUser = user;
      }

      final tokens = res['tokens'];
      if (tokens != null) {
        await _apiClient.tokenStorage.saveTokens(
          accessToken: tokens['accessToken'].toString(),
          refreshToken: tokens['refreshToken'].toString(),
        );
      }

      if (_currentUser != null) {
        await _apiClient.tokenStorage.saveUser(_currentUser!.toJson());
      }

      // Load doctor profile
      try {
        final pData = res['profile'] ?? res['doctorProfile'];
        if (pData != null) {
          _currentProfile = DoctorProfileModel.fromJson(pData as Map<String, dynamic>);
        } else {
          final profileData = await _apiClient.get('/doctors/me');
          final data = profileData is Map<String, dynamic> && profileData.containsKey('profile')
              ? profileData['profile']
              : (profileData is Map<String, dynamic> && profileData.containsKey('doctor')
                  ? profileData['doctor']
                  : profileData);
          if (data is Map<String, dynamic>) {
            _currentProfile = DoctorProfileModel.fromJson(data);
          }
        }
      } catch (_) {
        // Ignore profile retrieval error during initial login
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Doctor Registration
  Future<void> registerDoctor({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String specialization,
    required String medicalLicenseNumber,
    required String qualifications,
    required int experienceYears,
    required double consultationFee,
    String? bio,
    List<String> consultationModes = const ['IN_PERSON', 'ONLINE'],
    String? hospitalAffiliation,
    String? clinicAddress,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        'phone': phoneNumber.trim(),
        'phoneNumber': phoneNumber.trim(),
        'specialization': specialization.trim(),
        'nmcRegistrationNumber': medicalLicenseNumber.trim(),
        'medicalLicenseNumber': medicalLicenseNumber.trim(),
        'qualifications': qualifications.trim(),
        'experienceYears': experienceYears,
        'consultationFee': consultationFee,
        'consultationModes': consultationModes,
      };
      if (bio != null && bio.trim().isNotEmpty) body['bio'] = bio.trim();
      if (hospitalAffiliation != null && hospitalAffiliation.trim().isNotEmpty) {
        body['hospitalAffiliation'] = hospitalAffiliation.trim();
      }
      if (clinicAddress != null && clinicAddress.trim().isNotEmpty) {
        body['clinicAddress'] = clinicAddress.trim();
      }

      final res = await _apiClient.post(
        '/auth/register/doctor',
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
        _currentUser = DoctorUserModel.fromJson(res['user'] as Map<String, dynamic>);
        await _apiClient.tokenStorage.saveUser(_currentUser!.toJson());
      }

      final pData = res['profile'] ?? res['doctorProfile'];
      if (pData != null) {
        _currentProfile = DoctorProfileModel.fromJson(pData as Map<String, dynamic>);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update profile locally
  void updateProfileLocally(DoctorProfileModel profile) {
    _currentProfile = profile;
    notifyListeners();
  }

  /// Logout current session
  Future<void> logout() async {
    try {
      final refreshToken = await _apiClient.tokenStorage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          '/auth/logout',
          body: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Continue client cleanup even if backend fails
    } finally {
      await _apiClient.tokenStorage.clear();
      _currentUser = null;
      _currentProfile = null;
      notifyListeners();
    }
  }

  /// For unit testing and offline preview
  @visibleForTesting
  void setProfileForTesting(DoctorProfileModel profile) {
    _currentProfile = profile;
  }

  /// Logout all sessions
  Future<void> logoutAll() async {
    try {
      await _apiClient.post('/auth/logout-all', body: {});
    } catch (_) {
      // Continue client cleanup
    } finally {
      await _apiClient.tokenStorage.clear();
      _currentUser = null;
      _currentProfile = null;
      notifyListeners();
    }
  }
}
