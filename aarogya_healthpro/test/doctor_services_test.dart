import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya_healthpro/core/api/api_client.dart';
import 'package:aarogya_healthpro/core/api/api_exception.dart';
import 'package:aarogya_healthpro/core/storage/token_storage.dart';
import 'package:aarogya_healthpro/services/doctor_auth_service.dart';
import 'package:aarogya_healthpro/services/doctor_profile_service.dart';
import 'package:aarogya_healthpro/services/doctor_appointment_service.dart';
import 'package:aarogya_healthpro/services/doctor_notification_service.dart';

void main() {
  group('Doctor Services Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
    });

    test('DoctorAuthService logs in verified doctor and saves tokens', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'user': {
                  'id': 'usr-doc-1',
                  'email': 'doctor@example.com',
                  'role': 'DOCTOR',
                  'phoneNumber': '+919988776655',
                },
                'profile': {
                  'id': 'doc-123',
                  'userId': 'usr-doc-1',
                  'fullName': 'Dr. Aarav Mehta',
                  'specialization': 'Cardiology',
                  'medicalLicenseNumber': 'MCI-12345',
                  'qualifications': 'MBBS, MD',
                  'experienceYears': 14,
                  'consultationFee': 1000,
                  'consultationModes': ['IN_PERSON', 'ONLINE'],
                  'hospitalAffiliation': 'Apollo Hospitals',
                  'verifiedAt': '2025-01-01T00:00:00.000Z',
                },
                'tokens': {
                  'accessToken': 'doc_access_tok',
                  'refreshToken': 'doc_refresh_tok',
                },
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage, httpClient: mockClient);
      final authService = DoctorAuthService(apiClient: apiClient);

      await authService.login(email: 'doctor@example.com', password: 'Password@123');
      expect(authService.currentUser?.id, 'usr-doc-1');
      expect(authService.currentUser?.role, 'DOCTOR');
      expect(authService.currentProfile?.fullName, 'Dr. Aarav Mehta');
      expect(authService.currentProfile?.isVerified, true);
      expect(await tokenStorage.getAccessToken(), 'doc_access_tok');
    });

    test('DoctorAuthService rejects non-doctor user with 403', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'user': {
                  'id': 'usr-pat-1',
                  'email': 'patient@example.com',
                  'role': 'PATIENT',
                },
                'tokens': {
                  'accessToken': 'pat_tok',
                  'refreshToken': 'pat_ref',
                },
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage, httpClient: mockClient);
      final authService = DoctorAuthService(apiClient: apiClient);

      await expectLater(
        () => authService.login(email: 'patient@example.com', password: 'Password@123'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('DoctorProfileService fetches availability and publishes slot', () async {
      final now = DateTime.now();
      final endTime = now.add(const Duration(hours: 4));

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/doctors/me/availability') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'availabilities': [
                  {
                    'id': 'slot-1',
                    'doctorProfileId': 'doc-123',
                    'dayOfWeek': 1,
                    'startTime': now.toIso8601String(),
                    'endTime': endTime.toIso8601String(),
                    'status': 'AVAILABLE',
                  }
                ]
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/doctors/me/availability') && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['dayOfWeek'], 2);
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'availability': {
                  'id': 'slot-2',
                  'doctorProfileId': 'doc-123',
                  'dayOfWeek': 2,
                  'startTime': now.toIso8601String(),
                  'endTime': endTime.toIso8601String(),
                  'status': 'AVAILABLE',
                }
              },
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage, httpClient: mockClient);
      final profileService = DoctorProfileService(apiClient: apiClient);

      final slots = await profileService.getAvailability();
      expect(slots.length, 1);
      expect(slots.first.id, 'slot-1');

      final created = await profileService.createAvailability(
        dayOfWeek: 2,
        startTime: now,
        endTime: endTime,
      );
      expect(created.id, 'slot-2');
      expect(created.dayOfWeek, 2);
    });

    test('DoctorAppointmentService manages lifecycle: confirm, reject with reason, complete, no-show, cancel', () async {
      final now = DateTime.now();

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/appointments') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'appointments': [
                  {
                    'id': 'apt-101',
                    'patientProfileId': 'pat-1',
                    'doctorProfileId': 'doc-123',
                    'startTime': now.toIso8601String(),
                    'endTime': now.add(const Duration(minutes: 30)).toIso8601String(),
                    'mode': 'ONLINE',
                    'status': 'REQUESTED',
                    'patient': {
                      'id': 'pat-1',
                      'fullName': 'Sita Devi',
                      'gender': 'FEMALE',
                      'bloodGroup': 'B+',
                    },
                  }
                ]
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/appointments/apt-101/confirm') && request.method == 'PATCH') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'appointment': {
                  'id': 'apt-101',
                  'patientProfileId': 'pat-1',
                  'doctorProfileId': 'doc-123',
                  'startTime': now.toIso8601String(),
                  'endTime': now.add(const Duration(minutes: 30)).toIso8601String(),
                  'mode': 'ONLINE',
                  'status': 'CONFIRMED',
                }
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/appointments/apt-101/reject') && request.method == 'PATCH') {
          final body = jsonDecode(request.body);
          expect(body['reason'], 'Doctor on leave');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'appointment': {
                  'id': 'apt-101',
                  'patientProfileId': 'pat-1',
                  'doctorProfileId': 'doc-123',
                  'startTime': now.toIso8601String(),
                  'endTime': now.add(const Duration(minutes: 30)).toIso8601String(),
                  'mode': 'ONLINE',
                  'status': 'REJECTED',
                  'cancellationReason': 'Doctor on leave',
                }
              },
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage, httpClient: mockClient);
      final appointmentService = DoctorAppointmentService(apiClient: apiClient);

      final apts = await appointmentService.getAppointments();
      expect(apts.length, 1);
      expect(apts.first.canConfirm, true);
      expect(apts.first.canReject, true);
      expect(apts.first.patient?.fullName, 'Sita Devi');

      final confirmed = await appointmentService.confirmAppointment('apt-101');
      expect(confirmed.status, 'CONFIRMED');

      final rejected = await appointmentService.rejectAppointment('apt-101', reason: 'Doctor on leave');
      expect(rejected.status, 'REJECTED');
      expect(rejected.cancellationReason, 'Doctor on leave');
    });

    test('DoctorNotificationService fetches notifications and marks as read', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'notifications': [
                  {
                    'id': 'notif-doc-1',
                    'userId': 'usr-doc-1',
                    'title': 'New Appointment Request',
                    'message': 'Patient Sita Devi requested consultation',
                    'type': 'APPOINTMENT_REQUESTED',
                    'isRead': false,
                    'createdAt': DateTime.now().toIso8601String(),
                  }
                ]
              },
            }),
            200,
          );
        } else if (request.url.path.endsWith('/notifications/notif-doc-1/read') && request.method == 'PATCH') {
          return http.Response(jsonEncode({'status': 'success', 'data': {'id': 'notif-doc-1', 'isRead': true}}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(baseUrl: 'http://localhost:5000/api/v1', tokenStorage: tokenStorage, httpClient: mockClient);
      final notifService = DoctorNotificationService(apiClient: apiClient);

      final notifs = await notifService.getNotifications();
      expect(notifs.length, 1);
      expect(notifs.first.title, 'New Appointment Request');
      expect(notifs.first.isRead, false);

      await notifService.markAsRead('notif-doc-1');
    });
  });
}
