import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/ambulance_dispatch_service.dart';
import '../core/storage/token_storage.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _dispatchService = AmbulanceDispatchService();
  final _tokenStorage = TokenStorage();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final liveProfile = await _dispatchService.getProfile();
    if (liveProfile != null && mounted) {
      setState(() {
        _profile = liveProfile;
        _isLoading = false;
      });
      return;
    }

    // Fallback to local secure storage
    final localStr = await _tokenStorage.getDriverInfo();
    if (localStr != null && mounted) {
      try {
        final decoded = jsonDecode(localStr) as Map<String, dynamic>;
        setState(() {
          _profile = decoded;
          _isLoading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _profile?['user'] as Map<String, dynamic>? ?? {};
    final fullName = _profile?['fullName']?.toString() ??
        _profile?['name']?.toString() ??
        'Ambulance Lead Pilot';
    final email = user['email']?.toString() ?? _profile?['email']?.toString() ?? 'driver@aarogya.ai';
    final phone = user['phone']?.toString() ?? _profile?['phone']?.toString() ?? '+91 98109-23812';
    final role = user['role']?.toString() ?? _profile?['staffRole']?.toString() ?? 'AMBULANCE_DRIVER';
    final vehicleNo = _profile?['assignedVehicleNumber']?.toString() ?? 'DL-01-AMB-108';
    final license = _profile?['licenseNumber']?.toString() ?? 'DL-EMS-2026-99';
    final cert = _profile?['certificationLevel']?.toString() ?? 'EMT-Advanced (ALS Certified)';
    final status = user['verificationStatus']?.toString() ?? 'VERIFIED';

    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      appBar: AppBar(
        backgroundColor: SanctuaryColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMS Staff Profile & Unit Terminal',
              style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              'Aarogya Central Emergency Logistics Gateway',
              style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: SanctuaryColors.hairlineBorder),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SanctuaryColors.primaryTeal))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: SanctuaryColors.primaryTeal,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // Driver Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SanctuaryColors.surfaceContainerLowest,
                      borderRadius: SanctuaryRadius.rLg,
                      border: Border.all(color: SanctuaryColors.hairlineBorder),
                      boxShadow: SanctuaryColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [SanctuaryColors.primaryTeal, SanctuaryColors.primaryDark],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'A',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
                                      fullName,
                                      style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: status == 'VERIFIED'
                                          ? SanctuaryColors.optimalGreenBg
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status == 'VERIFIED' ? 'VERIFIED' : 'PENDING APPROVAL',
                                      style: TextStyle(
                                        color: status == 'VERIFIED'
                                            ? SanctuaryColors.optimalGreen
                                            : const Color(0xFFB45309),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                role == 'PARAMEDIC'
                                    ? 'Lead Field Paramedic • Emergency Medicine'
                                    : 'Emergency Response Driver • Rapid Ambulance ALS',
                                style: const TextStyle(color: SanctuaryColors.textSecondary, fontSize: 11.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: const TextStyle(color: SanctuaryColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Unit & Equipment Telemetry Card
                  _buildSectionHeader('ASSIGNED AMBULANCE TELEMETRY'),
                  Container(
                    decoration: BoxDecoration(
                      color: SanctuaryColors.surfaceContainerLowest,
                      borderRadius: SanctuaryRadius.rLg,
                      border: Border.all(color: SanctuaryColors.hairlineBorder),
                      boxShadow: SanctuaryColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.airport_shuttle,
                          title: 'Assigned Vehicle Number',
                          value: vehicleNo,
                          isHighlight: true,
                        ),
                        const Divider(height: 1, color: SanctuaryColors.hairlineBorder),
                        _buildInfoTile(
                          icon: Icons.badge_outlined,
                          title: 'Driving / Paramedic License',
                          value: license,
                        ),
                        const Divider(height: 1, color: SanctuaryColors.hairlineBorder),
                        _buildInfoTile(
                          icon: Icons.medical_services_outlined,
                          title: 'Certification Level',
                          value: cert,
                        ),
                        const Divider(height: 1, color: SanctuaryColors.hairlineBorder),
                        _buildInfoTile(
                          icon: Icons.phone_android_outlined,
                          title: 'Registered Duty Phone',
                          value: phone,
                        ),
                        const Divider(height: 1, color: SanctuaryColors.hairlineBorder),
                        _buildInfoTile(
                          icon: Icons.shield_outlined,
                          title: 'Compliance Verification',
                          value: status == 'VERIFIED'
                              ? 'Verified & Approved (Active EMS Duty)'
                              : 'Pending Verification',
                          isHighlight: status != 'VERIFIED',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),



                  // Active EMS Readiness Card
                  _buildSectionHeader('EMERGENCY STANDBY STATUS'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: SanctuaryRadius.rLg,
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.radar, color: SanctuaryColors.optimalGreen, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Central Dispatch Radar Linked',
                                style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Unit is broadcasting live GPS telemetry. High-priority SOS dispatches are automatically routed here in real-time.',
                                style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 11, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SanctuaryColors.emergencyRed,
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out / Switch EMS Driver', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: SanctuaryTypography.labelSm(color: SanctuaryColors.textSecondary).copyWith(
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SanctuaryColors.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? SanctuaryColors.crimsonRose : SanctuaryColors.textSecondary,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
