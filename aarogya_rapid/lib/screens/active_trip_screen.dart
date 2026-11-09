import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_map_view.dart';

class ActiveTripScreen extends StatefulWidget {
  final EmergencyRequest? request;
  final VoidCallback onOpenHandoverReport;
  final VoidCallback onBackToQueue;

  const ActiveTripScreen({
    super.key,
    this.request,
    required this.onOpenHandoverReport,
    required this.onBackToQueue,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  int currentStep = 2; // Step 2: En Route
  bool isStrobeLogged = true;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    if (req == null) {
      return Scaffold(
        backgroundColor: SanctuaryColors.surface,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.navigation_outlined,
                    size: 40,
                    color: SanctuaryColors.deepSlateNavy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Transit in Progress',
                  style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambulance unit is on standby. When you accept an emergency dispatch or log a transit, live en route tracking and clinical telemetry will activate here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: SanctuaryColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SanctuaryColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: widget.onBackToQueue,
                  icon: const Icon(Icons.emergency_outlined, size: 16),
                  label: const Text('View Emergency Queue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Trip Progress Stepper (Accepted -> En Route -> Arrived)
            _buildTripStepper(),
            const SizedBox(height: 12),

            // 2. Pickup Destination Card with ETA Banner
            _buildPickupDestinationCard(req),
            const SizedBox(height: 12),

            // 3. Simulated Live Navigation Map
            MiniNavigationMapView(
              height: 220,
              onExpand: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Toggling full navigation view overlay...')),
                );
              },
            ),
            const SizedBox(height: 12),

            // 4. Navigation Control Buttons
            _buildNavigationActions(),
            const SizedBox(height: 14),

            // 5. Patient Profile & Emergency Biometrics
            _buildPatientBiometricCard(req),
            const SizedBox(height: 12),

            // 6. Receiving Facility & Doctor
            _buildReceivingFacilityCard(req),
            const SizedBox(height: 16),

            // 7. Prominent Action Button: CONFIRM ARRIVED AT PICKUP LOCATION
            _buildArrivalConfirmationButton(),
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: SanctuaryColors.deepSlateNavy),
        onPressed: widget.onBackToQueue,
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aarogya Rapid',
            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.primary).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              Text(
                'TRIP #${widget.request?.id ?? "STANDBY"}',
                style: SanctuaryTypography.labelSm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10),
              ),
              const SizedBox(width: 6),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: SanctuaryColors.optimalGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'KA-03-HA-1102',
                style: SanctuaryTypography.labelSm(color: SanctuaryColors.textDark).copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // En Route Status Badge
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: SanctuaryColors.errorWash,
            borderRadius: SanctuaryRadius.rFull,
            border: Border.all(color: SanctuaryColors.errorBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SanctuaryColors.crimsonRose,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'EN ROUTE',
                style: TextStyle(
                  color: SanctuaryColors.crimsonRose,
                  fontWeight: FontWeight.w800,
                  fontSize: 10.5,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Emergency Call Action
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SanctuaryColors.surfaceInset,
              shape: BoxShape.circle,
              border: Border.all(color: SanctuaryColors.hairlineBorder),
            ),
            child: const Icon(Icons.phone_outlined, color: SanctuaryColors.deepSlateNavy, size: 18),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dialing Central Dispatch Command Line...')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: SanctuaryColors.hairlineBorder),
      ),
    );
  }

  Widget _buildTripStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Step 1: Accepted
          _buildStepItem(
            stepNumber: '1',
            icon: Icons.check,
            isCompleted: true,
            isActive: false,
            title: '1. Accepted',
            subtitle: '10:14 IST',
            color: SanctuaryColors.optimalGreen,
          ),
          _buildStepDivider(isCompleted: true),

          // Step 2: En Route
          _buildStepItem(
            stepNumber: '2',
            icon: Icons.emergency,
            isCompleted: false,
            isActive: true,
            title: '2. En Route',
            subtitle: 'ETA 5 mins',
            color: SanctuaryColors.crimsonRose,
          ),
          _buildStepDivider(isCompleted: false),

          // Step 3: Arrived
          _buildStepItem(
            stepNumber: '3',
            icon: null,
            isCompleted: false,
            isActive: false,
            title: 'Arrived',
            subtitle: 'Pickup Pt',
            color: SanctuaryColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNumber,
    required IconData? icon,
    required bool isCompleted,
    required bool isActive,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted
                ? SanctuaryColors.optimalGreen
                : isActive
                    ? SanctuaryColors.crimsonRose
                    : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive ? Colors.transparent : SanctuaryColors.hairlineBorder,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 15)
                : Text(
                    stepNumber,
                    style: TextStyle(
                      color: isCompleted || isActive ? Colors.white : SanctuaryColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isActive)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: const BoxDecoration(
                      color: SanctuaryColors.crimsonRose,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  title,
                  style: SanctuaryTypography.labelSm(
                    color: isActive ? SanctuaryColors.crimsonRose : SanctuaryColors.deepSlateNavy,
                  ).copyWith(fontSize: 11),
                ),
              ],
            ),
            Text(
              subtitle,
              style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isCompleted ? SanctuaryColors.optimalGreen : SanctuaryColors.hairlineBorder,
      ),
    );
  }

  Widget _buildPickupDestinationCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: SanctuaryColors.crimsonRose, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'PICKUP DESTINATION',
                      style: SanctuaryTypography.labelSm(color: SanctuaryColors.primaryTeal).copyWith(
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  req.pickupAddress,
                  style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  req.pickupLandmark,
                  style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),

          // ETA Banner Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE6F7F5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${req.distance} • Clear Route',
                  style: SanctuaryTypography.labelSm(color: SanctuaryColors.primaryDeepMarine).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '5 ',
                        style: SanctuaryTypography.metricDisplay(color: SanctuaryColors.primaryDark).copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: 'MINS',
                        style: SanctuaryTypography.labelSm(color: SanctuaryColors.primaryDark).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationActions() {
    return Column(
      children: [
        // Primary Button: Open Turn by Turn Navigation
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening High-Speed GPS Turn-by-Turn Navigation...')),
              );
            },
            icon: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 20),
            label: const Text(
              'Open Turn by Turn Navigation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00685F),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: SanctuaryRadius.rBase),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Secondary Button: Traffic Strobe Signal Logged
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                isStrobeLogged = !isStrobeLogged;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isStrobeLogged
                        ? 'Traffic Strobe Active: Signal pre-emption transmitting.'
                        : 'Traffic Strobe paused.',
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.sensors,
              color: isStrobeLogged ? SanctuaryColors.optimalGreen : SanctuaryColors.textSecondary,
              size: 18,
            ),
            label: Text(
              isStrobeLogged ? 'Traffic Strobe Signal Logged' : 'Traffic Strobe Standby',
              style: TextStyle(
                color: SanctuaryColors.deepSlateNavy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: SanctuaryColors.hairlineBorder),
              shape: RoundedRectangleBorder(borderRadius: SanctuaryRadius.rBase),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientBiometricCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Name, Age Chip & Allergy Alert
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          req.patientName,
                          style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${req.patientGender}, ${req.patientAge} yrs',
                            style: SanctuaryTypography.labelSm(color: SanctuaryColors.textSecondary).copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ABHA: ${req.abhaId}',
                      style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Penicillin Allergy Warning Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SanctuaryColors.errorWash,
                  borderRadius: SanctuaryRadius.rBase,
                  border: Border.all(color: SanctuaryColors.errorBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: SanctuaryColors.crimsonRose, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'PENICILLIN\nALLERGY',
                      style: SanctuaryTypography.labelSm(color: SanctuaryColors.crimsonRose).copyWith(
                        fontSize: 9.5,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reported Emergency Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: SanctuaryRadius.rBase,
              border: Border.all(color: SanctuaryColors.hairlineBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REPORTED EMERGENCY',
                  style: SanctuaryTypography.labelSm(color: SanctuaryColors.textMuted).copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  req.reportedEmergency,
                  style: SanctuaryTypography.bodyMd(color: SanctuaryColors.deepSlateNavy).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.medication_outlined, size: 13, color: SanctuaryColors.primaryTeal),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        req.emergencyDetails,
                        style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Live Wearable Telemetry Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.watch_outlined, size: 14, color: SanctuaryColors.primaryTeal),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE WEARABLE TELEMETRY',
                    style: SanctuaryTypography.labelSm(color: SanctuaryColors.primaryTeal).copyWith(
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: SanctuaryColors.optimalGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'boAt Wave Pro • Synced 2m ago',
                    style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Biometrics Cards (Heart Rate & SpO2)
          Row(
            children: [
              // Heart Rate Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: SanctuaryRadius.rBase,
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('HEART\nRATE', style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 9.5, height: 1.1, fontWeight: FontWeight.bold)),
                          Icon(Icons.favorite_outline, color: SanctuaryColors.crimsonRose, size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${req.heartRate} ',
                              style: SanctuaryTypography.metricDisplay(color: SanctuaryColors.deepSlateNavy).copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: 'BPM', style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: SanctuaryColors.warningAmberBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: SanctuaryColors.warningAmberBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.trending_up, color: SanctuaryColors.warningAmber, size: 12),
                            SizedBox(width: 3),
                            Text(
                              'Tachycardic',
                              style: TextStyle(color: SanctuaryColors.warningAmber, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Oxygen SpO2 Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: SanctuaryRadius.rBase,
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('OXYGEN\nSPO2', style: TextStyle(color: SanctuaryColors.textSecondary, fontSize: 9.5, height: 1.1, fontWeight: FontWeight.bold)),
                          Icon(Icons.air, color: SanctuaryColors.primaryTeal, size: 16),
                        ],
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${req.spo2} ',
                              style: SanctuaryTypography.metricDisplay(color: SanctuaryColors.deepSlateNavy).copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: '%', style: TextStyle(color: SanctuaryColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: SanctuaryColors.optimalGreenBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: SanctuaryColors.optimalGreenBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_outline, color: SanctuaryColors.optimalGreen, size: 12),
                            SizedBox(width: 3),
                            Text(
                              'Stable Room Air',
                              style: TextStyle(color: SanctuaryColors.optimalGreen, fontSize: 9.5, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }

  Widget _buildReceivingFacilityCard(EmergencyRequest req) {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RECEIVING FACILITY & DOCTOR',
            style: SanctuaryTypography.labelSm(color: SanctuaryColors.textMuted).copyWith(
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Hospital Box with Doctor Acknowledgement
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: SanctuaryRadius.rBase,
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF93C5FD)),
                      ),
                      child: const Icon(Icons.local_hospital, color: SanctuaryColors.primaryTeal, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.receivingHospital,
                            style: SanctuaryTypography.labelMd(color: SanctuaryColors.deepSlateNavy).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            req.hospitalBay,
                            style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 14, color: SanctuaryColors.primaryTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${req.assignedDoctor} (Acknowledged ${req.doctorAckTime})',
                        style: SanctuaryTypography.labelSm(color: SanctuaryColors.primaryDeepMarine).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Call ER Trauma & Call Caregiver (Priya)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connecting to Apollo ER Trauma Desk...')),
                      );
                    },
                    icon: const Icon(Icons.emergency_share, size: 15, color: SanctuaryColors.primaryTeal),
                    label: const Text(
                      'Call ER Trauma',
                      style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: SanctuaryColors.hairlineBorder),
                      shape: RoundedRectangleBorder(borderRadius: SanctuaryRadius.rBase),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling Caregiver Priya (+91 98480-22194)...')),
                      );
                    },
                    icon: const Icon(Icons.person_pin_circle_outlined, size: 15, color: SanctuaryColors.textSecondary),
                    label: const Text(
                      'Call Caregiver (Priya)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: SanctuaryColors.deepSlateNavy, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: SanctuaryColors.hairlineBorder),
                      shape: RoundedRectangleBorder(borderRadius: SanctuaryRadius.rBase),
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

  Widget _buildArrivalConfirmationButton() {
    return Container(
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
        boxShadow: SanctuaryColors.elevatedShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  currentStep = 3;
                });
                widget.onOpenHandoverReport();
              },
              icon: const Icon(Icons.check_box_outlined, color: Colors.white, size: 22),
              label: const Text(
                'CONFIRM: ARRIVED AT PICKUP LOCATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00685F),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: SanctuaryRadius.rBase),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Unlocks Paramedic Clinical Vitals & Handover Assessment Form',
            style: SanctuaryTypography.bodySm(color: SanctuaryColors.textMuted).copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
