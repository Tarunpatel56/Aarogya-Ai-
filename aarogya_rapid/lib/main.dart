import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/api_config.dart';
import 'models/trip_model.dart';
import 'screens/active_trip_screen.dart';
import 'screens/auth/driver_login_screen.dart';
import 'screens/handover_report_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/requests_queue_screen.dart';
import 'services/ambulance_auth_service.dart';
import 'services/ambulance_dispatch_service.dart';
import 'services/ambulance_socket_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Auto-probe candidate backend hosts (tunnel / LAN / localhost)
  await ApiConfig.autoDetectBaseUrl();

  runApp(const AarogyaRapidApp());
}

class AarogyaRapidApp extends StatelessWidget {
  const AarogyaRapidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aarogya Rapid EMS',
      debugShowCheckedModeBanner: false,
      theme: SanctuaryTheme.lightTheme,
      home: const RapidRootAuthWrapper(),
    );
  }
}

class RapidRootAuthWrapper extends StatefulWidget {
  const RapidRootAuthWrapper({super.key});

  @override
  State<RapidRootAuthWrapper> createState() => _RapidRootAuthWrapperState();
}

class _RapidRootAuthWrapperState extends State<RapidRootAuthWrapper> {
  final _authService = AmbulanceAuthService();
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isAuthenticated = loggedIn;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: SanctuaryColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: SanctuaryColors.emergencyRed),
        ),
      );
    }

    if (!_isAuthenticated) {
      return DriverLoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
      );
    }

    return RapidRootNavigationHost(
      onLogout: () async {
        await _authService.logout();
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
          });
        }
      },
    );
  }
}

class RapidRootNavigationHost extends StatefulWidget {
  final VoidCallback? onLogout;

  const RapidRootNavigationHost({super.key, this.onLogout});

  @override
  State<RapidRootNavigationHost> createState() => _RapidRootNavigationHostState();
}

class _RapidRootNavigationHostState extends State<RapidRootNavigationHost> {
  int _currentIndex = 0;
  EmergencyRequest? _activeTrip;
  final List<EmergencyRequest> _queue = [];
  final List<EmergencyRequest> _completedTrips = [];
  bool _showingHandoverModal = false;

  final _dispatchService = AmbulanceDispatchService();
  final _socketService = AmbulanceSocketService();
  Timer? _pollingTimer;
  Timer? _gpsStreamTimer;

  @override
  void initState() {
    super.initState();
    _initEmsConnection();
  }

  Future<void> _initEmsConnection() async {
    // 1. Connect Socket.IO
    await _socketService.connect();
    _socketService.onEmergencyBroadcast = (data) {
      final emergency = data['emergency'];
      if (emergency is Map<String, dynamic> && mounted) {
        setState(() {
          final req = EmergencyRequest.fromJson(emergency);
          if (!_queue.any((r) => r.id == req.id) && _activeTrip?.id != req.id) {
            _queue.insert(0, req);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: SanctuaryColors.crimsonRose,
            content: Text('⚡ LIVE SOS BROADCAST: #${emergency['id']} received!'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    };

    // 2. Fetch real initial dispatches from PostgreSQL
    await _refreshDispatches();

    // 3. Setup polling fallback (every 10s)
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshDispatches();
    });
  }

  Future<void> _refreshDispatches() async {
    final dispatches = await _dispatchService.getAvailableDispatches();
    final assigned = await _dispatchService.getAssignedTrips();

    if (mounted) {
      setState(() {
        for (final req in dispatches) {
          if (!_queue.any((r) => r.id == req.id) && _activeTrip?.id != req.id) {
            _queue.add(req);
          }
        }
        if (_activeTrip == null && assigned.isNotEmpty) {
          // If driver already has an in-progress trip in PostgreSQL, resume it
          final active = assigned.firstWhere(
            (r) => r.isCritical,
            orElse: () => assigned.first,
          );
          _activeTrip = active;
        }
      });
    }
  }

  void _startGpsStreaming(String emergencyId) {
    _gpsStreamTimer?.cancel();
    double currentLat = 28.5672;
    double currentLng = 77.2100;

    _gpsStreamTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_activeTrip == null) {
        timer.cancel();
        return;
      }
      // Stream moving coordinates to tracking room via Socket.IO
      currentLat += 0.0003;
      currentLng += 0.0002;
      _socketService.streamLocation(
        emergencyId: emergencyId,
        latitude: currentLat,
        longitude: currentLng,
        speed: 42.5,
        heading: 90,
        etaMinutes: 5,
      );
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _gpsStreamTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingHandoverModal && _activeTrip != null) {
      return HandoverReportScreen(
        request: _activeTrip!,
        onBack: () {
          setState(() {
            _showingHandoverModal = false;
          });
        },
        onFinishTrip: () async {
          final tripToComplete = _activeTrip!;
          // Update PostgreSQL status to COMPLETED
          await _dispatchService.updateMilestone(tripToComplete.id, status: 'COMPLETED');

          setState(() {
            _showingHandoverModal = false;
            _completedTrips.insert(0, tripToComplete);
            _activeTrip = null;
            _currentIndex = 2; // Jump to History
          });
          _gpsStreamTimer?.cancel();
        },
      );
    }

    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Screen 1: Emergency Requests Queue / EMS Terminal
          RequestsQueueScreen(
            requests: _queue,
            activeTrip: _activeTrip,
            onAcceptDispatch: (req) async {
              final messenger = ScaffoldMessenger.of(context);
              // 1. Accept dispatch in real PostgreSQL database
              final success = await _dispatchService.acceptDispatch(req.id);
              if (success && mounted) {
                // 2. Join Socket.IO emergency room and begin live GPS coordinate streaming
                _socketService.joinEmergency(req.id);
                _startGpsStreaming(req.id);

                setState(() {
                  _activeTrip = req;
                  _queue.removeWhere((r) => r.id == req.id);
                  _currentIndex = 1; // Transition to Active Trip
                });
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: SanctuaryColors.crimsonRose,
                    content: Text('Dispatch Accepted: #${req.id} • En route to ${req.patientName}'),
                  ),
                );
              }
            },
            onOpenTrip: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),

          // Screen 2: Live En Route Navigation & Telemetry
          ActiveTripScreen(
            request: _activeTrip,
            onOpenHandoverReport: () {
              if (_activeTrip != null) {
                // Notify backend of arrival
                _dispatchService.updateMilestone(_activeTrip!.id, status: 'REACHED_HOSPITAL');
                setState(() {
                  _showingHandoverModal = true;
                });
              }
            },
            onBackToQueue: () {
              setState(() {
                _currentIndex = 0;
              });
            },
          ),

          // Screen 3: Trip History & EMS Telemetry
          HistoryScreen(
            completedTrips: _completedTrips,
          ),

          // Screen 4: Paramedic & Terminal Profile
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: RapidBottomNavBar(
        currentIndex: _currentIndex,
        pendingRequestsCount: _queue.length,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _showingHandoverModal = false;
          });
        },
      ),
    );
  }
}
