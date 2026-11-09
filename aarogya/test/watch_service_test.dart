import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aarogya/core/api/api_client.dart';
import 'package:aarogya/core/storage/token_storage.dart';
import 'package:aarogya/core/storage/watch_preferences_storage.dart';
import 'package:aarogya/models/watch_telemetry_model.dart';
import 'package:aarogya/services/patient_service.dart';
import 'package:aarogya/services/watch_service.dart';
import 'package:aarogya/screens/health_monitoring_screen.dart';
import 'package:aarogya/screens/profile_screen.dart';
import 'package:aarogya/widgets/home/home_vitals_summary.dart';

void main() {
  group('WatchTelemetryModel Unit Tests', () {
    test('parses full telemetry JSON correctly', () {
      final json = {
        'device': {
          'name': 'FireBoltt 182',
          'macAddress': 'F4:4E:FC:B8:F3:42',
          'connectionType': 'Bluetooth Low Energy (BLE) + Classic',
          'hostInterface': 'Windows 11 BLE Radio',
          'connectionStatus': 'Connected',
          'batteryLevel': 100,
          'paired': true,
        },
        'telemetry': {
          'heartRate': {
            'bpm': 76,
            'sensorContact': true,
            'supported': true,
            'status': 'Live stream active',
          },
          'steps': {
            'value': null,
            'supported': false,
            'status': 'Proprietary protocol (0xFFD0)',
          },
          'spo2': {
            'value': null,
            'supported': false,
            'status': 'Proprietary vendor protocol',
          },
          'sleep': {
            'value': null,
            'supported': false,
            'status': 'Requires companion app',
          },
        },
        'bridgeMode': 'Local Laptop Bridge',
        'timestamp': '2026-10-28T04:20:00.000Z',
      };

      final model = WatchTelemetryModel.fromJson(json);
      expect(model.name, 'FireBoltt 182');
      expect(model.macAddress, 'F4:4E:FC:B8:F3:42');
      expect(model.batteryLevel, 100);
      expect(model.paired, true);
      expect(model.isConnected, true);
      expect(model.heartRateBpm, 76);
      expect(model.isLiveMeasuring, true);
      expect(model.stepsValue, null);
      expect(model.bridgeMode, 'Local Laptop Bridge');
    });

    test('creates disconnected fallback correctly', () {
      final model = WatchTelemetryModel.disconnected();
      expect(model.name, 'FireBoltt 182');
      expect(model.paired, false);
      expect(model.isConnected, false);
      expect(model.batteryLevel, null);
      expect(model.heartRateBpm, null);
    });

    test('WatchConnectionState labels and helpers return expected values', () {
      expect(WatchConnectionState.notConnected.label, 'Not Connected');
      expect(WatchConnectionState.connecting.label, 'Connecting');
      expect(WatchConnectionState.connected.label, 'Connected');
      expect(WatchConnectionState.connectionFailed.label, 'Connection Failed');
      expect(WatchConnectionState.disconnected.label, 'Disconnected');
      expect(WatchConnectionState.bridgeUnavailable.label, 'Laptop Bridge Unavailable');

      expect(WatchConnectionState.connected.isConnected, true);
      expect(WatchConnectionState.notConnected.isConnected, false);
      expect(WatchConnectionState.connecting.isConnecting, true);
    });
  });

  group('WatchPreferencesStorage Unit Tests', () {
    test('in-memory storage saves, retrieves and clears preference', () async {
      final storage = InMemoryWatchPreferencesStorage();
      expect(await storage.getPreference(), isNull);

      await storage.savePreference('not_now');
      expect(await storage.getPreference(), 'not_now');

      await storage.savePreference('connected');
      expect(await storage.getPreference(), 'connected');

      await storage.clear();
      expect(await storage.getPreference(), isNull);
    });
  });

  group('WatchService API Integration Tests', () {
    late InMemoryTokenStorage tokenStorage;
    late InMemoryWatchPreferencesStorage prefStorage;

    setUp(() {
      tokenStorage = InMemoryTokenStorage();
      prefStorage = InMemoryWatchPreferencesStorage();
    });

    test('fetchTelemetry queries bridge and notifies listeners', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/wearables/bridge/watch')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'device': {
                  'name': 'FireBoltt 182',
                  'macAddress': 'F4:4E:FC:B8:F3:42',
                  'connectionType': 'BLE + Classic',
                  'hostInterface': 'Windows 11 BLE Radio',
                  'connectionStatus': 'Standby (Paired to Laptop)',
                  'batteryLevel': 100,
                  'paired': true,
                },
                'telemetry': {
                  'heartRate': {
                    'bpm': null,
                    'sensorContact': false,
                    'supported': true,
                    'status': 'Sensor idle / off wrist (Standard BLE 0x180D)',
                  },
                  'steps': {'value': null, 'supported': false, 'status': 'Proprietary'},
                  'spo2': {'value': null, 'supported': false, 'status': 'Proprietary'},
                  'sleep': {'value': null, 'supported': false, 'status': 'Proprietary'},
                },
                'bridgeMode': 'Local Laptop Bridge',
                'timestamp': '2026-10-28T04:20:00.000Z',
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

      final service = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);
      final telemetry = await service.fetchTelemetry();

      expect(telemetry.name, 'FireBoltt 182');
      expect(telemetry.batteryLevel, 100);
      expect(telemetry.paired, true);
      expect(service.currentTelemetry?.name, 'FireBoltt 182');
      expect(service.connectionState, WatchConnectionState.connected);

      service.disconnect();
      expect(service.currentTelemetry?.paired, false);
      expect(service.connectionState, WatchConnectionState.disconnected);
    });

    test('fetchCapabilities returns GATT specification dictionary', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/wearables/capabilities')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'modelName': 'FireBoltt 182',
                'hardwareModel': 'FD28',
                'macAddress': 'F4:4E:FC:B8:F3:42',
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

      final service = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);
      final caps = await service.fetchCapabilities();
      expect(caps['modelName'], 'FireBoltt 182');
      expect(caps['hardwareModel'], 'FD28');
    });

    test('setNotNow persists choice and does not initiate connection', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final service = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      await service.setNotNow();

      expect(service.isPromptDismissed, true);
      expect(service.connectionState, WatchConnectionState.notConnected);
      expect(await prefStorage.getPreference(), 'not_now');
      expect(requestCount, 0); // No Bluetooth scan or bridge request made!
    });

    test('detects bridge unavailable on 503 or server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Laptop bridge offline'}), 503);
      });

      final apiClient = ApiClient(httpClient: mockClient, tokenStorage: tokenStorage);
      final service = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      try {
        await service.connect();
        fail('Should have thrown an exception on 503');
      } catch (e) {
        expect(e, isNotNull);
      }
      expect(service.connectionState, WatchConnectionState.bridgeUnavailable);
    });
  });

  group('HealthMonitoringScreen Widget Tests', () {
    testWidgets('Scenario 1: New user opens app without connecting a watch', (tester) async {
      final prefStorage = InMemoryWatchPreferencesStorage();
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final apiClient = ApiClient(httpClient: mockClient);
      final watchService = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: HealthMonitoringScreen(watchService: watchService),
        ),
      );

      // Verify Smartwatch Connection Card components
      expect(find.text('Connect Your Smartwatch'), findsOneWidget);
      expect(
        find.text('Connect your watch to view supported health measurements in Aarogya AI.'),
        findsOneWidget,
      );
      expect(find.text('Connect Watch'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      // Verify other health monitoring features are present and not blocked
      expect(find.text('Health Monitoring'), findsOneWidget);
      expect(find.text('Self-Reported Health Metrics'), findsOneWidget);
      expect(find.text('Blood Glucose'), findsOneWidget);
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Resting Pulse / Heart Rate'), findsOneWidget);
    });

    testWidgets('Scenario 2: User taps "Not Now"', (tester) async {
      int requestCount = 0;
      final prefStorage = InMemoryWatchPreferencesStorage();
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final apiClient = ApiClient(httpClient: mockClient);
      final watchService = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: HealthMonitoringScreen(watchService: watchService),
        ),
      );

      expect(find.text('Connect Your Smartwatch'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      // Tap "Not Now"
      await tester.tap(find.text('Not Now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Connection prompt card is closed
      expect(find.text('Connect Your Smartwatch'), findsNothing);
      expect(find.text('Not Now'), findsNothing);

      // No Bluetooth scanning or bridge requests occurred
      expect(requestCount, 0);

      // Preference persisted as 'not_now'
      expect(await prefStorage.getPreference(), 'not_now');

      // Hub card displays "Watch Not Connected" with "Connect Watch" button for later
      expect(find.text('Watch Not Connected'), findsOneWidget);
      expect(find.text('Connect Watch'), findsOneWidget);

      // Dashboard self-reported metrics remain fully operational
      expect(find.text('Self-Reported Health Metrics'), findsOneWidget);
    });

    testWidgets('Scenario 3: App restarts after user skips connection', (tester) async {
      // Preference already set to 'not_now'
      final prefStorage = InMemoryWatchPreferencesStorage('not_now');
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final apiClient = ApiClient(httpClient: mockClient);
      final watchService = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: HealthMonitoringScreen(watchService: watchService),
        ),
      );
      await tester.pumpAndSettle();

      // Prompt is not repeatedly shown
      expect(find.text('Connect Your Smartwatch'), findsNothing);
      expect(find.text('Not Now'), findsNothing);

      // Does not auto-initiate connection
      expect(requestCount, 0);

      // Shows "Watch Not Connected" and allows connecting later
      expect(find.text('Watch Not Connected'), findsOneWidget);
      expect(find.text('Connect Watch'), findsOneWidget);
    });

    testWidgets('Scenario 4: User connects watch later and displays real verified telemetry', (tester) async {
      final prefStorage = InMemoryWatchPreferencesStorage('not_now');
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/wearables/bridge/watch')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'device': {
                  'name': 'FireBoltt 182',
                  'macAddress': 'F4:4E:FC:B8:F3:42',
                  'connectionType': 'BLE + Classic',
                  'hostInterface': 'Windows 11 BLE Radio',
                  'connectionStatus': 'Connected',
                  'batteryLevel': 100,
                  'paired': true,
                },
                'telemetry': {
                  'heartRate': {
                    'bpm': 74,
                    'sensorContact': true,
                    'supported': true,
                    'status': 'Live stream active',
                  },
                  'steps': {'value': null, 'supported': false, 'status': 'DaFit sync'},
                  'spo2': {'value': null, 'supported': false, 'status': 'Proprietary'},
                  'sleep': {'value': null, 'supported': false, 'status': 'Proprietary'},
                },
                'bridgeMode': 'Local Laptop Bridge',
                'timestamp': '2026-10-28T04:20:00.000Z',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(
        tokenStorage: InMemoryTokenStorage(),
        httpClient: mockClient,
      );
      final watchService = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: HealthMonitoringScreen(watchService: watchService),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Connect Watch
      await tester.tap(find.text('Connect Watch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // Check connected watch state
      expect(find.text('FireBoltt 182'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('74 BPM'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Vendor Protocol Notice (Steps, SpO2 & Sleep)'), findsOneWidget);

      // Verify preference saved as connected
      expect(await prefStorage.getPreference(), 'connected');
    });

    testWidgets('Scenario 5: User disconnects the watch', (tester) async {
      final prefStorage = InMemoryWatchPreferencesStorage('connected');
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/wearables/bridge/watch')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'device': {
                  'name': 'FireBoltt 182',
                  'macAddress': 'F4:4E:FC:B8:F3:42',
                  'connectionStatus': 'Connected',
                  'batteryLevel': 95,
                  'paired': true,
                },
                'telemetry': {
                  'heartRate': {'bpm': 72, 'sensorContact': true, 'supported': true},
                  'steps': {'value': null, 'supported': false},
                  'spo2': {'value': null, 'supported': false},
                  'sleep': {'value': null, 'supported': false},
                },
                'bridgeMode': 'Local Laptop Bridge',
                'timestamp': '2026-10-28T04:20:00.000Z',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(
        tokenStorage: InMemoryTokenStorage(),
        httpClient: mockClient,
      );
      final watchService = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: HealthMonitoringScreen(watchService: watchService),
        ),
      );
      await tester.pumpAndSettle();

      // Connect watch
      await tester.tap(find.text('Connect Watch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('FireBoltt 182'), findsOneWidget);

      // Disconnect
      final disconnectBtn = find.byTooltip('Disconnect');
      expect(disconnectBtn, findsOneWidget);
      await tester.tap(disconnectBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // After disconnect: displays "Watch Not Connected" and "Connect Watch" button
      expect(find.text('Watch Not Connected'), findsOneWidget);
      expect(find.text('Connect Watch'), findsOneWidget);
      expect(await prefStorage.getPreference(), 'disconnected');
    });

    testWidgets('Scenario 6: Laptop or backend bridge is unavailable', (tester) async {
      final prefStorage = InMemoryWatchPreferencesStorage();
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Laptop bridge unavailable on host'}), 503);
      });

      final apiClient = ApiClient(
        tokenStorage: InMemoryTokenStorage(),
        httpClient: mockClient,
      );
      final watchService = WatchService(apiClient: apiClient, preferencesStorage: prefStorage);

      await tester.pumpWidget(
        MaterialApp(
          home: HealthMonitoringScreen(watchService: watchService),
        ),
      );

      // Tap Connect Watch
      await tester.tap(find.text('Connect Watch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // Displays Laptop Bridge Unavailable state clearly
      expect(find.text('Laptop Bridge Unavailable'), findsWidgets);
      expect(
        find.textContaining('Laptop bridge or backend server is unreachable'),
        findsOneWidget,
      );

      // Health metrics remain active and unblocked
      expect(find.text('Self-Reported Health Metrics'), findsOneWidget);
      expect(find.text('Blood Glucose'), findsOneWidget);
    });
  });

  group('Home Screen Wearable Sync Card Adaptivity Tests', () {
    testWidgets('Home screen card renders "Connect Your Watch" with Connect button when not connected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeVitalsSummary(
              glucoseReading: '95 mg/dL',
              glucoseSub: 'Fasting',
              hasLoggedGlucose: true,
              connectionState: WatchConnectionState.notConnected,
              watchTelemetry: null,
              onGlucoseLogged: (mgDl, type) {},
              onNavigateToHealth: () {},
            ),
          ),
        ),
      );

      expect(find.text('WEARABLE SYNC'), findsOneWidget);
      expect(find.text('Connect Your Watch'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('Home screen card renders actual device name and telemetry when connected', (tester) async {
      final telemetry = WatchTelemetryModel(
        name: 'FireBoltt 182',
        macAddress: 'F4:4E:FC:B8:F3:42',
        connectionType: 'BLE',
        hostInterface: 'Win11',
        connectionStatus: 'Connected',
        batteryLevel: 100,
        paired: true,
        heartRateBpm: 74,
        heartRateSensorContact: true,
        heartRateStatus: 'Active',
        stepsValue: null,
        stepsStatus: 'DaFit',
        spo2Value: null,
        spo2Status: 'N/A',
        sleepValue: null,
        sleepStatus: 'N/A',
        bridgeMode: 'Laptop',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeVitalsSummary(
              glucoseReading: '95 mg/dL',
              glucoseSub: 'Fasting',
              hasLoggedGlucose: true,
              connectionState: WatchConnectionState.connected,
              watchTelemetry: telemetry,
              onGlucoseLogged: (mgDl, type) {},
              onNavigateToHealth: () {},
            ),
          ),
        ),
      );

      expect(find.text('WEARABLE SYNC'), findsOneWidget);
      expect(find.text('FireBoltt 182'), findsOneWidget);
      expect(find.text('100% • 74 BPM'), findsOneWidget);
      expect(find.text('Manage Watch >'), findsOneWidget);
    });

    testWidgets('Home screen card explains bridge unavailable when bridge is down', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeVitalsSummary(
              glucoseReading: '95 mg/dL',
              glucoseSub: 'Fasting',
              hasLoggedGlucose: true,
              connectionState: WatchConnectionState.bridgeUnavailable,
              watchTelemetry: null,
              onGlucoseLogged: (mgDl, type) {},
              onNavigateToHealth: () {},
            ),
          ),
        ),
      );

      expect(find.text('WEARABLE SYNC'), findsOneWidget);
      expect(find.text('Bridge Unavailable'), findsOneWidget);
      expect(find.text('Laptop bridge or backend is unavailable'), findsOneWidget);
      expect(find.text('Check Bridge >'), findsOneWidget);
    });
  });

  group('Profile Screen Settings - Manage Devices Tests', () {
    testWidgets('Profile screen shows Connect Smartwatch option and opens settings dialog', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/patients/profile')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'p1',
                'fullName': 'Aarav Sharma',
                'abhaId': '12-3456-7890-1234',
                'bloodGroup': 'O+',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final apiClient = ApiClient(tokenStorage: InMemoryTokenStorage(), httpClient: mockClient);
      final patientService = PatientService(apiClient: apiClient);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(patientService: patientService),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('Devices & Wearables'), findsOneWidget);
      expect(find.text('Connect Smartwatch'), findsOneWidget);

      // Tap on Connect Smartwatch tile (scroll to ensure visible in 800x600 viewport)
      await tester.ensureVisible(find.text('Connect Smartwatch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connect Smartwatch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Manage Devices bottom sheet opens
      expect(find.text('Manage Devices'), findsOneWidget);
      expect(find.text('Watch Not Connected'), findsOneWidget);
      expect(find.text('Connect Watch'), findsOneWidget);
      expect(find.text('Reset Setup Preference'), findsOneWidget);
    });
  });
}
