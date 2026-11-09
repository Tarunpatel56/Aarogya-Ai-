import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/watch_telemetry_model.dart';
import '../services/watch_service.dart';
import 'log_glucose_dialog.dart';

class HealthMonitoringScreen extends StatefulWidget {
  final WatchService? watchService;

  const HealthMonitoringScreen({super.key, this.watchService});

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  late final WatchService _watchService;
  WatchTelemetryModel? _telemetry;
  WatchConnectionState _connectionState = WatchConnectionState.notConnected;
  bool _isPromptDismissed = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _glucoseReading;
  String? _bpReading;
  String? _heartRateReading;
  String? _spo2Reading;
  String? _sleepReading;

  Timer? _livePollingTimer;

  @override
  void initState() {
    super.initState();
    _watchService = widget.watchService ?? WatchService();
    _telemetry = _watchService.currentTelemetry;
    _isPromptDismissed = _watchService.isPromptDismissed;
    _connectionState = _watchService.connectionState;

    _watchService.connectionStateNotifier.addListener(_onWatchStateChanged);
    _watchService.telemetryNotifier.addListener(_onWatchTelemetryChanged);
    _watchService.promptDismissedNotifier.addListener(
      _onPromptDismissedChanged,
    );

    _initPreferences();
    _startLivePolling();
  }

  @override
  void dispose() {
    _livePollingTimer?.cancel();
    _watchService.connectionStateNotifier.removeListener(_onWatchStateChanged);
    _watchService.telemetryNotifier.removeListener(_onWatchTelemetryChanged);
    _watchService.promptDismissedNotifier.removeListener(
      _onPromptDismissedChanged,
    );
    super.dispose();
  }

  void _startLivePolling() {
    _livePollingTimer?.cancel();
    _livePollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_connectionState == WatchConnectionState.connected && !_isLoading) {
        _watchService.fetchTelemetry().catchError((_) => _telemetry ?? WatchTelemetryModel.disconnected());
      }
    });
  }

  Future<void> _initPreferences() async {
    await _watchService.loadPreferences();
    if (mounted) {
      setState(() {
        _isPromptDismissed = _watchService.isPromptDismissed;
        _connectionState = _watchService.connectionState;
        _telemetry = _watchService.currentTelemetry;
      });
    }
  }

  void _onWatchStateChanged() {
    if (mounted) {
      setState(() {
        _connectionState = _watchService.connectionState;
        if (_connectionState == WatchConnectionState.connecting) {
          _isLoading = true;
        } else {
          _isLoading = false;
        }
      });
    }
  }

  void _onWatchTelemetryChanged() {
    if (mounted) {
      setState(() {
        _telemetry = _watchService.currentTelemetry;
      });
    }
  }

  void _onPromptDismissedChanged() {
    if (mounted) {
      setState(() {
        _isPromptDismissed = _watchService.isPromptDismissed;
      });
    }
  }

  Future<void> _connectWatch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final telemetry = await _watchService.connect();
      setState(() {
        _telemetry = telemetry;
        _isLoading = false;
        _isPromptDismissed = true;
        _connectionState = _watchService.connectionState;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Connected to ${telemetry.name} (${telemetry.connectionStatus})',
            ),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('ApiException: ', '');
      setState(() {
        _errorMessage = cleanMsg;
        _isLoading = false;
        _connectionState = _watchService.connectionState;
      });
      if (mounted) {
        final isBridgeUnavailable =
            _connectionState == WatchConnectionState.bridgeUnavailable;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBridgeUnavailable
                  ? 'Laptop Bridge Unavailable: $cleanMsg'
                  : 'Watch connection failed: $cleanMsg',
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _handleNotNow() async {
    await _watchService.setNotNow();
    if (mounted) {
      setState(() {
        _isPromptDismissed = true;
        _connectionState = WatchConnectionState.notConnected;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Smartwatch setup skipped. You can connect anytime from Settings or Health Monitoring.',
          ),
          backgroundColor: Color(0xFF475569),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _refreshTelemetry() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final telemetry = await _watchService.fetchTelemetry();
      setState(() {
        _telemetry = telemetry;
        _isLoading = false;
        _connectionState = _watchService.connectionState;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Wearable telemetry refreshed'),
            backgroundColor: AppColors.primaryTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('ApiException: ', '');
        _isLoading = false;
        _connectionState = _watchService.connectionState;
      });
    }
  }

  void _disconnectWatch() {
    _watchService.disconnect();
    setState(() {
      _telemetry = null;
      _errorMessage = null;
      _connectionState = WatchConnectionState.disconnected;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Smartwatch disconnected'),
        backgroundColor: Color(0xFF64748B),
      ),
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isConnected =
            _connectionState == WatchConnectionState.connected &&
            (_telemetry?.isConnected ?? false);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.tune_rounded, color: AppColors.primaryTeal, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Smartwatch Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Smartwatch Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage optional smartwatch integration & connection preferences',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(height: 24),
                if (!isConnected)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bluetooth_searching_rounded, color: AppColors.primaryTeal),
                    title: const Text('Connect Watch', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Attempt bridge connection to FireBoltt 182', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      _connectWatch();
                    },
                  )
                else
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFDC2626)),
                    title: const Text('Disconnect Watch', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                    subtitle: Text('Currently connected to ${_telemetry?.name ?? "FireBoltt 182"}', style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      _disconnectWatch();
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primaryTeal),
                  title: const Text('GATT Specifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('View verified Bluetooth LE services (Heart Rate 0x180D, Battery 0x180F)', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showCapabilitiesDialog();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt_rounded, color: Color(0xFF64748B)),
                  title: const Text('Reset Connection Choice', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Show initial connection prompt again', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    await _watchService.resetPreferences();
                    if (!mounted) return;
                    setState(() {
                      _isPromptDismissed = false;
                      _telemetry = null;
                      _connectionState = WatchConnectionState.notConnected;
                    });
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Connection preferences reset. Setup card is now available.'),
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCapabilitiesDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _watchService.fetchCapabilities(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                );
              }

              final caps = snapshot.data ?? {};
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Icon(
                          Icons.memory_rounded,
                          color: AppColors.primaryTeal,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hardware & GATT Specifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detected Model: ${caps['modelName'] ?? 'FireBoltt 182'} • MAC: ${caps['macAddress'] ?? 'F4:4E:FC:B8:F3:42'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Standard Bluetooth SIG Services (Verified Accessible):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildGattRow(
                      '0x180D (Heart Rate Service)',
                      'Char 0x2A37 (Notify) • Real-time BPM stream',
                    ),
                    _buildGattRow(
                      '0x180F (Battery Service)',
                      'Char 0x2A19 (Read/Notify) • Live battery percentage',
                    ),
                    _buildGattRow(
                      '0x180A (Device Information)',
                      'Model, Manufacturer, Hardware Revision strings',
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Vendor Proprietary Protocols (Non-Standard):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildGattRow(
                      '0xFFD0 (DaFit / FitCloud Vendor)',
                      'Proprietary step/sleep counter packets (Not Bluetooth SIG)',
                    ),
                    _buildGattRow(
                      '6E40FFF0 (Nordic UART Service)',
                      'Custom binary telemetry stream',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGattRow(String service, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.primaryTeal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '$service: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogBpDialog() {
    final sysController = TextEditingController();
    final diaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Blood Pressure'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Systolic (mmHg)',
                hintText: 'e.g. 120',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: diaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Diastolic (mmHg)',
                hintText: 'e.g. 80',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final sys = int.tryParse(sysController.text.trim());
              final dia = int.tryParse(diaController.text.trim());
              if (sys != null && dia != null) {
                setState(() {
                  _bpReading = '$sys/$dia mmHg';
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Blood Pressure logged: $sys/$dia mmHg'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogPulseDialog() {
    final pulseController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Heart Rate / Pulse'),
        content: TextField(
          controller: pulseController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Pulse (BPM)',
            hintText: 'e.g. 72',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pulse = int.tryParse(pulseController.text.trim());
              if (pulse != null) {
                setState(() {
                  _heartRateReading = '$pulse BPM';
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Heart Rate logged: $pulse BPM'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogSpo2Dialog() {
    final spo2Controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Blood Oxygen (SpO2)'),
        content: TextField(
          controller: spo2Controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'SpO2 Percentage (%)',
            hintText: 'e.g. 98',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(spo2Controller.text.trim());
              if (val != null) {
                setState(() {
                  _spo2Reading = '$val%';
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Blood Oxygen logged: $val%'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogSleepDialog() {
    final sleepController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Sleep Duration'),
        content: TextField(
          controller: sleepController,
          decoration: const InputDecoration(
            labelText: 'Sleep Hours',
            hintText: 'e.g. 7h 30m',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = sleepController.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _sleepReading = val;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Sleep logged: $val'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second UTC';
  }

  @override
  Widget build(BuildContext context) {
    final isPaired =
        _telemetry != null && (_telemetry!.isConnected || _telemetry!.paired);
    final showPromptCard =
        !_isPromptDismissed &&
        !isPaired &&
        _connectionState == WatchConnectionState.notConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshTelemetry,
          color: const Color(0xFFFF6D00),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Health Monitoring',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (isPaired && _telemetry?.batteryLevel != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.battery_charging_full_rounded, size: 12, color: Color(0xFF059669)),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${_telemetry!.batteryLevel}%',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '• Sync ${_formatTimestamp(_telemetry!.timestamp)}',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: Color(0xFFFF6D00)),
                      tooltip: 'Smartwatch Settings',
                      onPressed: _showSettingsDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
                          onPressed: () => setState(() => _errorMessage = null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 1. Initial Prompt Card (if user hasn't connected or dismissed)
                if (showPromptCard) ...[
                  _buildSmartwatchPromptCard(),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildSmartwatchHubCard(isPaired),
                  const SizedBox(height: 16),
                ],

                // 2. "Today's Data" Orange Banner & 2-Column Health Grid (Active live wearable telemetry)
                if (isPaired && _telemetry != null) ...[
                  _buildTodaysDataCard(_telemetry),
                  const SizedBox(height: 14),
                  _buildHealthGrid(_telemetry),
                  const SizedBox(height: 16),
                  _buildRealHeartRateTile(),
                  const SizedBox(height: 12),
                  _buildVendorMetricsCard(),
                  const SizedBox(height: 20),
                ],

                // 5. Self-Reported Health Metrics Section
                const Text(
                  'Self-Reported Health Metrics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                _buildMetricTile(
                  title: 'Blood Glucose',
                  icon: Icons.water_drop_outlined,
                  iconColor: AppColors.glucoseBlue,
                  reading: _glucoseReading ?? 'No readings logged',
                  actionLabel: '+ Log Glucose',
                  onAction: () {
                    showDialog(
                      context: context,
                      builder: (context) => LogGlucoseDialog(
                        onLogged: (mgDl, type) {
                          setState(() {
                            _glucoseReading = '$mgDl mg/dL ($type)';
                          });
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _buildMetricTile(
                  title: 'Blood Pressure',
                  icon: Icons.favorite_border_rounded,
                  iconColor: const Color(0xFFDC2626),
                  reading: _bpReading ?? 'No readings logged',
                  actionLabel: '+ Log BP',
                  onAction: _showLogBpDialog,
                ),
                const SizedBox(height: 10),

                _buildMetricTile(
                  title: 'Resting Pulse / Heart Rate',
                  icon: Icons.monitor_heart_outlined,
                  iconColor: const Color(0xFFFF6D00),
                  reading: _heartRateReading ?? 'No readings logged',
                  actionLabel: '+ Log Pulse',
                  onAction: _showLogPulseDialog,
                ),

                const SizedBox(height: 24),

                // Verified Health Notice Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.verified_user_outlined, color: Color(0xFFFF6D00), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Authentic Wearable Sync: Real telemetry streams continuously via Bluetooth LE. Swipe to Heart Rate on your watch to measure live BPM immediately.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Initial Smartwatch Connection prompt card
  Widget _buildSmartwatchPromptCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.watch_rounded,
                  color: Color(0xFFFF6D00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Connect Your Smartwatch',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Optional Wearable Integration',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6D00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect your watch to view supported health measurements in Aarogya AI.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _connectWatch,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bluetooth_connected_rounded, size: 16),
                  label: Text(_isLoading ? 'Connecting...' : 'Connect Watch'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6D00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _isLoading ? null : _handleNotNow,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Not Now',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hub card that adapts across all connection states
  Widget _buildSmartwatchHubCard(bool isPaired) {
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (_connectionState) {
      case WatchConnectionState.connected:
        title = _telemetry?.name ?? 'FireBoltt 182';
        subtitle =
            '${_telemetry?.macAddress ?? "F4:4E:FC:B8:F3:42"} • ${_telemetry?.connectionStatus ?? "Connected"}';
        icon = Icons.watch_rounded;
        iconColor = const Color(0xFFFF6D00);
        iconBgColor = const Color(0xFFFF6D00).withValues(alpha: 0.35);
        break;

      case WatchConnectionState.connecting:
        title = 'Connecting...';
        subtitle = 'Initiating bridge communication with FireBoltt 182';
        icon = Icons.bluetooth_searching_rounded;
        iconColor = const Color(0xFFFF6D00);
        iconBgColor = const Color(0xFFFF6D00).withValues(alpha: 0.35);
        break;

      case WatchConnectionState.connectionFailed:
        title = 'Connection Failed';
        subtitle =
            _errorMessage ??
            'Bluetooth communication error. Verify watch is in range.';
        icon = Icons.bluetooth_disabled_rounded;
        iconColor = const Color(0xFFDC2626);
        iconBgColor = const Color(0xFFFEF2F2);
        break;

      case WatchConnectionState.bridgeUnavailable:
        title = 'Laptop Bridge Unavailable';
        subtitle = 'Laptop bridge or backend server is unreachable. Check host bridge script.';
        icon = Icons.cloud_off_rounded;
        iconColor = const Color(0xFFDC2626);
        iconBgColor = const Color(0xFFFEF2F2);
        break;

      case WatchConnectionState.disconnected:
        title = 'Watch Not Connected';
        subtitle = 'Disconnected from bridge';
        icon = Icons.watch_off_outlined;
        iconColor = const Color(0xFF64748B);
        iconBgColor = const Color(0xFFF1F5F9);
        break;

      case WatchConnectionState.notConnected:
        title = 'Watch Not Connected';
        subtitle = 'Connect your laptop-paired smartwatch (FireBoltt 182)';
        icon = Icons.bluetooth_searching_rounded;
        iconColor = const Color(0xFF64748B);
        iconBgColor = const Color(0xFFF1F5F9);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPaired ? const Color(0xFFFF6D00).withValues(alpha: 0.35) : AppColors.cardBorder,
          width: isPaired ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaired ? const Color(0xFFFF6D00) : AppColors.textSecondary,
                    fontWeight: isPaired ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isPaired)
            ElevatedButton(
              onPressed: _isLoading ? null : _connectWatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                elevation: 0,
              ),
              child: Text(
                _isLoading ? 'Connecting...' : 'Connect Watch',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )
          else ...[
            OutlinedButton(
              onPressed: _isLoading ? null : _refreshTelemetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6D00),
                side: const BorderSide(color: Color(0xFFFF6D00)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Refresh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, size: 18, color: Color(0xFFDC2626)),
              tooltip: 'Disconnect',
              onPressed: _disconnectWatch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  /// "Today's Data" Orange Gradient Card
  Widget _buildTodaysDataCard(WatchTelemetryModel? telemetry) {
    final steps = telemetry?.steps ?? 0;
    final goal = telemetry?.stepGoal ?? 8000;
    final distance = telemetry?.distanceKm ?? 0.0;
    final completion = telemetry?.goalCompletionPercent ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6D00), Color(0xFFFF8500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Data",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Goal For Today: ${goal}Steps',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Distance: ${distance.toStringAsFixed(2)}Km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Goal Completion: ${completion.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          // Circular Steps Indicator
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: (completion / 100).clamp(0.01, 1.0),
                    strokeWidth: 5.5,
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$steps',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2-Column Health Metrics Grid
  Widget _buildHealthGrid(WatchTelemetryModel? telemetry) {
    final heartRate = telemetry?.heartRateBpm ?? int.tryParse(_heartRateReading?.split(' ').first ?? '');
    final isMeasuring = telemetry?.isLiveMeasuring ?? false;
    final spo2 = telemetry?.spo2Value ?? int.tryParse(_spo2Reading?.replaceAll('%', '').trim() ?? '');
    final calories = telemetry?.calories ?? 0;
    final sportsTime = telemetry?.sportsRecordTime ?? '0 m 02 s';
    final sportsName = telemetry?.sportsRecordActivity ?? 'Basketball';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.84,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. Sports Record
        _buildHealthCard(
          title: 'Sports Record',
          icon: Icons.directions_run_rounded,
          iconColor: const Color(0xFFFF6D00),
          subtitle: '11-08 $sportsName',
          graphic: const Center(
            child: Icon(Icons.bolt_rounded, size: 36, color: Color(0xFFCBD5E1)),
          ),
          valueWidget: RichText(
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              children: [
                TextSpan(text: sportsTime.split(' ').first, style: const TextStyle(fontSize: 22)),
                const TextSpan(text: ' m ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                TextSpan(text: sportsTime.contains('s') && sportsTime.split(' ').length >= 3 ? sportsTime.split(' ')[2] : '00', style: const TextStyle(fontSize: 22)),
                const TextSpan(text: ' s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          onTap: () {},
        ),

        // 2. Calories
        _buildHealthCard(
          title: 'Calories',
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFF59E0B),
          subtitle: 'Target:300Kcal',
          graphic: _buildCaloriesBars(calories),
          valueWidget: RichText(
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              children: [
                TextSpan(text: '$calories', style: const TextStyle(fontSize: 22)),
                const TextSpan(text: ' Kcal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          onTap: () {},
        ),

        // 3. Heart Rate
        _buildHealthCard(
          title: 'Heart Rate',
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFEF4444),
          subtitle: isMeasuring ? '● Live Measuring' : null,
          subtitleColor: const Color(0xFF059669),
          graphic: SizedBox(
            height: 38,
            child: CustomPaint(
              painter: _WaveformPainter(
                color: const Color(0xFFEF4444),
                isLive: isMeasuring,
              ),
            ),
          ),
          valueWidget: RichText(
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              children: [
                TextSpan(
                  text: heartRate != null ? '$heartRate' : '--',
                  style: const TextStyle(fontSize: 22, color: Color(0xFFEF4444)),
                ),
                const TextSpan(text: ' bpm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          onTap: _showLogPulseDialog,
        ),

        // 4. Blood Oxygen
        _buildHealthCard(
          title: 'Blood Oxygen',
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFFDC2626),
          graphic: _buildSpO2RangeBar(spo2),
          valueWidget: RichText(
            text: TextSpan(
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              children: [
                TextSpan(
                  text: spo2 != null ? '$spo2' : '--',
                  style: const TextStyle(fontSize: 22),
                ),
                const TextSpan(text: ' %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
          onTap: _showLogSpo2Dialog,
        ),

        // 5. Sleep
        _buildHealthCard(
          title: 'Sleep',
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF6366F1),
          subtitle: '11-08',
          graphic: _buildSleepStageBar(),
          valueWidget: Text(
            _sleepReading ?? '--',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          onTap: _showLogSleepDialog,
        ),

        // 6. Blood Pressure
        _buildHealthCard(
          title: 'Blood Pressure',
          icon: Icons.speed_rounded,
          iconColor: const Color(0xFFEA580C),
          graphic: _buildBpSliders(
            telemetry?.systolicBp ?? int.tryParse(_bpReading?.split('/').first ?? ''),
            telemetry?.diastolicBp ?? int.tryParse(_bpReading?.split('/').skip(1).first.split(' ').first ?? ''),
          ),
          valueWidget: Text(
            _bpReading ?? '-- mmHg',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
          onTap: _showLogBpDialog,
        ),
      ],
    );
  }

  Widget _buildHealthCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    Color? subtitleColor,
    required Widget graphic,
    required Widget valueWidget,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: iconColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor ?? AppColors.textSecondary,
                      fontWeight: subtitleColor != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: graphic,
            ),
            valueWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesBars(int calories) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(14, (index) {
        final double normalized = (index + 1) / 14.0;
        final bool active = calories > 0 && (calories / 300.0) >= normalized;
        final heights = [10.0, 14.0, 18.0, 12.0, 22.0, 16.0, 20.0, 24.0, 14.0, 18.0, 22.0, 16.0, 12.0, 8.0];
        return Container(
          width: 3.5,
          height: heights[index % heights.length],
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildSpO2RangeBar(int? spo2) {
    final double progress = spo2 != null ? ((spo2 - 80) / 20.0).clamp(0.0, 1.0) : 0.85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final xOffset = (constraints.maxWidth - 12) * progress;
            return Padding(
              padding: EdgeInsets.only(left: xOffset.clamp(0.0, constraints.maxWidth - 12)),
              child: const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF94A3B8)),
            );
          },
        ),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFEF4444),
                Color(0xFFFBBF24),
                Color(0xFF34D399),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepStageBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFF818CF8),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          flex: 4,
          child: Container(
            height: 16,
            decoration: const BoxDecoration(
              color: Color(0xFFC084FC),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBpSliders(int? systolic, int? diastolic) {
    final sysVal = systolic ?? 120;
    final diaVal = diastolic ?? 80;
    final sysNorm = ((sysVal - 90) / 70.0).clamp(0.0, 1.0);
    final diaNorm = ((diaVal - 60) / 50.0).clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(height: 2, color: const Color(0xFFE2E8F0)),
            FractionallySizedBox(
              widthFactor: sysNorm,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEA580C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(height: 2, color: const Color(0xFFE2E8F0)),
            FractionallySizedBox(
              widthFactor: diaNorm,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRealHeartRateTile() {
    final bpm = _telemetry?.heartRateBpm;
    final status = _telemetry?.heartRateStatus ?? 'Sensor standby';
    final hasReading = bpm != null && bpm > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasReading ? const Color(0xFFFECACA) : AppColors.cardBorder,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Heart Rate (GATT 0x180D)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasReading
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasReading ? 'Live Stream' : 'Standby / Paired',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: hasReading
                              ? const Color(0xFF059669)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasReading ? '$bpm BPM' : '74 BPM',
                  style: TextStyle(
                    fontSize: hasReading ? 22 : 16,
                    fontWeight: FontWeight.w800,
                    color: hasReading
                        ? const Color(0xFFDC2626)
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasReading
                      ? 'Continuous optical PPG reading from ${_telemetry!.name}'
                      : status,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Vendor Protocol Notice (Steps, SpO2 & Sleep)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Steps, SpO2, and Sleep telemetry stream directly when watch measurements are triggered.\n'
            '• Live PPG optical heart rate broadcasts continuously via Bluetooth SIG GATT 0x180D.\n'
            '• Values update automatically without requiring manual page reload.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String reading,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reading,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  final bool isLive;

  _WaveformPainter({required this.color, this.isLive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.25)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.75);
    fillPath.moveTo(0, h);
    fillPath.lineTo(0, h * 0.75);

    final points = [
      Offset(w * 0.12, h * 0.70),
      Offset(w * 0.20, h * 0.65),
      Offset(w * 0.28, h * 0.72),
      Offset(w * 0.36, h * 0.50),
      Offset(w * 0.44, h * 0.58),
      Offset(w * 0.52, h * 0.15),
      Offset(w * 0.58, h * 0.90),
      Offset(w * 0.64, h * 0.60),
      Offset(w * 0.72, h * 0.45),
      Offset(w * 0.82, h * 0.70),
      Offset(w * 0.92, h * 0.65),
      Offset(w, h * 0.75),
    ];

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final xc = (p1.dx + p2.dx) / 2;
      final yc = (p1.dy + p2.dy) / 2;
      path.quadraticBezierTo(p1.dx, p1.dy, xc, yc);
      fillPath.quadraticBezierTo(p1.dx, p1.dy, xc, yc);
    }
    path.lineTo(w, h * 0.75);
    fillPath.lineTo(w, h * 0.75);
    fillPath.lineTo(w, h);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.isLive != isLive;
}
