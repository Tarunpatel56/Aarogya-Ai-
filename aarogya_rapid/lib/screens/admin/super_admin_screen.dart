import 'package:flutter/material.dart';
import '../../services/ambulance_dispatch_service.dart';
import '../../theme/app_theme.dart';

class SuperAdminScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final VoidCallback? onSwitchToDriverMode;

  const SuperAdminScreen({
    super.key,
    this.onLogout,
    this.onSwitchToDriverMode,
  });

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final _dispatchService = AmbulanceDispatchService();
  List<Map<String, dynamic>> _staffList = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // ALL, PENDING, VERIFIED, REJECTED
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    final statusParam = _selectedFilter == 'ALL' ? null : _selectedFilter;
    final list = await _dispatchService.getAdminDrivers(
      status: statusParam,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    if (mounted) {
      setState(() {
        _staffList = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateDriverVerification(
    String driverId,
    String status, {
    String? driverName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isApproval = status == 'VERIFIED';

    final success = await _dispatchService.verifyDriver(
      driverId,
      status: status,
      notes: isApproval
          ? 'Approved by Super Admin Command'
          : 'Credentials rejected by Super Admin',
    );

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor:
                isApproval ? const Color(0xFF15803D) : const Color(0xFFDC2626),
            content: Text(
              isApproval
                  ? '✓ ${driverName ?? "Driver"} approved and verified! Live duty enabled.'
                  : '✗ ${driverName ?? "Driver"} marked as $status.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        _fetchStaff();
      } else {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFDC2626),
            content: Text('Failed to update driver verification status.'),
          ),
        );
      }
    }
  }

  void _showRejectionDialog(String driverId, String driverName) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Driver Credentials: $driverName',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter reason for rejecting license or certification:',
              style: TextStyle(fontSize: 12, color: SanctuaryColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Invalid commercial badge / expired license',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateDriverVerification(driverId, 'REJECTED', driverName: driverName);
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int pendingCount = _staffList.where((s) {
      final user = s['user'] as Map<String, dynamic>? ?? {};
      return user['verificationStatus'] == 'PENDING';
    }).length;

    final int verifiedCount = _staffList.where((s) {
      final user = s['user'] as Map<String, dynamic>? ?? {};
      return user['verificationStatus'] == 'VERIFIED';
    }).length;

    return Scaffold(
      backgroundColor: SanctuaryColors.surface,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchStaff,
        color: SanctuaryColors.primaryTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // 1. Super Admin Authority Banner
            _buildSuperAdminNotice(),
            const SizedBox(height: 14),

            // 2. Metrics Summary Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'PENDING APPROVAL',
                    count: '$pendingCount',
                    subtitle: 'Awaiting Super Admin',
                    color: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFEF3C7),
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'VERIFIED UNITS',
                    count: '$verifiedCount',
                    subtitle: 'Active on Duty',
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFDCFCE7),
                    icon: Icons.verified_user_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricCard(
                    title: 'TOTAL FLEET',
                    count: '${_staffList.length}',
                    subtitle: 'Registered EMS',
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    icon: Icons.airport_shuttle_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Search Bar
            _buildSearchBar(),
            const SizedBox(height: 12),

            // 4. Status Filter Chips
            _buildFilterRow(pendingCount, verifiedCount),
            const SizedBox(height: 16),

            // 5. Section Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: SanctuaryColors.crimsonRose,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ambulance Drivers & Paramedics',
                  style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_staffList.length} Found',
                  style: const TextStyle(fontSize: 11.5, color: SanctuaryColors.textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Drivers List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: SanctuaryColors.primaryTeal),
                ),
              )
            else if (_staffList.isEmpty)
              _buildEmptyState()
            else
              ..._staffList.map((driver) => _buildDriverCard(driver)),

            const SizedBox(height: 32),
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
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFF881337)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Aarogya Super Admin',
                        overflow: TextOverflow.ellipsis,
                        style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Text(
                        'SUPER ADMIN',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Central Fleet Compliance & Driver Verification',
                  overflow: TextOverflow.ellipsis,
                  style: SanctuaryTypography.bodySm(color: SanctuaryColors.textSecondary).copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: SanctuaryColors.deepSlateNavy, size: 20),
          onPressed: _fetchStaff,
          tooltip: 'Refresh list',
        ),
        if (widget.onLogout != null)
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: SanctuaryColors.crimsonRose, size: 20),
            onPressed: widget.onLogout,
            tooltip: 'Sign Out Super Admin',
          ),
        const SizedBox(width: 6),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: SanctuaryColors.hairlineBorder),
      ),
    );
  }

  Widget _buildSuperAdminNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: SanctuaryRadius.rBase,
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strict Super Admin Verification Policy Active',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No ambulance driver or paramedic can accept emergency dispatches, broadcast live sirens, or enter on-duty standby without verified credentials approval by Super Admin.',
                  style: TextStyle(color: Color(0xFFB45309), fontSize: 10.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: color, size: 14),
              ),
              const Spacer(),
              Text(
                count,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: SanctuaryColors.textMuted, fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: SanctuaryColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SanctuaryRadius.rBase,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          _searchQuery = val.trim();
          _fetchStaff();
        },
        decoration: InputDecoration(
          hintText: 'Search driver by name, DL, vehicle plate...',
          hintStyle: const TextStyle(fontSize: 12, color: SanctuaryColors.textMuted),
          prefixIcon: const Icon(Icons.search, size: 18, color: SanctuaryColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    _fetchStaff();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterRow(int pendingCount, int verifiedCount) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('ALL', 'All Drivers'),
          const SizedBox(width: 6),
          _buildFilterChip('PENDING', 'Pending ($pendingCount)', isAlert: pendingCount > 0),
          const SizedBox(width: 6),
          _buildFilterChip('VERIFIED', 'Verified ($verifiedCount)'),
          const SizedBox(width: 6),
          _buildFilterChip('REJECTED', 'Rejected'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {bool isAlert = false}) {
    final bool isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = filterKey);
        _fetchStaff();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAlert ? const Color(0xFFDC2626) : SanctuaryColors.primaryTeal)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isAlert ? const Color(0xFFFCA5A5) : SanctuaryColors.hairlineBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : SanctuaryColors.deepSlateNavy,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final user = driver['user'] as Map<String, dynamic>? ?? {};
    final String status = user['verificationStatus']?.toString() ?? 'PENDING';
    final String fullName = driver['fullName']?.toString() ?? 'Ambulance Staff';
    final String vehicleNo = driver['assignedVehicleNumber']?.toString() ?? 'DL-01-AMB-108';
    final String license = driver['licenseNumber']?.toString() ?? 'Pending DL';
    final String cert = driver['certificationLevel']?.toString() ?? 'EMT-Advanced';
    final String phone = user['phone']?.toString() ?? 'No Phone';
    final String email = user['email']?.toString() ?? '';
    final String role = user['role']?.toString() ?? 'AMBULANCE_DRIVER';
    final bool isVerified = status == 'VERIFIED';
    final bool isPending = status == 'PENDING' || status == 'UNDER_REVIEW';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : SanctuaryColors.hairlineBorder,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Role & Verification Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: role == 'PARAMEDIC'
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: role == 'PARAMEDIC'
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFBBF7D0),
                    ),
                  ),
                  child: Text(
                    role == 'PARAMEDIC' ? 'ALS PARAMEDIC' : 'AMBULANCE DRIVER',
                    style: TextStyle(
                      color: role == 'PARAMEDIC'
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF15803D),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? SanctuaryColors.optimalGreenBg
                        : isPending
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isVerified
                          ? SanctuaryColors.optimalGreenBorder
                          : isPending
                              ? const Color(0xFFFCD34D)
                              : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified
                            : isPending
                                ? Icons.pending
                                : Icons.cancel,
                        size: 12,
                        color: isVerified
                            ? SanctuaryColors.optimalGreen
                            : isPending
                                ? const Color(0xFFD97706)
                                : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: isVerified
                              ? SanctuaryColors.optimalGreen
                              : isPending
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFFDC2626),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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
                // Driver Name & Contact
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [SanctuaryColors.primaryTeal, SanctuaryColors.primaryDark],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'D',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: SanctuaryTypography.headlineSm(color: SanctuaryColors.deepSlateNavy).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(color: SanctuaryColors.textSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Phone: $phone',
                            style: const TextStyle(color: SanctuaryColors.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Credentials Grid
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SanctuaryColors.hairlineBorder),
                  ),
                  child: Column(
                    children: [
                      _buildCredentialRow('Assigned Vehicle:', vehicleNo, Icons.airport_shuttle, isHighlight: true),
                      const SizedBox(height: 6),
                      _buildCredentialRow('Driving License:', license, Icons.badge_outlined),
                      const SizedBox(height: 6),
                      _buildCredentialRow('Certification:', cert, Icons.medical_services_outlined),
                      if (driver['verifiedBy'] != null) ...[
                        const SizedBox(height: 6),
                        _buildCredentialRow(
                          'Verified By:',
                          '${driver["verifiedBy"]} (Super Admin)',
                          Icons.verified_user_outlined,
                        ),
                      ],
                    ],
                  ),
                ),

                // Uploaded Compliance Documents Preview for Super Admin
                if (driver['documents'] is Map && (driver['documents'] as Map).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.folder_shared, size: 14, color: Color(0xFF0F172A)),
                            SizedBox(width: 4),
                            Text(
                              'Uploaded Compliance Documents (Super Admin Audit):',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: (driver['documents'] as Map).entries.map((entry) {
                            final docVal = entry.value is Map ? (entry.value as Map) : {};
                            final fileName = docVal['fileName']?.toString() ?? entry.key.toString();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf, size: 12, color: Color(0xFFE11D48)),
                                  const SizedBox(width: 4),
                                  Text(
                                    fileName,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Super Admin Action Buttons
                if (isPending) ...[
                  Row(
                    children: [
                      // Approve Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF15803D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _updateDriverVerification(
                              driver['id']?.toString() ?? '',
                              'VERIFIED',
                              driverName: fullName,
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text(
                              'APPROVE & VERIFY',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reject Button
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            foregroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _showRejectionDialog(
                            driver['id']?.toString() ?? '',
                            fullName,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text(
                            'REJECT',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (isVerified) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Verified & Authorized for Live Emergency Dispatch',
                          style: TextStyle(color: Color(0xFF166534), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _updateDriverVerification(
                          driver['id']?.toString() ?? '',
                          'UNDER_REVIEW',
                          driverName: fullName,
                        ),
                        child: const Text('Revoke / Review', style: TextStyle(color: Color(0xFFD97706), fontSize: 11)),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Driver Verification Rejected',
                          style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _updateDriverVerification(
                          driver['id']?.toString() ?? '',
                          'VERIFIED',
                          driverName: fullName,
                        ),
                        child: const Text('Re-Verify', style: TextStyle(color: Color(0xFF15803D), fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 13, color: SanctuaryColors.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: SanctuaryColors.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
              color: isHighlight ? SanctuaryColors.primaryTeal : SanctuaryColors.deepSlateNavy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: SanctuaryColors.surfaceContainerLowest,
        borderRadius: SanctuaryRadius.rLg,
        border: Border.all(color: SanctuaryColors.hairlineBorder),
      ),
      child: Column(
        children: const [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: SanctuaryColors.optimalGreen),
          SizedBox(height: 12),
          Text(
            'All Fleet Drivers Processed',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: SanctuaryColors.deepSlateNavy),
          ),
          SizedBox(height: 4),
          Text(
            'No registered drivers match the selected filter.',
            style: TextStyle(fontSize: 11.5, color: SanctuaryColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

