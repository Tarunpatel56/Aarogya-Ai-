import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya_healthpro/core/api/api_client.dart';
import 'package:aarogya_healthpro/core/api/api_exception.dart';
import 'package:aarogya_healthpro/core/storage/token_storage.dart';

void main() {
  group('Doctor ApiClient Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
    });

    test('Attaches Authorization header when access token is present', () async {
      await tokenStorage.saveTokens(
        accessToken: 'valid_doctor_token',
        refreshToken: 'valid_refresh_token',
      );

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer valid_doctor_token');
        return http.Response(jsonEncode({'status': 'success', 'data': {'role': 'DOCTOR'}}), 200);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final res = await apiClient.get('/doctors/me');
      expect(res['role'], 'DOCTOR');
    });

    test('Throws ApiException with statusCode and message on HTTP 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'error',
            'message': 'Invalid medical license number',
            'code': 'VALIDATION_ERROR',
          }),
          400,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      await expectLater(
        () => apiClient.post('/doctors/me/availability', body: {}),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Invalid medical license number')),
      );
    });

    test('Throws isConflict = true on HTTP 409 slot overlap', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'fail',
            'message': 'Overlapping availability slot already exists',
            'code': 'SLOT_CONFLICT',
          }),
          409,
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      try {
        await apiClient.post('/doctors/me/availability', body: {});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.isConflict, true);
        expect(e.message, contains('Overlapping availability slot'));
      }
    });

    test('Refreshes token on 401 and retries original request', () async {
      await tokenStorage.saveTokens(
        accessToken: 'expired_doctor_token',
        refreshToken: 'valid_refresh_token',
      );

      var callCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          expect(jsonDecode(request.body)['refreshToken'], 'valid_refresh_token');
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'accessToken': 'refreshed_doctor_token',
                'refreshToken': 'refreshed_refresh_token',
              },
            }),
            200,
          );
        }

        callCount++;
        if (callCount == 1) {
          expect(request.headers['Authorization'], 'Bearer expired_doctor_token');
          return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
        } else {
          expect(request.headers['Authorization'], 'Bearer refreshed_doctor_token');
          return http.Response(jsonEncode({'status': 'success', 'data': {'doctor': 'Dr. Mehta'}}), 200);
        }
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final res = await apiClient.get('/doctors/me');
      expect(res['doctor'], 'Dr. Mehta');
      expect(await tokenStorage.getAccessToken(), 'refreshed_doctor_token');
      expect(await tokenStorage.getRefreshToken(), 'refreshed_refresh_token');
    });

    test('Clears tokens and triggers onSessionExpired when refresh token fails', () async {
      await tokenStorage.saveTokens(
        accessToken: 'expired_doctor_token',
        refreshToken: 'revoked_refresh_token',
      );

      bool sessionExpiredFired = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(jsonEncode({'message': 'Refresh token revoked'}), 401);
        }
        return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
        onSessionExpired: () {
          sessionExpiredFired = true;
        },
      );

      await expectLater(
        () => apiClient.get('/doctors/me'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', true)),
      );

      expect(sessionExpiredFired, true);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });
  });
}
