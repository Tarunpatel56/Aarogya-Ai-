import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/appointment_service.dart';
import '../services/notification_service.dart';
import '../services/watch_service.dart';
import '../models/patient_profile_model.dart';
import '../models/watch_telemetry_model.dart';
import 'appointments/appointments_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/abha_card_widget.dart';
import 'profile/family_health_screen.dart';
import 'profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService? authService;
  final PatientService? patientService;

  const ProfileScreen({
    super.key,
    this.authService,
    this.patientService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final PatientService _patientService;
  late final WatchService _watchService;
  PatientProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _patientService = widget.patientService ?? PatientService();
    _watchService = WatchService();
    _watchService.connectionStateNotifier.addListener(_onWatchStateChanged);
    _watchService.telemetryNotifier.addListener(_onWatchStateChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _watchService.connectionStateNotifier.removeListener(_onWatchStateChanged);
    _watchService.telemetryNotifier.removeListener(_onWatchStateChanged);
    super.dispose();
  }

  void _onWatchStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _patientService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profile = widget.authService?.currentProfile;
          _isLoading = false;
          if (_profile == null) {
            _errorMessage = 'Unable to load profile data';
          }
        });
      }
    }
  }

  void _showEditProfileDialog() async {
    if (_profile == null) return;

    final updated = await Navigator.push<PatientProfileModel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          initialProfile: _profile!,
          patientService: _patientService,
          authService: widget.authService,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _profile = updated);
    } else {
      _loadProfile();
    }
  }

  void _showManageDevicesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final liveConnected = _watchService.connectionState == WatchConnectionState.connected &&
              (_watchService.currentTelemetry?.isConnected ?? false);
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
                    Icon(Icons.watch_rounded, color: AppColors.primaryTeal, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Manage Devices',
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
                  'Configure your Bluetooth smart watch connection preferences.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    liveConnected ? Icons.watch_rounded : Icons.watch_off_outlined,
                    color: liveConnected ? AppColors.primaryTeal : const Color(0xFF64748B),
                  ),
                  title: Text(
                    liveConnected
                        ? (_watchService.currentTelemetry?.name ?? 'FireBoltt 182')
                        : 'Watch Not Connected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'State: ${_watchService.connectionState.label}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: liveConnected
                      ? ElevatedButton(
                          onPressed: () {
                            _watchService.disconnect();
                            setSheetState(() {});
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Smartwatch disconnected.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Disconnect'),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);
                            nav.pop();
                            try {
                              await _watchService.connect();
                              if (mounted) setState(() {});
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Connection failed: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Connect Watch'),
                        ),
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.restart_alt_rounded, color: Color(0xFF64748B)),
                  title: const Text('Reset Setup Preference', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Restore initial setup card in Health Monitoring', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    await _watchService.resetPreferences();
                    nav.pop();
                    if (mounted) {
                      setState(() {});
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Smartwatch preferences reset.'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
        },
      ),
    );
  }

  void _showServerHostDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    bool testing = false;
    String? statusMessage;
    bool isSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
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
                      Icon(Icons.cloud_sync_outlined, color: AppColors.primaryTeal, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Backend Server Host',
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
                    'Connects phone to local PC backend over Wi-Fi or USB.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 24),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://10.16.36.46:5000/api/v1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (statusMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSuccess ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                            size: 16,
                            color: isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusMessage!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: testing
                              ? null
                              : () async {
                                  setSheetState(() {
                                    testing = true;
                                    statusMessage = 'Probing candidate servers...';
                                    isSuccess = false;
                                  });
                                  final detected = await ApiConfig.autoDetectBaseUrl();
                                  setSheetState(() {
                                    testing = false;
                                    controller.text = detected;
                                    statusMessage = 'Connected: $detected';
                                    isSuccess = true;
                                  });
                                  setState(() {});
                                },
                          icon: const Icon(Icons.autorenew_rounded, size: 16),
                          label: const Text('Auto-Detect', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: testing
                              ? null
                              : () async {
                                  setSheetState(() {
                                    testing = true;
                                    statusMessage = 'Pinging host...';
                                    isSuccess = false;
                                  });
                                  final url = controller.text.trim();
                                  try {
                                    final healthUri = Uri.parse(url.replaceAll('/api/v1', '/health'));
                                    final res = await http.get(healthUri).timeout(const Duration(seconds: 3));
                                    if (res.statusCode == 200) {
                                      ApiConfig.setBaseUrl(url);
                                      setSheetState(() {
                                        testing = false;
                                        statusMessage = 'Server online! Status: 200 OK';
                                        isSuccess = true;
                                      });
                                      setState(() {});
                                    } else {
                                      setSheetState(() {
                                        testing = false;
                                        statusMessage = 'Server returned HTTP ${res.statusCode}';
                                        isSuccess = false;
                                      });
                                    }
                                  } catch (err) {
                                    setSheetState(() {
                                      testing = false;
                                      statusMessage = 'Connection failed: $err';
                                      isSuccess = false;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Save & Test', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to log out of your Aarogya account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService?.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _profile?.fullName ?? widget.authService?.currentUser?.email ?? 'Patient';
    final abhaId = _profile?.abhaId != null && _profile!.abhaId!.isNotEmpty
        ? 'ABHA: ${_profile!.abhaId}'
        : 'ABHA: Not Linked';
    final bloodGroup = _profile?.bloodGroup ?? 'Not Set';
    final emergencyName = _profile?.emergencyContactName ?? 'Primary Responder';
    final emergencyPhone = _profile?.emergencyContactPhone ?? 'Not Configured';

    final initials = patientName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Patient Profile',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ABHA Credentials & Emergency Protocol',
                                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primaryTeal),
                          tooltip: 'Edit Profile',
                          onPressed: _showEditProfileDialog,
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
                            const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)))),
                            TextButton(onPressed: _loadProfile, child: const Text('Retry')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Profile Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryTeal, width: 2),
                              color: AppColors.mintBg,
                            ),
                            child: Center(
                              child: Text(
                                initials.isNotEmpty ? initials : 'P',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        patientName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  abhaId,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    StatusBadge(
                                      label: 'Blood: $bloodGroup',
                                      backgroundColor: const Color(0xFFFFEBEE),
                                      textColor: const Color(0xFFC62828),
                                    ),
                                    if (_profile?.gender != null) ...[
                                      const SizedBox(width: 6),
                                      StatusBadge(
                                        label: _profile!.gender!,
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        textColor: const Color(0xFF475569),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Official ABHA Digital Health Identity Card
                    AbhaCardWidget(
                      profile: _profile ??
                          PatientProfileModel(
                            id: 'p1',
                            userId: 'u1',
                            fullName: patientName,
                            abhaId: abhaId,
                            bloodGroup: bloodGroup,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Management Cards
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentsScreen(
                                    appointmentService: AppointmentService(
                                      apiClient: widget.authService?.apiClient,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.calendar_month, color: AppColors.primaryTeal, size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'My Appointments',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationsScreen(
                                    notificationService: NotificationService(
                                      apiClient: widget.authService?.apiClient,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.notifications_outlined, color: AppColors.primaryTeal, size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Notifications',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Family Health Management Tile
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.family_restroom_rounded, color: AppColors.primaryTeal, size: 22),
                          title: const Text('Family Health Network', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          subtitle: const Text('Manage parents, children, dependent records & vitals', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FamilyHealthScreen(
                                  patientService: _patientService,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Emergency Contact
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SOS Emergency Protocol',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: const Text(
                            'Configure',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildContactItem(emergencyName, 'Primary Responder', emergencyPhone),
                    const SizedBox(height: 8),
                    _buildContactItem('Apollo Emergency GPS Desk', 'Hospital EMS Network', '1066 (24/7)'),

                    const SizedBox(height: 22),
                    const Text('Devices & Wearables', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),

                    // Smartwatch Management Tile
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: ListTile(
                          leading: Icon(
                            _watchService.connectionState == WatchConnectionState.connected
                                ? Icons.watch_rounded
                                : Icons.watch_off_outlined,
                            color: _watchService.connectionState == WatchConnectionState.connected
                                ? AppColors.primaryTeal
                                : const Color(0xFF64748B),
                          ),
                          title: Text(
                            _watchService.connectionState == WatchConnectionState.connected
                                ? 'Manage Devices (Connected)'
                                : 'Connect Smartwatch',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            _watchService.connectionState == WatchConnectionState.connected
                                ? '${_watchService.currentTelemetry?.name ?? "FireBoltt 182"} • Connected (${_watchService.currentTelemetry?.batteryLevel != null ? "${_watchService.currentTelemetry!.batteryLevel}%" : "Active"})'
                                : 'Watch Not Connected • Tap to manage or connect',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: _showManageDevicesDialog,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
                    const Text('Backend & Server Connectivity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),

                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primaryTeal),
                          title: const Text('Server Connection (LAN/Wi-Fi)', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            ApiConfig.baseUrl,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18),
                          onTap: _showServerHostDialog,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
                    const Text('Account & Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),

                    // Logout & Session Actions
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.exit_to_app, color: Color(0xFFDC2626)),
                              title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                              subtitle: const Text('Terminate current session on this device', style: TextStyle(fontSize: 11.5)),
                              trailing: const Icon(Icons.chevron_right, size: 18),
                              onTap: _handleLogout,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.power_settings_new, color: Color(0xFF991B1B)),
                              title: const Text('Log Out Everywhere', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF991B1B))),
                              subtitle: const Text('Revoke all refresh tokens and sessions', style: TextStyle(fontSize: 11.5)),
                              trailing: const Icon(Icons.chevron_right, size: 18),
                              onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Log Out Everywhere'),
                                  content: const Text('This will terminate all active sessions across all devices.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                                      child: const Text('Log Out All', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await widget.authService?.logoutAll();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildContactItem(String name, String relation, String phone) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.sosLightBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_in_talk_rounded, color: AppColors.sosRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(relation, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(phone, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryTeal)),
        ],
      ),
    );
  }
}
