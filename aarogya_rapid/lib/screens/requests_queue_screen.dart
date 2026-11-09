import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../theme/app_theme.dart';

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

class _RequestsQueueScreenState extends State<RequestsQueueScreen> {
  bool isOnDuty = true;

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
          title: const Text('Log Emergency Dispatch Intake'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Patient Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'e.g. Ramesh Kumar', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Pickup Location / Incident Address *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(hintText: 'e.g. 100 Feet Rd, Indiranagar', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Reported Emergency / Clinical Chief Complaint *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: emergencyController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'e.g. Severe chest pain, dyspnea', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Contact Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'e.g. +91 98765-43210', border: OutlineInputBorder()),
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
                      child: Text('Tier 1 Critical Emergency (High Priority)', style: TextStyle(fontSize: 12.5)),
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
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty || addressController.text.trim().isEmpty || emergencyController.text.trim().isEmpty) {
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
              child: const Text('Dispatch Unit'),
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ambulance Unit Status & Duty Toggle Card
            _buildUnitStatusCard(),
            const SizedBox(height: 12),

            // 2. Dispatch Safety Mode Banner
            _buildDispatchSafetyBanner(),
            const SizedBox(height: 16),

            // 3. Active Dispatch Banner if en route
            if (activeTrip != null) ...[
              _buildActiveDispatchBanner(activeTrip),
              const SizedBox(height: 16),
            ],

            // 4. Section Title: Emergency Requests Queue
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Emergency Requests Queue',
                    style: SanctuaryTypography.headlineMd(color: SanctuaryColors.deepSlateNavy).copyWith(fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: requests.isNotEmpty ? SanctuaryColors.crimsonRose : SanctuaryColors.optimalGreen,
                    borderRadius: SanctuaryRadius.rFull,
                  ),
                  child: Text(
                    requests.isNotEmpty ? '${requests.length} Pending' : 'Queue Clear',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Emergency Requests or Clean Empty State
            if (requests.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                decoration: BoxDecoration(
                  color: SanctuaryColors.surfaceContainerLowest,
                  borderRadius: SanctuaryRadius.rLg,
                  border: Border.all(color: SanctuaryColors.hairlineBorder),
                  boxShadow: SanctuaryColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.airport_shuttle_outlined,
                        size: 40,
                        color: SanctuaryColors.deepSlateNavy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Active Emergency Dispatches',
                      style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ambulance Unit KA-01-EA-108 is currently stationed on standby. Live emergency SOS requests from patients or hospital dispatchers will be assigned here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: SanctuaryColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SanctuaryColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showManualIntakeDialog,
                      icon: const Icon(Icons.add_alert_rounded, size: 18),
                      label: const Text('Log Manual Emergency Intake', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...requests.map((req) => _buildEmergencyCard(req)),
            ],

            const SizedBox(height: 24),
          ],
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SanctuaryColors.errorWash,
              shape: BoxShape.circle,
              border: Border.all(color: SanctuaryColors.errorBorder),
            ),
            child: const Icon(
              Icons.emergency_outlined,
              color: SanctuaryColors.crimsonRose,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aarogya Rapid',
                  style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'EMS Unit Terminal • Bengaluru Central',
                  style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.cloud_done_outlined, color: SanctuaryColors.optimalGreen, size: 22),
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
        color: const Color(0xFFEFF3FE),
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: const Color(0xFFD6E0FA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFDAE2FD),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.airport_shuttle, color: SanctuaryColors.deepSlateNavy, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unit KA-01-EA-108 • EMS BLS/ALS',
                  style: SanctuaryTypography.labelMd(color: SanctuaryColors.deepSlateNavy).copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnDuty ? 'Status: Active Duty • Standby Ready' : 'Status: Off Duty',
                  style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
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
              onChanged: (val) => setState(() => isOnDuty = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchSafetyBanner() {
    return ClipRRect(
      borderRadius: SanctuaryRadius.rBase,
      child: Container(
        decoration: BoxDecoration(
          color: SanctuaryColors.surfaceContainerLowest,
          border: Border.all(color: SanctuaryColors.hairlineBorder),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3.5, color: SanctuaryColors.primaryTeal),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, color: SanctuaryColors.primaryTeal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Emergency Dispatch Network',
                              style: SanctuaryTypography.labelSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Direct hospital trauma bay coordination and encrypted patient telemetry active.',
                              style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDispatchBanner(EmergencyRequest req) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.navigation_rounded, color: Color(0xFF1D4ED8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Transit: ${req.patientName}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  req.pickupAddress,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: widget.onOpenTrip,
            child: const Text('Open Trip', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(EmergencyRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: req.isCritical ? SanctuaryColors.emergencyRed : SanctuaryColors.primaryTeal,
                  borderRadius: SanctuaryRadius.rFull,
                ),
                child: Text(
                  req.tier,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                req.triggeredAgo,
                style: const TextStyle(fontSize: 11, color: SanctuaryColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${req.patientName} (${req.patientGender}, ${req.patientAge}y)',
            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Chief Complaint: ${req.reportedEmergency}',
            style: const TextStyle(fontSize: 12, color: SanctuaryColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: SanctuaryColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req.pickupAddress,
                  style: const TextStyle(fontSize: 11.5, color: SanctuaryColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: req.isCritical ? SanctuaryColors.emergencyRed : SanctuaryColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => widget.onAcceptDispatch(req),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Accept Emergency Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
