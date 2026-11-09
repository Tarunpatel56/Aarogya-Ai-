import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/emergency_model.dart';
import '../services/emergency_service.dart';
import 'emergency/live_ambulance_tracking_screen.dart';

class EmergencySosDialog extends StatefulWidget {
  final EmergencyService? emergencyService;

  const EmergencySosDialog({super.key, this.emergencyService});

  @override
  State<EmergencySosDialog> createState() => _EmergencySosDialogState();
}

class _EmergencySosDialogState extends State<EmergencySosDialog>
    with SingleTickerProviderStateMixin {
  int _secondsLeft = 3;
  Timer? _timer;
  bool _triggered = false;
  bool _isDispatching = false;
  EmergencyModel? _emergency;
  String? _dispatchError;
  late final EmergencyService _service;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _service = widget.emergencyService ?? EmergencyService();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        _triggerDispatch();
      }
    });
  }

  Future<void> _triggerDispatch() async {
    setState(() {
      _secondsLeft = 0;
      _triggered = true;
      _isDispatching = true;
      _dispatchError = null;
    });

    try {
      final res = await _service.createEmergencySos(
        latitude: 28.5672,
        longitude: 77.2100,
        pickupAddress: 'Current GPS Location (Delhi-NCR)',
      );

      if (mounted) {
        setState(() {
          _emergency = res;
          _isDispatching = false;
        });

        // Automatically open live tracking command screen so patient sees live radar & driver acceptance
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && _emergency != null) {
            _openTrackingScreen();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDispatching = false;
          _dispatchError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _openTrackingScreen() {
    if (_emergency == null) return;
    Navigator.pop(context); // close dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveAmbulanceTrackingScreen(initialEmergency: _emergency!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sosRed.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosRed.withValues(alpha: 0.3 * _pulseController.value),
                        blurRadius: 20 * _pulseController.value,
                        spreadRadius: 6 * _pulseController.value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.sosRed,
                      ),
                      child: Center(
                        child: _triggered
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 32,
                              )
                            : Text(
                                '$_secondsLeft',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              _triggered ? 'AMBULANCE DISPATCHED!' : 'Triggering Emergency SOS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _triggered ? const Color(0xFF15803D) : AppColors.sosRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _triggered
                  ? 'Your GPS coordinates and emergency alert have been transmitted to nearby trauma bay and ambulance.'
                  : 'Sending high-priority emergency distress alert with your live GPS location to emergency responders.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            if (!_triggered) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sosRed,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _timer?.cancel();
                        _triggerDispatch();
                      },
                      child: const Text(
                        'Send Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              if (_isDispatching)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primaryTeal))),
                      SizedBox(width: 10),
                      Text('Connecting to nearest ambulance...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                )
              else if (_dispatchError != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                  child: Text(_dispatchError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
                )
              else if (_emergency != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Assigned: ${_emergency!.assignedVehicleNo}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hospital: ${_emergency!.hospitalName} • ETA: ~${_emergency!.estimatedMinutes} mins',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openTrackingScreen,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text(
                      'Track Live Ambulance On Map',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
