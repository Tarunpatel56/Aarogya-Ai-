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
import 'screens/splash/rapid_splash_screen.dart';

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
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return RapidSplashScreen(
        authService: _authService,
        onSessionChecked: (hasSession) {
          if (mounted) {
            setState(() {
              _isAuthenticated = hasSession;
              _isCheckingAuth = false;
            });
          }
        },
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

    // 2. Setup real-time driver verification listener
    _socketService.onDriverVerificationUpdated = (data) {
      if (mounted) {
        final status = data['status']?.toString() ?? 'UPDATED';
        final reason = data['rejectionReason']?.toString() ?? '';
        final isVerified = status == 'VERIFIED';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isVerified ? SanctuaryColors.optimalGreen : SanctuaryColors.crimsonRose,
            content: Text(
              isVerified
                  ? '✓ Your Driver & Ambulance credentials have been verified! Duty mode is unlocked.'
                  : '⚠️ Driver verification updated: $status ${reason.isNotEmpty ? "($reason)" : ""}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {});
      }
    };



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

    // Remove emergency from queue if another unit accepted it first
    _socketService.onEmergencyClaimed = (data) {
      final emergencyId = data['emergencyId']?.toString();
      final claimedBy = data['driverName']?.toString() ?? 'Another Unit';
      if (emergencyId != null && mounted) {
        setState(() {
          _queue.removeWhere((r) => r.id == emergencyId);
        });
        if (_activeTrip?.id != emergencyId) {
          final shortId = emergencyId.length > 8 ? emergencyId.substring(0, 8) : emergencyId;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF334155),
              content: Text('⚡ Emergency #$shortId claimed by $claimedBy'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    };

    // 4. Fetch real initial dispatches from PostgreSQL
    await _refreshDispatches();

    // 5. Setup polling fallback (every 10s)
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

  void _startGpsStreaming(String emergencyId, {double? targetLat, double? targetLng}) {
    _gpsStreamTimer?.cancel();
    final pLat = targetLat ?? _activeTrip?.latitude ?? 28.5672;
    final pLng = targetLng ?? _activeTrip?.longitude ?? 77.2100;

    double currentLat = pLat + 0.012; // Start ~1.3 km away
    double currentLng = pLng + 0.010;
    int remainingMinutes = 6;
    double currentSpeed = 44.0;

    // Send first coordinate packet immediately to engage live tracking
    _socketService.streamLocation(
      emergencyId: emergencyId,
      latitude: currentLat,
      longitude: currentLng,
      speed: currentSpeed,
      heading: 220,
      etaMinutes: remainingMinutes,
    );

    _gpsStreamTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_activeTrip == null) {
        timer.cancel();
        return;
      }

      // Smooth step towards patient coordinates
      final dLat = (pLat - currentLat) * 0.08;
      final dLng = (pLng - currentLng) * 0.08;
      currentLat += dLat;
      currentLng += dLng;

      // Realistic GPS micro-movement jitter so coordinates visibly update
      currentLat += (0.00003 * ((timer.tick % 2 == 0) ? 1 : -0.5));
      currentLng += (0.00002 * ((timer.tick % 3 == 0) ? 1 : -0.5));

      if (remainingMinutes > 1 && timer.tick % 6 == 0) {
        remainingMinutes--;
      }

      currentSpeed = 38.0 + (timer.tick % 5) * 2.5;

      _socketService.streamLocation(
        emergencyId: emergencyId,
        latitude: currentLat,
        longitude: currentLng,
        speed: currentSpeed,
        heading: 215,
        etaMinutes: remainingMinutes,
      );

      // Update local state in ambulance app so driver sees live telemetry
      if (mounted) {
        setState(() {
          _activeTrip = _activeTrip?.copyWith(
            driverLatitude: currentLat,
            driverLongitude: currentLng,
            eta: '$remainingMinutes mins',
          );
        });
      }
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
          final messenger = ScaffoldMessenger.of(context);
          final tripToComplete = _activeTrip!;
          // Update PostgreSQL status to COMPLETED
          await _dispatchService.updateMilestone(tripToComplete.id, status: 'COMPLETED');

          if (!mounted) return;
          setState(() {
            _showingHandoverModal = false;
            _completedTrips.insert(0, tripToComplete);
            _activeTrip = null;
            _currentIndex = 0; // Return to Emergency Queue / Active Standby for NEXT ORDER!
          });
          _gpsStreamTimer?.cancel();
          messenger.showSnackBar(
            SnackBar(
              content: Text('✓ Rescue Mission #${tripToComplete.id} Completed! Unit is on Active Standby for Next Order.'),
              backgroundColor: SanctuaryColors.optimalGreen,
              duration: const Duration(seconds: 4),
            ),
          );
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
                _startGpsStreaming(req.id, targetLat: req.latitude, targetLng: req.longitude);

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
          ProfileScreen(
            onLogout: widget.onLogout,
          ),
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
