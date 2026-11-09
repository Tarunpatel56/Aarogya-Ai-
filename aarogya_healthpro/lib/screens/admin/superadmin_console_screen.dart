import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/admin_service.dart';
import '../../core/api/api_exception.dart';

class SuperAdminConsoleScreen extends StatefulWidget {
  final AdminService? adminService;

  const SuperAdminConsoleScreen({super.key, this.adminService});

  @override
  State<SuperAdminConsoleScreen> createState() => _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends State<SuperAdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  late final AdminService _adminService;
  late final TabController _tabController;

  final _searchController = TextEditingController();
  Map<String, dynamic>? _stats;
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _currentRoleFilter = 'ALL';
  String _currentVerificationFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _adminService = widget.adminService ?? AdminService();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      switch (_tabController.index) {
        case 0: // All
          _currentRoleFilter = 'ALL';
          _currentVerificationFilter = 'ALL';
          break;
        case 1: // Doctors
          _currentRoleFilter = 'DOCTOR';
          _currentVerificationFilter = 'ALL';
          break;
        case 2: // Pending Verification
          _currentRoleFilter = 'DOCTOR';
          _currentVerificationFilter = 'PENDING';
          break;
        case 3: // Patients
          _currentRoleFilter = 'PATIENT';
          _currentVerificationFilter = 'ALL';
          break;
      }
    });
    _fetchUsers();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statsData = await _adminService.getStats();
      final usersData = await _adminService.getUsers(
        role: _currentRoleFilter,
        verificationStatus: _currentVerificationFilter,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _stats = statsData;
          _users = usersData['users'] as List? ?? [];
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load administration console: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final usersData = await _adminService.getUsers(
        role: _currentRoleFilter,
        verificationStatus: _currentVerificationFilter,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _users = usersData['users'] as List? ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh user list: $e')),
        );
      }
    }
  }

  Future<void> _verifyDoctor(String userId, String doctorName) async {
    try {
      await _adminService.verifyDoctor(userId, status: 'VERIFIED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $doctorName is now VERIFIED and active on Aarogya App!'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, String email, bool currentActive) async {
    final nextStatus = !currentActive;
    try {
      await _adminService.updateUserStatus(
        userId,
        isActive: nextStatus,
        reason: nextStatus ? 'Reactivated by SuperAdmin' : 'Suspended by SuperAdmin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextStatus ? 'User account activated' : 'User account suspended'),
            backgroundColor: nextStatus ? AppColors.primary : Colors.orange,
          ),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(String userId, String email, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Permanently Delete User?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently remove "$name" ($email) from the Aarogya Ecosystem?\n\nThis will permanently delete their account, profile, records, and access tokens.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $email permanently removed.'),
              backgroundColor: Colors.red.shade700,
            ),
          );
          _loadAll();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SuperAdmin Ecosystem Console',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Full Control & Access Matrix (Logged in as SuperAdmin)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Ecosystem Data',
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Accounts'),
            Tab(text: 'Doctors Directory'),
            Tab(text: 'Pending Approvals'),
            Tab(text: 'Patients'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats Row
                      if (_stats != null && _stats!['users'] != null) _buildStatsSection(),
                      const SizedBox(height: 16),

                      // Search bar
                      TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _fetchUsers(),
                        decoration: InputDecoration(
                          hintText: 'Search by name, email, role, license...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchUsers();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.borderHairline),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Results Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ECOSYSTEM ACCOUNTS (${_users.length})',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Filter: ${_currentRoleFilter.toLowerCase()}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // User items
                      if (_users.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderHairline),
                          ),
                          child: const Center(
                            child: Text(
                              'No matching accounts found.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ..._users.map((u) => _buildUserCard(u)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsSection() {
    final usersStats = _stats!['users'];
    final byRole = usersStats['byRole'] ?? {};
    final total = usersStats['total'] ?? 0;
    final active = usersStats['active'] ?? 0;
    final pending = usersStats['pendingVerification'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF38BDF8), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PLATFORM COMMAND STATUS',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: const Text(
                  'HEALTHY',
                  style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric('TOTAL USERS', total.toString(), Colors.white),
              _buildStatMetric('ACTIVE', active.toString(), const Color(0xFF34D399)),
              _buildStatMetric('DOCTORS', (byRole['DOCTOR'] ?? 0).toString(), const Color(0xFF38BDF8)),
              _buildStatMetric('PENDING', pending.toString(), const Color(0xFFFBBF24)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    final id = user['id']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final role = user['role']?.toString() ?? 'PATIENT';
    final verificationStatus = user['verificationStatus']?.toString() ?? 'PENDING';
    final isActive = user['isActive'] == true;
    final doctorProfile = user['doctorProfile'];
    final patientProfile = user['patientProfile'];

    String displayName = email;
    String subtitle = 'Role: $role';
    if (doctorProfile != null && doctorProfile['fullName'] != null) {
      displayName = doctorProfile['fullName'].toString();
      subtitle = 'Dr. • ${doctorProfile['specialization']} • NMC: ${doctorProfile['nmcRegistrationNumber'] ?? "Pending"}';
    } else if (patientProfile != null && patientProfile['fullName'] != null) {
      displayName = patientProfile['fullName'].toString();
      subtitle = 'Patient • Gender: ${patientProfile['gender'] ?? "-"}';
    }

    final isDoctor = role == 'DOCTOR';
    final isVerified = verificationStatus == 'VERIFIED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !isActive ? Colors.red.shade200 : AppColors.borderHairline,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDoctor
                    ? const Color(0xFF00685F).withValues(alpha: 0.12)
                    : const Color(0xFF4F46E5).withValues(alpha: 0.12),
                child: Icon(
                  isDoctor ? Icons.medical_services : Icons.person,
                  color: isDoctor ? const Color(0xFF00685F) : const Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Verification badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isVerified ? 'VERIFIED' : 'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isVerified ? const Color(0xFF15803D) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Active/Inactive badge
                  Text(
                    isActive ? '● Active' : '● Suspended',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? const Color(0xFF15803D) : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),

          // Action row (Wrap eliminates any RenderFlex overflow on small screens)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              // Verify button for unverified doctors
              if (isDoctor && !isVerified)
                ElevatedButton.icon(
                  onPressed: () => _verifyDoctor(id, displayName),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Verify Doctor', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle active/inactive
                  TextButton.icon(
                    onPressed: () => _toggleUserStatus(id, email, isActive),
                    icon: Icon(
                      isActive ? Icons.block : Icons.check,
                      size: 16,
                      color: isActive ? Colors.orange.shade800 : const Color(0xFF15803D),
                    ),
                    label: Text(
                      isActive ? 'Suspend' : 'Activate',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.orange.shade800 : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 20),
                    tooltip: 'Permanently Remove Account',
                    onPressed: () => _confirmDeleteUser(id, email, displayName),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

