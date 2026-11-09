import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/watch_telemetry_model.dart';
import '../../screens/log_glucose_dialog.dart';

class HomeVitalsSummary extends StatelessWidget {
  final String glucoseReading;
  final String glucoseSub;
  final bool hasLoggedGlucose;
  final Function(int mgDl, String type) onGlucoseLogged;
  final VoidCallback onNavigateToHealth;
  final WatchTelemetryModel? watchTelemetry;
  final WatchConnectionState? connectionState;
  final VoidCallback? onConnectWatch;

  const HomeVitalsSummary({
    super.key,
    required this.glucoseReading,
    required this.glucoseSub,
    required this.hasLoggedGlucose,
    required this.onGlucoseLogged,
    required this.onNavigateToHealth,
    this.watchTelemetry,
    this.connectionState,
    this.onConnectWatch,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveState = connectionState ??
        ((watchTelemetry?.paired ?? false) || (watchTelemetry?.isConnected ?? false)
            ? WatchConnectionState.connected
            : WatchConnectionState.notConnected);

    final isConnected = effectiveState == WatchConnectionState.connected &&
        ((watchTelemetry?.paired ?? false) || (watchTelemetry?.isConnected ?? false));
    final isBridgeUnavailable = effectiveState == WatchConnectionState.bridgeUnavailable;
    final isConnecting = effectiveState == WatchConnectionState.connecting;
    final isConnectionFailed = effectiveState == WatchConnectionState.connectionFailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.monitor_heart_outlined, color: AppColors.primaryTeal, size: 19),
                SizedBox(width: 6),
                Text(
                  'Health Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onNavigateToHealth,
              child: const Text(
                'View All Metrics',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: Blood Glucose (Interactive Manual Log)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
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
                      children: const [
                        Flexible(
                          child: Text(
                            'BLOOD GLUCOSE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.water_drop_outlined, color: AppColors.glucoseBlue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      glucoseReading,
                      style: TextStyle(
                        fontSize: hasLoggedGlucose ? 18 : 13,
                        fontWeight: hasLoggedGlucose ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      glucoseSub,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => LogGlucoseDialog(onLogged: onGlucoseLogged),
                        );
                      },
                      child: const Text(
                        '+ Log Reading >',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Wearable Sync Status (Adapts to all connection states)
            Expanded(
              child: GestureDetector(
                onTap: onNavigateToHealth,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected
                          ? AppColors.primaryTeal.withValues(alpha: 0.3)
                          : (isBridgeUnavailable
                              ? const Color(0xFFFECACA)
                              : AppColors.cardBorder),
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'WEARABLE SYNC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            isConnected
                                ? Icons.watch_outlined
                                : (isBridgeUnavailable ? Icons.cloud_off_rounded : Icons.watch_outlined),
                            color: isConnected
                                ? AppColors.primaryTeal
                                : (isBridgeUnavailable ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // State-specific device / title label
                      Text(
                        isConnected
                            ? watchTelemetry!.name
                            : (isBridgeUnavailable
                                ? 'Bridge Unavailable'
                                : (isConnecting
                                    ? 'Connecting...'
                                    : (isConnectionFailed
                                        ? 'Connection Failed'
                                        : 'Connect Your Watch'))),
                        style: TextStyle(
                          fontSize: isConnected ? 15 : 13.5,
                          fontWeight: FontWeight.w700,
                          color: isBridgeUnavailable ? const Color(0xFFDC2626) : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // State-specific verified telemetry or explanation
                      Text(
                        isConnected
                            ? (watchTelemetry!.batteryLevel != null
                                ? (watchTelemetry!.heartRateBpm != null && watchTelemetry!.heartRateBpm! > 0
                                    ? '${watchTelemetry!.batteryLevel}% • ${watchTelemetry!.heartRateBpm} BPM'
                                    : 'Battery ${watchTelemetry!.batteryLevel}% • Active')
                                : watchTelemetry!.connectionStatus)
                            : (isBridgeUnavailable
                                ? 'Laptop bridge or backend is unavailable'
                                : (isConnecting
                                    ? 'Connecting to watch bridge'
                                    : (isConnectionFailed
                                        ? 'Bluetooth sync failed'
                                        : 'Watch Not Connected'))),
                        style: TextStyle(
                          fontSize: 10,
                          color: isConnected
                              ? AppColors.primaryTeal
                              : (isBridgeUnavailable ? const Color(0xFF991B1B) : AppColors.textSecondary),
                          fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // State-specific primary button or link
                      if (isConnected)
                        const Text(
                          'Manage Watch >',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
                          ),
                        )
                      else if (isBridgeUnavailable)
                        const Text(
                          'Check Bridge >',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        )
                      else if (isConnecting)
                        const Text(
                          'Connecting...',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryTeal,
                          ),
                        )
                      else
                        SizedBox(
                          height: 26,
                          child: ElevatedButton(
                            onPressed: onConnectWatch ?? onNavigateToHealth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                              minimumSize: Size.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text(
                              'Connect',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
