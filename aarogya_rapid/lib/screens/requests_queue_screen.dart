import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../theme/app_theme.dart';
import '../core/storage/token_storage.dart';
import '../services/ambulance_dispatch_service.dart';

class RequestsQueueScreen extends StatefulWidget {
  final List<EmergencyRequest> requests;
  final EmergencyRequest? activeTrip;
  final Function(EmergencyRequest) onAcceptDispatch;
  final VoidCallback onOpenTrip;

  const RequestsQueueScreen({
    super.key,
    this.requests = const [],
    this.activeTrip,
    required this.onAcceptDispatch,
    required this.onOpenTrip,
  });

  @override
  State<RequestsQueueScreen> createState() => _RequestsQueueScreenState();
}

class _RequestsQueueScreenState extends State<RequestsQueueScreen>
    with SingleTickerProviderStateMixin {
  bool isOnDuty = true;
  String _driverName = 'Ambulance Lead Pilot';
  String _vehiclePlate = 'DL-01-AMB-108';
  String _verificationStatus = 'VERIFIED';
  String _role = 'AMBULANCE_DRIVER';
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _loadDriverMetadata();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverMetadata() async {
    try {
      final profile = await AmbulanceDispatchService().getProfile();
      if (profile != null && mounted) {
        final user = profile['user'] as Map<String, dynamic>? ?? {};
        setState(() {
          _driverName = profile['fullName']?.toString() ?? _driverName;
          _vehiclePlate = profile['assignedVehicleNumber']?.toString() ?? _vehiclePlate;
          _verificationStatus = user['verificationStatus']?.toString() ?? _verificationStatus;
          _role = user['role']?.toString() ?? _role;
          if (_verificationStatus != 'VERIFIED') {
            isOnDuty = false;
          }
        });
        return;
      }
      final raw = await TokenStorage().getDriverInfo();
      if (raw != null && mounted) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final user = decoded['user'] as Map<String, dynamic>? ?? decoded;
        setState(() {
          _driverName = decoded['fullName']?.toString() ?? decoded['name']?.toString() ?? _driverName;
          _vehiclePlate = decoded['assignedVehicleNumber']?.toString() ?? _vehiclePlate;
          _verificationStatus = user['verificationStatus']?.toString() ?? _verificationStatus;
          _role = user['role']?.toString() ?? _role;
          if (_verificationStatus != 'VERIFIED') {
            isOnDuty = false;
          }
        });
      }
    } catch (_) {}
  }

  void _showManualIntakeDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final emergencyController = TextEditingController();
    final phoneController = TextEditingController();
    bool isCritical = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log Emergency Dispatch Intake', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Patient Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Incident Location / Address *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Ring Road, Indiranagar',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Emergency Complaint / Trauma *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: emergencyController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Acute severe chest pain, shortness of breath',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Caller / Emergency Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+91 98765-43210',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: isCritical,
                      activeColor: SanctuaryColors.emergencyRed,
                      onChanged: (val) => setModalState(() => isCritical = val ?? true),
                    ),
                    const Expanded(
                      child: Text('Tier 1 Critical Emergency (ALS Strobe Active)', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCritical ? SanctuaryColors.emergencyRed : SanctuaryColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty ||
                    emergencyController.text.trim().isEmpty) {
                  return;
                }
                final req = EmergencyRequest.manualIntake(
                  patientName: nameController.text.trim(),
                  pickupAddress: addressController.text.trim(),
                  reportedEmergency: emergencyController.text.trim(),
                  patientPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
                  isCritical: isCritical,
                );
                Navigator.pop(ctx);
                widget.onAcceptDispatch(req);
              },
              child: const Text('Dispatch Ambulance Unit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTrip = widget.activeTrip;
    final requests = widget.requests;

    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadDriverMetadata();
        },
        color: SanctuaryColors.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Super Admin Verification Pending Banner
              if (_verificationStatus != 'VERIFIED') ...[
                _buildVerificationPendingBanner(),
                const SizedBox(height: 12),
              ],

              // 1. Ambulance Unit Telemetry & Duty Card
              _buildUnitStatusCard(),
              const SizedBox(height: 12),

              // 2. Verified Dispatch Safety Network
              _buildDispatchSafetyBanner(),
              const SizedBox(height: 16),

              // 3. Active Dispatch Banner if en route
              if (activeTrip != null) ...[
                _buildActiveDispatchBanner(activeTrip),
                const SizedBox(height: 16),
              ],

              // 4. Section Header: Emergency Requests Queue
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: requests.isNotEmpty ? SanctuaryColors.emergencyRed : SanctuaryColors.primaryTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live Emergency Dispatch Queue',
                      style: SanctuaryTypography.headlineMd(color: SanctuaryColors.deepSlateNavy).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: requests.isNotEmpty ? SanctuaryColors.crimsonRose : SanctuaryColors.optimalGreen,
                      borderRadius: SanctuaryRadius.rFull,
                      boxShadow: requests.isNotEmpty
                          ? [
                              BoxShadow(
                                color: SanctuaryColors.crimsonRose.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (requests.isNotEmpty)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        Text(
                          requests.isNotEmpty ? '${requests.length} LIVE SOS' : 'STANDBY READY',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Emergency Requests List OR Sleek Standby Radar
              if (requests.isEmpty) ...[
                _buildStandbyRadarCard(),
              ] else ...[
                ...requests.map((req) => _buildEmergencyCard(req)),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: SanctuaryColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFF9F1239)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SanctuaryColors.crimsonRose.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.emergency,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Aarogya Rapid EMS',
                      style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Central Emergency Dispatch Terminal',
                  style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 16),
          child: Tooltip(
            message: 'Connected to Aarogya Real-Time Socket Gateway',
            child: Icon(Icons.cloud_done_rounded, color: SanctuaryColors.optimalGreen, size: 22),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: SanctuaryColors.hairlineBorder),
      ),
    );
  }

  Widget _buildUnitStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOnDuty ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.airport_shuttle,
              color: isOnDuty ? const Color(0xFF2563EB) : SanctuaryColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _vehiclePlate,
                      style: SanctuaryTypography.labelMd(color: SanctuaryColors.deepSlateNavy).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _verificationStatus == 'VERIFIED'
                            ? SanctuaryColors.optimalGreenBg
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _verificationStatus == 'VERIFIED' ? 'ALS Unit • Verified' : 'Pending Super Admin',
                        style: TextStyle(
                          color: _verificationStatus == 'VERIFIED'
                              ? SanctuaryColors.optimalGreen
                              : const Color(0xFFB45309),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _verificationStatus != 'VERIFIED'
                      ? 'Pilot: $_driverName • Credentials Pending Review'
                      : 'Pilot: $_driverName • ${isOnDuty ? "Active Duty • Standby" : "Off Duty"}',
                  style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isOnDuty,
              activeThumbColor: Colors.white,
              activeTrackColor: SanctuaryColors.optimalGreen,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade400,
              onChanged: (val) {
                if (_verificationStatus != 'VERIFIED') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot go On Duty: Super Admin verification required.'),
                      backgroundColor: Color(0xFFD97706),
                    ),
                  );
                  return;
                }
                setState(() => isOnDuty = val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchSafetyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: const [
          Icon(Icons.verified_user_outlined, color: SanctuaryColors.optimalGreen, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Real-Time Telemetry & Trauma Bay Radio: Online & Encrypted',
              style: TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDispatchBanner(EmergencyRequest req) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
        ),
        borderRadius: SanctuaryRadius.rLg,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACTIVE TRANSIT IN PROGRESS',
                  style: TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  req.patientName,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  req.pickupAddress,
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3A8A),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onOpenTrip,
            child: const Text('Open Navigation', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildStandbyRadarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72 + (_radarController.value * 28),
                    height: 72 + (_radarController.value * 28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SanctuaryColors.primaryTeal.withValues(alpha: 0.15 * (1 - _radarController.value)),
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.radar_rounded,
                      size: 32,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Unit Stationed on Active Standby',
            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Ambulance $_vehiclePlate is broadcasting live GPS telemetry. When a patient triggers Emergency SOS, dispatch requests appear here with live smartwatch vitals.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: SanctuaryColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: SanctuaryColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: _showManualIntakeDialog,
            icon: const Icon(Icons.add_alert_rounded, size: 18),
            label: const Text('Log Manual Emergency Intake', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(EmergencyRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(
          color: req.isCritical ? SanctuaryColors.crimsonRose.withValues(alpha: 0.4) : SanctuaryColors.hairlineBorder,
          width: req.isCritical ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: req.isCritical ? SanctuaryColors.crimsonRose.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Priority Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: req.isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: req.isCritical ? SanctuaryColors.crimsonRose : SanctuaryColors.optimalGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    req.isCritical ? 'CRITICAL TIER 1 • IMMEDIATE DISPATCH' : 'TIER 2 • URGENT EMERGENCY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: req.isCritical ? SanctuaryColors.crimsonRose : SanctuaryColors.optimalGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                  ),
                  child: Text(
                    req.distance,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: SanctuaryColors.deepSlateNavy),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Name & Demographics
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.patientName,
                            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${req.patientGender}, ${req.patientAge}y',
                                style: const TextStyle(fontSize: 11.5, color: SanctuaryColors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Blood: ${req.bloodGroup}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ),
                              if (req.allergyName != 'None' && req.allergyName != 'None reported')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'Allergy: ${req.allergyName}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('ETA', style: TextStyle(fontSize: 9, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                          Text(
                            req.eta,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Live Smartwatch Vitals HUD Row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                const Icon(Icons.watch_outlined, color: Color(0xFF38BDF8), size: 14),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    req.wearableDevice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'ECG: ${req.ecgObservation}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildVitalMetric(icon: Icons.favorite, label: 'HEART RATE', value: '${req.heartRate} bpm', color: const Color(0xFFF43F5E)),
                          Container(width: 1, height: 24, color: Colors.white12),
                          _buildVitalMetric(icon: Icons.air, label: 'SPO2', value: '${req.spo2}%', color: const Color(0xFF38BDF8)),
                          Container(width: 1, height: 24, color: Colors.white12),
                          _buildVitalMetric(icon: Icons.speed, label: 'BLOOD PRESSURE', value: req.bloodPressure, color: const Color(0xFFA78BFA)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Chief Complaint Banner
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_information_outlined, size: 16, color: SanctuaryColors.crimsonRose),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req.reportedEmergency,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SanctuaryColors.deepSlateNavy),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Location Pin
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: SanctuaryColors.primaryTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        req.pickupAddress,
                        style: const TextStyle(fontSize: 12, color: SanctuaryColors.textSecondary, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    req.pickupLandmark,
                    style: const TextStyle(fontSize: 11, color: SanctuaryColors.textMuted),
                  ),
                ),
                const SizedBox(height: 14),

                // Big Tactical Accept Dispatch Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _verificationStatus != 'VERIFIED'
                          ? Colors.grey.shade400
                          : (req.isCritical ? const Color(0xFFDC2626) : SanctuaryColors.primaryTeal),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _verificationStatus != 'VERIFIED'
                        ? _showVerificationRequiredDialog
                        : () => widget.onAcceptDispatch(req),
                    icon: Icon(
                      _verificationStatus != 'VERIFIED'
                          ? Icons.lock_outline_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _verificationStatus != 'VERIFIED'
                          ? 'VERIFICATION PENDING (SUPER ADMIN REQUIRED)'
                          : 'ACCEPT DISPATCH & ENGAGE UNIT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Super Admin Verification Required',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your driving license and EMS credentials must be verified and approved by the Super Admin before you can go on duty or accept live emergency dispatches.\n\nPlease wait for Super Admin approval or contact your fleet supervisor.',
          style: TextStyle(fontSize: 13, height: 1.45, color: SanctuaryColors.deepSlateNavy),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SanctuaryColors.primaryTeal),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPendingBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'AWAITING SUPER ADMIN VERIFICATION',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCD34D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(
                          color: Color(0xFF78350F),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your driving license & EMS credentials are submitted and pending compliance review by Super Admin. You will be activated automatically once approved.',
                  style: TextStyle(color: Color(0xFFB45309), fontSize: 11, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8.5, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
