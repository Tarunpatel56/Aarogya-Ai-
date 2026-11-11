import 'package:flutter/material.dart';
import '../../core/storage/token_storage.dart';
import '../../services/superadmin_service.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const SuperAdminDashboardScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  final SuperAdminService _adminService = SuperAdminService();
  final TokenStorage _tokenStorage = TokenStorage();

  int _currentIndex = 0;
  bool _isLoading = false;
  String _adminEmail = 'superadmin@aarogya.ai';

  // Stats
  Map<String, dynamic> _stats = {};

  // Doctors
  List<Map<String, dynamic>> _doctors = [];
  String _doctorStatusFilter = 'PENDING';
  final TextEditingController _doctorSearchController = TextEditingController();

  // Ambulance Staff
  List<Map<String, dynamic>> _ambulanceStaff = [];
  String _ambulanceStatusFilter = 'PENDING';
  final TextEditingController _ambulanceSearchController = TextEditingController();

  // Emergencies
  List<Map<String, dynamic>> _emergencies = [];

  // Patients
  List<Map<String, dynamic>> _patients = [];
  final TextEditingController _patientSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _refreshCurrentTab();
  }

  Future<void> _loadAdminInfo() async {
    final info = await _tokenStorage.getAdminInfo();
    if (info != null && info.isNotEmpty) {
      try {
        if (mounted) {
          setState(() {
            _adminEmail = 'Super Admin (${info.contains("email") ? "Online" : "Admin"})';
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _refreshCurrentTab() async {
    setState(() => _isLoading = true);
    try {
      if (_currentIndex == 0) {
        await _fetchStats();
      } else if (_currentIndex == 1) {
        await _fetchDoctors();
      } else if (_currentIndex == 2) {
        await _fetchAmbulanceStaff();
      } else if (_currentIndex == 3) {
        await _fetchEmergencies();
      } else if (_currentIndex == 4) {
        await _fetchPatients();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStats() async {
    final data = await _adminService.getPlatformStats();
    if (mounted) {
      setState(() => _stats = data);
    }
  }

  Future<void> _fetchDoctors() async {
    final doctors = await _adminService.getDoctors(
      verificationStatus: _doctorStatusFilter,
      search: _doctorSearchController.text,
    );
    if (mounted) {
      setState(() => _doctors = doctors);
    }
  }

  Future<void> _fetchAmbulanceStaff() async {
    final staff = await _adminService.getAmbulanceStaff(
      status: _ambulanceStatusFilter,
      search: _ambulanceSearchController.text,
    );
    if (mounted) {
      setState(() => _ambulanceStaff = staff);
    }
  }

  Future<void> _fetchEmergencies() async {
    final list = await _adminService.getActiveEmergencies();
    if (mounted) {
      setState(() => _emergencies = list);
    }
  }

  Future<void> _fetchPatients() async {
    final list = await _adminService.getPatients(
      search: _patientSearchController.text,
    );
    if (mounted) {
      setState(() => _patients = list);
    }
  }

  // Doctor Action
  Future<void> _handleDoctorVerification(String doctorId, String doctorName, String status) async {
    final isApprove = status == 'VERIFIED';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Approve Doctor?' : 'Reject Doctor?'),
        content: Text(
          isApprove
              ? 'Doctor $doctorName will be approved and immediately become visible to patients on the Aarogya App.'
              : 'Doctor $doctorName will be marked as REJECTED and cannot access clinical features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isApprove ? 'Confirm Approval' : 'Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _adminService.verifyDoctor(doctorId, status: status);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Doctor $doctorName successfully ${isApprove ? "approved & verified" : "rejected"}'
                : 'Failed to update doctor verification status',
          ),
          backgroundColor: success ? (isApprove ? Colors.green : Colors.orange) : Colors.red,
        ),
      );
      _fetchDoctors();
    }
  }

  // Ambulance Action
  Future<void> _handleAmbulanceVerification(String staffId, String staffName, String status) async {
    final isApprove = status == 'VERIFIED';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Approve Ambulance Pilot?' : 'Reject Ambulance Pilot?'),
        content: Text(
          isApprove
              ? 'Pilot $staffName will be verified and granted live EMS emergency dispatch access on Aarogya Rapid.'
              : 'Pilot $staffName will be marked as REJECTED and cannot accept emergency trips.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isApprove ? 'Confirm Approval' : 'Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _adminService.verifyAmbulanceStaff(staffId, status: status);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Ambulance Staff $staffName successfully ${isApprove ? "approved & verified" : "rejected"}'
                : 'Failed to update ambulance verification status',
          ),
          backgroundColor: success ? (isApprove ? Colors.green : Colors.orange) : Colors.red,
        ),
      );
      _fetchAmbulanceStaff();
    }
  }

  Future<void> _handleDeleteUser(String userId, String userName, String userType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Delete Account ID?', style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete $userName\'s ($userType) ID? This will remove their record from the database and revoke all platform access.',
          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Delete ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final success = await _adminService.deleteUser(userId);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Account ID for $userName was deleted permanently.'
                : 'Failed to delete account. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      _refreshCurrentTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aarogya Super Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _adminEmail,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Current Screen',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshCurrentTab,
          ),
          IconButton(
            tooltip: 'Logout Super Admin',
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            onPressed: () async {
              await _adminService.logout();
              widget.onLogout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _buildCurrentTab(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFFEF4444).withValues(alpha: 0.25),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _refreshCurrentTab();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Color(0xFF94A3B8)),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFEF4444)),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined, color: Color(0xFF94A3B8)),
            selectedIcon: Icon(Icons.medical_services, color: Color(0xFFEF4444)),
            label: 'Dr. Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.emergency_outlined, color: Color(0xFF94A3B8)),
            selectedIcon: Icon(Icons.emergency, color: Color(0xFFEF4444)),
            label: 'EMS Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined, color: Color(0xFF94A3B8)),
            selectedIcon: Icon(Icons.radar, color: Color(0xFFEF4444)),
            label: 'Live SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined, color: Color(0xFF94A3B8)),
            selectedIcon: Icon(Icons.people, color: Color(0xFFEF4444)),
            label: 'Patients',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildDoctorsTab();
      case 2:
        return _buildAmbulanceTab();
      case 3:
        return _buildLiveSOSTab();
      case 4:
        return _buildPatientsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // TAB 0: OVERVIEW
  Widget _buildOverviewTab() {
    final users = _stats['users'] as Map<String, dynamic>? ?? {};
    final byRole = users['byRole'] as Map<String, dynamic>? ?? {};
    final operations = _stats['operations'] as Map<String, dynamic>? ?? {};

    final totalUsers = users['total'] ?? 0;
    final pendingApprovals = users['pendingVerification'] ?? 0;
    final patientCount = byRole['PATIENT'] ?? 0;
    final doctorCount = byRole['DOCTOR'] ?? 0;
    final driverCount = byRole['DRIVER'] ?? 0;
    final totalAppointments = operations['totalAppointments'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.security, color: Color(0xFFEF4444), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aarogya Central Command System',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total 3-App Ecosystem Authority. Doctor & Ambulance Staff strictly require Super Admin verification before duty access.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Ecosystem Metrics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard(
                title: 'Pending Approvals',
                value: '$pendingApprovals',
                icon: Icons.pending_actions,
                color: const Color(0xFFF59E0B),
                subtitle: 'Doctors & Pilots awaiting approval',
                onTap: () {
                  setState(() => _currentIndex = 1);
                  _refreshCurrentTab();
                },
              ),
              _buildMetricCard(
                title: 'Registered Doctors',
                value: '$doctorCount',
                icon: Icons.medical_services,
                color: const Color(0xFF3B82F6),
                subtitle: 'Doctor Pro network',
                onTap: () {
                  setState(() => _currentIndex = 1);
                  _refreshCurrentTab();
                },
              ),
              _buildMetricCard(
                title: 'Ambulance Fleet',
                value: '$driverCount',
                icon: Icons.emergency,
                color: const Color(0xFFEF4444),
                subtitle: 'Rapid EMS pilots',
                onTap: () {
                  setState(() => _currentIndex = 2);
                  _refreshCurrentTab();
                },
              ),
              _buildMetricCard(
                title: 'Patients Enrolled',
                value: '$patientCount',
                icon: Icons.people,
                color: const Color(0xFF10B981),
                subtitle: 'Auto-verified ABHA patients',
                onTap: () {
                  setState(() => _currentIndex = 4);
                  _refreshCurrentTab();
                },
              ),
              _buildMetricCard(
                title: 'Total Appointments',
                value: '$totalAppointments',
                icon: Icons.calendar_month,
                color: const Color(0xFF8B5CF6),
                subtitle: 'Consultations booked',
              ),
              _buildMetricCard(
                title: 'Platform Users',
                value: '$totalUsers',
                icon: Icons.hub,
                color: const Color(0xFF06B6D4),
                subtitle: 'Combined across 3 apps',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: DOCTORS APPROVALS
  Widget _buildDoctorsTab() {
    return Column(
      children: [
        // Controls
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              TextField(
                controller: _doctorSearchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search doctor by name, email, specialization...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                    onPressed: () {
                      _doctorSearchController.clear();
                      _fetchDoctors();
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _fetchDoctors(),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('PENDING', 'Pending Approval', _doctorStatusFilter, (val) {
                      setState(() => _doctorStatusFilter = val);
                      _fetchDoctors();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('VERIFIED', 'Verified & Active', _doctorStatusFilter, (val) {
                      setState(() => _doctorStatusFilter = val);
                      _fetchDoctors();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('REJECTED', 'Rejected', _doctorStatusFilter, (val) {
                      setState(() => _doctorStatusFilter = val);
                      _fetchDoctors();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('ALL', 'All Doctors', _doctorStatusFilter, (val) {
                      setState(() => _doctorStatusFilter = val);
                      _fetchDoctors();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _doctors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      Text(
                        'No doctors found for "$_doctorStatusFilter"',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _doctors.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final doc = _doctors[index];
                    final profile = doc['profile'] as Map<String, dynamic>? ?? doc['doctorProfile'] as Map<String, dynamic>? ?? {};
                    final name = doc['profileName'] ?? profile['fullName'] ?? 'Dr. Unknown';
                    final specialization = profile['specialization'] ?? 'General Medicine';
                    final nmc = profile['nmcRegistrationNumber'] ?? 'N/A';
                    final email = doc['email'] ?? '';
                    final phone = doc['phone'] ?? '';
                    final status = doc['verificationStatus'] ?? 'PENDING';
                    final isPending = status == 'PENDING';
                    final isVerified = status == 'VERIFIED';
                    final doctorId = doc['id']?.toString() ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPending
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                              : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                radius: 22,
                                child: const Icon(Icons.person, color: Color(0xFF3B82F6)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      specialization,
                                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'NMC Reg: $nmc',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const Divider(color: Color(0xFF334155), height: 16),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ),
                              if (phone.isNotEmpty) ...[
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(phone, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isVerified)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                  label: const Text('Approve & Activate', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  onPressed: () => _handleDoctorVerification(doctorId, name, 'VERIFIED'),
                                ),
                              const SizedBox(width: 8),
                              if (isPending || isVerified)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined, size: 16),
                                  label: const Text('Reject', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _handleDoctorVerification(doctorId, name, 'REJECTED'),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Delete ID Permanently',
                                icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
                                onPressed: () => _handleDeleteUser(doctorId, name, 'Doctor'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 2: AMBULANCE STAFF APPROVALS
  Widget _buildAmbulanceTab() {
    return Column(
      children: [
        // Controls
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              TextField(
                controller: _ambulanceSearchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search ambulance pilot by name, license, vehicle plate...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                    onPressed: () {
                      _ambulanceSearchController.clear();
                      _fetchAmbulanceStaff();
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _fetchAmbulanceStaff(),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('PENDING', 'Pending Approval', _ambulanceStatusFilter, (val) {
                      setState(() => _ambulanceStatusFilter = val);
                      _fetchAmbulanceStaff();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('VERIFIED', 'Verified Fleet', _ambulanceStatusFilter, (val) {
                      setState(() => _ambulanceStatusFilter = val);
                      _fetchAmbulanceStaff();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('REJECTED', 'Rejected', _ambulanceStatusFilter, (val) {
                      setState(() => _ambulanceStatusFilter = val);
                      _fetchAmbulanceStaff();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterChip('ALL', 'All Fleet', _ambulanceStatusFilter, (val) {
                      setState(() => _ambulanceStatusFilter = val);
                      _fetchAmbulanceStaff();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _ambulanceStaff.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emergency_outlined, size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      Text(
                        'No ambulance staff found for "$_ambulanceStatusFilter"',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _ambulanceStaff.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final staff = _ambulanceStaff[index];
                    final user = staff['user'] as Map<String, dynamic>? ?? {};
                    final name = staff['fullName'] ?? 'EMS Pilot';
                    final license = staff['licenseNumber'] ?? 'N/A';
                    final vehicle = staff['assignedVehicleNumber'] ?? 'Unassigned';
                    final email = user['email'] ?? staff['email'] ?? '';
                    final phone = user['phone'] ?? staff['phone'] ?? '';
                    final status = user['verificationStatus'] ?? staff['verificationStatus'] ?? 'PENDING';
                    final isPending = status == 'PENDING';
                    final isVerified = status == 'VERIFIED';
                    final staffId = staff['id']?.toString() ?? user['id']?.toString() ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPending
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                              : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                radius: 22,
                                child: const Icon(Icons.directions_car, color: Color(0xFFEF4444)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'License: $license',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Vehicle Plate: $vehicle',
                                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const Divider(color: Color(0xFF334155), height: 16),
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(email, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ),
                              if (phone.isNotEmpty) ...[
                                const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text(phone, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isVerified)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                  label: const Text('Approve & Activate', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  onPressed: () => _handleAmbulanceVerification(staffId, name, 'VERIFIED'),
                                ),
                              const SizedBox(width: 8),
                              if (isPending || isVerified)
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.cancel_outlined, size: 16),
                                  label: const Text('Reject', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _handleAmbulanceVerification(staffId, name, 'REJECTED'),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Delete ID Permanently',
                                icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 22),
                                onPressed: () {
                                  final targetUserId = user['id']?.toString() ?? staff['userId']?.toString() ?? staffId;
                                  _handleDeleteUser(targetUserId, name, 'Ambulance Pilot');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 3: LIVE SOS RADAR
  Widget _buildLiveSOSTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.radar, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live SOS Incident Radar',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Active patient emergency requests & live ambulance telemetry',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchEmergencies,
              ),
            ],
          ),
        ),
        Expanded(
          child: _emergencies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      const Text(
                        'No Active SOS Incidents',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All emergency requests are resolved or in standby.',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _emergencies.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = _emergencies[index];
                    final patient = item['patientProfile'] as Map<String, dynamic>? ?? {};
                    final patientUser = patient['user'] as Map<String, dynamic>? ?? {};
                    final patientName = patient['fullName'] ?? 'Emergency Patient';
                    final patientPhone = patientUser['phone'] ?? patient['phone'] ?? 'N/A';
                    final lat = item['latitude']?.toString() ?? '0.0';
                    final lng = item['longitude']?.toString() ?? '0.0';
                    final address = item['pickupAddress'] ?? 'Live GPS Location';
                    final status = item['status'] ?? 'REQUESTED';
                    final vehicle = item['assignedVehicleNo'] ?? 'Seeking nearest pilot';
                    final hospital = item['hospitalName'] ?? 'Emergency General';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    patientName,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              _buildEmergencyStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Address: $address',
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GPS: ($lat, $lng)',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace'),
                          ),
                          const Divider(color: Color(0xFF334155), height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Assigned: $vehicle', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                              ),
                              Text('Dest: $hospital', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text('Patient Contact: $patientPhone', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 4: PATIENTS DIRECTORY (3-APP ACCESS)
  Widget _buildPatientsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E293B),
          child: TextField(
            controller: _patientSearchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search patient by name, email, ABHA ID...',
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                onPressed: () {
                  _patientSearchController.clear();
                  _fetchPatients();
                },
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _fetchPatients(),
          ),
        ),
        Expanded(
          child: _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      const Text(
                        'No patients registered yet',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _patients.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = _patients[index];
                    final profile = item['profile'] as Map<String, dynamic>? ?? item['patientProfile'] as Map<String, dynamic>? ?? {};
                    final name = item['profileName'] ?? profile['fullName'] ?? 'Aarogya Patient';
                    final abha = profile['abhaId'] ?? 'N/A';
                    final email = item['email'] ?? '';
                    final phone = item['phone'] ?? '';
                    final isActive = item['isActive'] == true;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                            radius: 20,
                            child: const Icon(Icons.person, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ABHA: $abha',
                                  style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$email  •  $phone',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                color: isActive ? Colors.green : Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Delete ID Permanently',
                            icon: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 20),
                            onPressed: () {
                              final patientUserId = item['id']?.toString() ?? '';
                              _handleDeleteUser(patientUserId, name, 'Patient');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, String current, Function(String) onSelect) {
    final isSelected = value == current;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        ),
      ),
      selectedColor: const Color(0xFFEF4444),
      backgroundColor: const Color(0xFF0F172A),
      onSelected: (_) => onSelect(value),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'VERIFIED':
        bg = const Color(0xFF10B981).withValues(alpha: 0.2);
        fg = const Color(0xFF10B981);
        break;
      case 'REJECTED':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.2);
        fg = const Color(0xFFEF4444);
        break;
      case 'PENDING':
      default:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.2);
        fg = const Color(0xFFF59E0B);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmergencyStatusBadge(String status) {
    Color bg = const Color(0xFFEF4444).withValues(alpha: 0.2);
    Color fg = const Color(0xFFEF4444);
    if (status == 'EN_ROUTE' || status == 'ASSIGNED') {
      bg = const Color(0xFF3B82F6).withValues(alpha: 0.2);
      fg = const Color(0xFF38BDF8);
    } else if (status == 'RESOLVED' || status == 'COMPLETED') {
      bg = const Color(0xFF10B981).withValues(alpha: 0.2);
      fg = const Color(0xFF10B981);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
