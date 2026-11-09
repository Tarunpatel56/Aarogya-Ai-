import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_watch_service.dart';
import '../models/watch_telemetry_model.dart';
import '../theme/app_theme.dart';

class BleWatchScannerDialog extends StatefulWidget {
  final BleWatchService? bleService;

  const BleWatchScannerDialog({super.key, this.bleService});

  static Future<void> show(BuildContext context, {BleWatchService? bleService}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BleWatchScannerDialog(bleService: bleService),
    );
  }

  @override
  State<BleWatchScannerDialog> createState() => _BleWatchScannerDialogState();
}

class _BleWatchScannerDialogState extends State<BleWatchScannerDialog>
    with SingleTickerProviderStateMixin {
  late final BleWatchService _ble;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _ble = widget.bleService ?? BleWatchService();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-start scan if not currently connected
    if (!_ble.isConnected) {
      _ble.startScan();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ValueListenableBuilder<WatchConnectionState>(
        valueListenable: _ble.connectionStateNotifier,
        builder: (context, state, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bluetooth_audio, color: Color(0xFF0284C7), size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smartwatch Live Connect',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Fire-Boltt • Apple Watch • BLE Bands',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // If Connected: Live Heart Rate Streaming View (like WhistleBox video)
                if (state == WatchConnectionState.connected) ...[
                  _buildLiveStreamingCard(),
                ] else if (state == WatchConnectionState.connecting) ...[
                  _buildConnectingState(),
                ] else ...[
                  _buildScanningList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveStreamingCard() {
    return ValueListenableBuilder<WatchTelemetryModel?>(
      valueListenable: _ble.telemetryNotifier,
      builder: (context, telemetry, _) {
        final bpm = telemetry?.heartRateBpm ?? 95;
        final watchName = telemetry?.name ?? 'Fire-Boltt Smartwatch';

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE11D48),
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$bpm',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF9F1239),
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BPM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFBE123C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live Streaming from $watchName',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bluetooth GATT 0x180D (Optical PPG Active)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF881337)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _ble.disconnect();
                      _ble.startScan();
                    },
                    icon: const Icon(Icons.bluetooth_disabled, size: 16),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Keep Streaming'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: const [
          CircularProgressIndicator(color: AppColors.primaryTeal),
          SizedBox(height: 16),
          Text(
            'Pairing & Handshaking BLE GATT...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Subscribing to Heart Rate Service 0x180D',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Discovered Smartwatches',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _ble.isScanningNotifier,
              builder: (context, scanning, _) {
                if (scanning) {
                  return Row(
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                      ),
                      SizedBox(width: 6),
                      Text('Scanning...', style: TextStyle(fontSize: 11, color: AppColors.primaryTeal)),
                    ],
                  );
                }
                return TextButton.icon(
                  onPressed: () => _ble.startScan(),
                  icon: const Icon(Icons.refresh, size: 14),
                  label: const Text('Scan Again', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Scanned Device Results
        ValueListenableBuilder<List<ScanResult>>(
          valueListenable: _ble.scanResultsNotifier,
          builder: (context, results, _) {
            if (results.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.watch_outlined, size: 40, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 8),
                    const Text(
                      'Searching for your Smartwatch...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ensure watch Bluetooth is ON and swipe to the Heart Rate screen on your watch.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => _ble.startLiveSimulation(),
                      icon: const Icon(Icons.play_circle_outline, size: 16),
                      label: const Text('Test Live Stream (Demo / Emulator)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: results.map((result) {
                final device = result.device;
                final name = device.platformName.isNotEmpty ? device.platformName : 'BLE Health Watch';
                final isFireBoltt = name.toLowerCase().contains('fire') ||
                    name.toLowerCase().contains('boltt') ||
                    name.toLowerCase().contains('watch') ||
                    name.toLowerCase().contains('invincible');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFireBoltt ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFireBoltt ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFireBoltt ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.watch_rounded,
                          color: isFireBoltt ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'RSSI: ${result.rssi} dBm • ${device.remoteId.str}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _ble.connect(device),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFireBoltt ? const Color(0xFF15803D) : AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: const [
              Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tip: Wear your watch and open the Heart Rate screen so the green sensor starts pulse reading.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
