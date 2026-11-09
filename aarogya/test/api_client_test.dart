import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya/core/api/api_client.dart';
import 'package:aarogya/core/api/api_exception.dart';
import 'package:aarogya/core/storage/token_storage.dart';

void main() {
  group('ApiClient Tests', () {
    late InMemoryTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
    });

    test('Attaches Authorization header when access token is present', () async {
      await tokenStorage.saveTokens(
        accessToken: 'valid_access_token',
        refreshToken: 'valid_refresh_token',
      );

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer valid_access_token');
        return http.Response(jsonEncode({'status': 'success', 'data': {'foo': 'bar'}}), 200);
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final res = await apiClient.get('/test');
      expect(res['foo'], 'bar');
    });

    test('Throws ApiException with statusCode and message on HTTP 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'error',
            'message': 'Invalid email or password format',
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
        () => apiClient.post('/test', body: {}),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Invalid email or password format')),
      );
    });

    test('Throws isConflict = true on HTTP 409 double-booking', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 'fail',
            'message': 'Doctor already has an overlapping appointment in this time window',
            'code': 'APPOINTMENT_CONFLICT',
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
        await apiClient.post('/appointments', body: {});
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.isConflict, true);
        expect(e.message, contains('overlapping appointment'));
      }
    });

    test('Attempts token refresh on 401 and retries original request', () async {
      await tokenStorage.saveTokens(
        accessToken: 'expired_access_token',
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
                'accessToken': 'new_refreshed_access_token',
                'refreshToken': 'new_refreshed_refresh_token',
              },
            }),
            200,
          );
        }

        callCount++;
        if (callCount == 1) {
          // First attempt with expired token
          expect(request.headers['Authorization'], 'Bearer expired_access_token');
          return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
        } else {
          // Retry attempt with refreshed token
          expect(request.headers['Authorization'], 'Bearer new_refreshed_access_token');
          return http.Response(jsonEncode({'status': 'success', 'data': {'item': 123}}), 200);
        }
      });

      final apiClient = ApiClient(
        baseUrl: 'http://localhost:5000/api/v1',
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final res = await apiClient.get('/secure-resource');
      expect(res['item'], 123);
      expect(await tokenStorage.getAccessToken(), 'new_refreshed_access_token');
      expect(await tokenStorage.getRefreshToken(), 'new_refreshed_refresh_token');
    });

    test('Clears tokens and fires onSessionExpired if refresh fails', () async {
      await tokenStorage.saveTokens(
        accessToken: 'expired_access_token',
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
        () => apiClient.get('/profile'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', true)),
      );

      expect(sessionExpiredFired, true);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });
  });
}
