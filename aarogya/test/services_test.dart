import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya/core/api/api_client.dart';
import 'package:aarogya/core/storage/token_storage.dart';
import 'package:aarogya/services/auth_service.dart';
import 'package:aarogya/services/patient_service.dart';
import 'package:aarogya/services/doctor_service.dart';
import 'package:aarogya/services/appointment_service.dart';
import 'package:aarogya/services/notification_service.dart';

void main() {
  group('Patient App Services Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
    });

    test('AuthService logs in successfully and stores tokens', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'user': {
                  'id': 'usr-123',
                  'email': 'patient@example.com',
                  'role': 'PATIENT',
                  'phoneNumber': '+919876543210',
                },
                'profile': {
                  'id': 'pat-123',
                  'userId': 'usr-123',
                  'fullName': 'Test Patient',
                  'dateOfBirth': '1995-05-15T00:00:00.000Z',
                  'gender': 'MALE',
                  'bloodGroup': 'O+',
                  'emergencyContactName': 'Jane Doe',
                  'emergencyContactPhone': '+919876543211',
                  'allergies': 'Penicillin',
                },
                'tokens': {
                  'accessToken': 'test_acc_token',
                  'refreshToken': 'test_ref_token',
                },
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final authService = AuthService(apiClient: apiClient);

      await authService.login(email: 'patient@example.com', password: 'Password@123');
      expect(authService.currentUser?.id, 'usr-123');
      expect(authService.currentUser?.email, 'patient@example.com');
      expect(authService.currentProfile?.fullName, 'Test Patient');
      expect(await tokenStorage.getAccessToken(), 'test_acc_token');
      expect(await tokenStorage.getRefreshToken(), 'test_ref_token');
    });

    test('DoctorService lists verified doctors and filters', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/doctors')) {
          expect(request.url.queryParameters['specialization'], 'Cardiology');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': [
                {
                  'id': 'doc-1',
                  'userId': 'u-doc-1',
                  'fullName': 'Dr. Sharma',
                  'specialization': 'Cardiology',
                  'medicalLicenseNumber': 'MCI-9988',
                  'experienceYears': 12,
                  'consultationFee': 750,
                  'consultationModes': ['IN_PERSON', 'ONLINE'],
                  'hospitalAffiliation': 'AIIMS',
                  'verifiedAt': '2025-01-01T00:00:00.000Z',
                }
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final doctorService = DoctorService(apiClient: apiClient);
      final docs = await doctorService.getDoctors(specialization: 'Cardiology');
      expect(docs.length, 1);
      expect(docs.first.fullName, 'Dr. Sharma');
      expect(docs.first.isVerified, true);
      expect(docs.first.consultationFee, 750.0);
    });

    test('AppointmentService requests appointment and parses response', () async {
      final startTime = DateTime.now().add(const Duration(days: 1));
      final endTime = startTime.add(const Duration(minutes: 30));

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/appointments')) {
          final body = jsonDecode(request.body);
          expect(body['doctorProfileId'], 'doc-1');
          expect(body['mode'], 'ONLINE');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'apt-555',
                'patientProfileId': 'pat-123',
                'doctorProfileId': 'doc-1',
                'startTime': startTime.toUtc().toIso8601String(),
                'endTime': endTime.toUtc().toIso8601String(),
                'mode': 'ONLINE',
                'status': 'REQUESTED',
                'reason': 'Routine heart checkup',
              },
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final appointmentService = AppointmentService(apiClient: apiClient);
      final apt = await appointmentService.requestAppointment(
        doctorProfileId: 'doc-1',
        startTime: startTime,
        endTime: endTime,
        mode: 'ONLINE',
        reason: 'Routine heart checkup',
      );

      expect(apt.id, 'apt-555');
      expect(apt.status, 'REQUESTED');
      expect(apt.reason, 'Routine heart checkup');
    });

    test('PatientService updates profile correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/patients/me') && request.method == 'PATCH') {
          final body = jsonDecode(request.body);
          expect(body['bloodGroup'], 'AB+');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'pat-123',
                'userId': 'usr-123',
                'fullName': 'Updated Name',
                'dateOfBirth': '1995-05-15T00:00:00.000Z',
                'gender': 'MALE',
                'bloodGroup': 'AB+',
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final patientService = PatientService(apiClient: apiClient);
      final updated = await patientService.updateProfile(fullName: 'Updated Name', bloodGroup: 'AB+');
      expect(updated.bloodGroup, 'AB+');
      expect(updated.fullName, 'Updated Name');
    });

    test('NotificationService fetches and marks as read', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'notifications': [
                  {
                    'id': 'notif-1',
                    'userId': 'usr-123',
                    'title': 'Appointment Confirmed',
                    'message': 'Your appointment with Dr. Sharma is confirmed',
                    'type': 'APPOINTMENT_CONFIRMED',
                    'isRead': false,
                    'createdAt': DateTime.now().toUtc().toIso8601String(),
                  }
                ]
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/notifications/notif-1/read') && request.method == 'PATCH') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'id': 'notif-1',
                'isRead': true,
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final notifService = NotificationService(apiClient: apiClient);
      final notifs = await notifService.getNotifications();
      expect(notifs.length, 1);
      expect(notifs.first.isRead, false);

      await notifService.markAsRead('notif-1');
    });
  });
}
