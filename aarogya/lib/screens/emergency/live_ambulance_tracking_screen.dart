import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/emergency_model.dart';
import '../../services/emergency_service.dart';
import '../../services/patient_socket_service.dart';
import '../../core/api/api_exception.dart';

class LiveAmbulanceTrackingScreen extends StatefulWidget {
  final EmergencyService? emergencyService;
  final EmergencyModel initialEmergency;

  const LiveAmbulanceTrackingScreen({
    super.key,
    this.emergencyService,
    required this.initialEmergency,
  });

  @override
  State<LiveAmbulanceTrackingScreen> createState() =>
      _LiveAmbulanceTrackingScreenState();
}

class _LiveAmbulanceTrackingScreenState
    extends State<LiveAmbulanceTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final EmergencyService _service;
  late EmergencyModel _emergency;
  Timer? _pollingTimer;
  bool _isCancelling = false;
  late AnimationController _pulseController;
  final PatientSocketService _socketService = PatientSocketService();
  double _liveSpeedKmh = 38.0;

  @override
  void initState() {
    super.initState();
    _service = widget.emergencyService ?? EmergencyService();
    _emergency = widget.initialEmergency;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initSocket();

    // Auto-poll live ambulance status every 6 seconds as backup
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _refreshStatus();
    });
  }

  void _initSocket() {
    _socketService.connect().then((_) {
      _socketService.joinEmergency(_emergency.id);
      _socketService.onAmbulanceLocationUpdated = (data) {
        if (mounted) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          final eta = (data['etaMinutes'] as num?)?.toInt();
          final speed = (data['speed'] as num?)?.toDouble();

          setState(() {
            _emergency = _emergency.copyWith(
              driverLatitude: lat,
              driverLongitude: lng,
              estimatedMinutes: eta ?? _emergency.estimatedMinutes,
            );
            if (speed != null) {
              _liveSpeedKmh = speed;
            }
          });
        }
      };

      _socketService.onEmergencyStatusUpdated = (data) {
        if (mounted) {
          final newStatus = data['status']?.toString();
          if (newStatus != null) {
            setState(() {
              _emergency = _emergency.copyWith(status: newStatus);
            });
          }
        }
      };
    });
  }

  @override
  void dispose() {
    _socketService.leaveEmergency(_emergency.id);
    _pollingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (_emergency.isCancelled || _emergency.isCompleted) return;
    try {
      final updated = await _service.getEmergencyById(_emergency.id);
      if (mounted) {
        setState(() {
          _emergency = updated;
        });
      }
    } catch (_) {}
  }

  Future<void> _simulateDriverStep() async {
    try {
      final stepped = await _service.simulateStep(_emergency.id);
      if (mounted) {
        setState(() {
          _emergency = stepped;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ambulance updated: ETA ${_emergency.estimatedMinutes} mins, Status: ${_emergency.status}',
            ),
            backgroundColor: const Color(0xFF15803D),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Simulation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Emergency SOS?'),
        content: const Text(
          'Are you sure you want to cancel the ambulance dispatch? If this was a mistake, you can cancel safely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text(
              'Yes, Cancel SOS',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      final cancelled = await _service.cancelEmergency(_emergency.id);
      if (mounted) {
        setState(() {
          _emergency = cancelled;
          _isCancelling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency SOS successfully cancelled.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Live Ambulance Tracking',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStatus,
            tooltip: 'Refresh tracking',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Banner
            _buildStatusHeader(),
            const SizedBox(height: 16),

            // Visual Tracking Radar / Map Canvas
            _buildVisualRadarCard(),
            const SizedBox(height: 16),

            // Hospital Destination & Bed Info
            _buildHospitalDestinationCard(),
            const SizedBox(height: 16),

            // Paramedic & Vehicle Details
            _buildAmbulanceDetailsCard(),
            const SizedBox(height: 20),

            // Interactive simulation button (to step closer for testing)
            OutlinedButton.icon(
              onPressed: _emergency.isActive ? _simulateDriverStep : null,
              icon: const Icon(
                Icons.navigation,
                size: 16,
                color: Color(0xFF2563EB),
              ),
              label: const Text(
                'Simulate Ambulance Moving Closer (Demo)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF93C5FD)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel SOS Button
            if (_emergency.isActive)
              ElevatedButton.icon(
                onPressed: _isCancelling ? null : _cancelSos,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(
                  _isCancelling
                      ? 'Cancelling SOS...'
                      : 'Cancel Emergency Request',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final bool isEnRoute = _emergency.status == 'EN_ROUTE';
    final Color badgeColor = _emergency.isCancelled
        ? Colors.grey
        : isEnRoute
        ? const Color(0xFF15803D)
        : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withValues(alpha: 0.12),
                  boxShadow: _emergency.isActive
                      ? [
                          BoxShadow(
                            color: badgeColor.withValues(
                              alpha: 0.3 * _pulseController.value,
                            ),
                            blurRadius: 12 * _pulseController.value,
                            spreadRadius: 3 * _pulseController.value,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _emergency.isCancelled
                      ? Icons.cancel_outlined
                      : Icons.emergency_outlined,
                  color: badgeColor,
                  size: 26,
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _emergency.isCancelled
                      ? 'SOS DISPATCH CANCELLED'
                      : isEnRoute
                      ? 'AMBULANCE EN ROUTE'
                      : 'AMBULANCE ASSIGNED & DISPATCHED',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _emergency.isCancelled
                      ? 'This request was safely called off'
                      : 'Estimated Arrival in ~${_emergency.estimatedMinutes} minutes',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualRadarCard() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background concentric radar rings
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
          ),

          // Route dashed line indicator
          Positioned(
            left: 50,
            top: 75,
            right: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                12,
                (i) => Container(
                  width: 6,
                  height: 2,
                  color: i % 2 == 0 ? Colors.white30 : Colors.transparent,
                ),
              ),
            ),
          ),

          // Patient GPS Location Pin (Left)
          Positioned(
            left: 35,
            top: 55,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You (GPS)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Ambulance Moving Location Pin (Right)
          Positioned(
            right: 35,
            top: 55,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626)
                              .withValues(alpha: 0.5 * _pulseController.value),
                          blurRadius: 10 * _pulseController.value,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _emergency.assignedVehicleNo ?? 'Ambulance',
                  style: const TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Bottom live GPS coordinates display
          Positioned(
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Live GPS: ${(_emergency.driverLatitude ?? _emergency.latitude).toStringAsFixed(4)}, ${(_emergency.driverLongitude ?? _emergency.longitude).toStringAsFixed(4)} • Moving: ~${_liveSpeedKmh.toStringAsFixed(0)} km/h',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.local_hospital,
                color: AppColors.primaryTeal,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Destination Hospital & Trauma Bay',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _emergency.hospitalName ?? 'AIIMS Emergency Trauma Bay',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Emergency team alerted • Trauma bay prepared with life support',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Emergency Hotline: ${_emergency.emergencyHotline ?? "102"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Dialing Hospital Hotline: ${_emergency.emergencyHotline ?? "102"}',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Text(
                    'Call Bay',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ASSIGNED AMBULANCE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _emergency.assignedVehicleNo ?? 'DL-01-AMB-2401',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Advanced Life Support (ALS)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _emergency.driverName ?? 'Vikram Singh (Paramedic Lead)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _emergency.driverPhone ?? '+91-9876543210',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Calling Driver: ${_emergency.driverPhone ?? "+91-9876543210"}',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.call, size: 14),
                label: const Text('Call', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
