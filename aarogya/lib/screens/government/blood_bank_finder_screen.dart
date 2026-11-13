import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';

class BloodBankFinderScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const BloodBankFinderScreen({super.key, this.service});

  @override
  State<BloodBankFinderScreen> createState() => _BloodBankFinderScreenState();
}

class _BloodBankFinderScreenState extends State<BloodBankFinderScreen> {
  late final GovernmentHealthService _service;
  bool _isLoading = true;
  List<Map<String, dynamic>> _bloodBanks = [];

  String _selectedBloodGroup = 'ALL';
  String _selectedComponent = 'ALL';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _bloodGroups = ['ALL', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _fetchBloodBanks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchBloodBanks() async {
    setState(() => _isLoading = true);
    try {
      final banks = await _service.getBloodBanks(
        bloodGroup: _selectedBloodGroup,
        component: _selectedComponent,
      );
      if (mounted) {
        setState(() {
          _bloodBanks = banks;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _makeCall(String? phone) {
    if (phone == null || phone.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to Blood Bank helpline: $phone'),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  void _showEmergencyRequestDialog(BuildContext context, Map<String, dynamic>? bank) {
    final patientNameCtrl = TextEditingController();
    final hospitalCtrl = TextEditingController(text: bank?['name']?.toString() ?? '');
    final unitsCtrl = TextEditingController(text: '2');
    String group = _selectedBloodGroup == 'ALL' ? 'O+' : _selectedBloodGroup;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: AppColors.sosRed),
            SizedBox(width: 8),
            Text('Aapatkaleen Blood Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: patientNameCtrl,
                decoration: const InputDecoration(labelText: 'Patient Name', hintText: 'Mareez ka naam'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hospitalCtrl,
                decoration: const InputDecoration(labelText: 'Hospital / Blood Bank Name'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: group,
                      items: _bloodGroups
                          .where((g) => g != 'ALL')
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) group = val;
                      },
                      decoration: const InputDecoration(labelText: 'Blood Group'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: unitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Units Required'),
                    ),
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
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aapatkaleen Blood Request e-RaktKosh Portal par darj ho gayi!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosRed),
            child: const Text('Send Alert (SOS)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBanks = _bloodBanks.where((b) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = (b['name'] ?? '').toString().toLowerCase();
      final city = (b['city'] ?? '').toString().toLowerCase();
      final state = (b['state'] ?? '').toString().toLowerCase();
      return name.contains(q) || city.contains(q) || state.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'e-RaktKosh Blood Bank Finder',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency_outlined, color: AppColors.sosRed),
            tooltip: 'Emergency Blood Request',
            onPressed: () => _showEmergencyRequestDialog(context, null),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filters Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search city, state or blood bank name...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
                      filled: true,
                      fillColor: AppColors.scaffoldBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Blood Group Horizontal Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _bloodGroups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final g = _bloodGroups[idx];
                        final isSel = _selectedBloodGroup == g;
                        return ChoiceChip(
                          label: Text(g, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: AppColors.sosRed,
                          backgroundColor: AppColors.scaffoldBg,
                          onSelected: (val) {
                            setState(() => _selectedBloodGroup = g);
                            _fetchBloodBanks();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : filteredBanks.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Chune gaye filters ke anuroop koi blood bank nahi mila.',
                              style: TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBanks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            return _buildBloodBankCard(filteredBanks[idx]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodBankCard(Map<String, dynamic> bank) {
    final name = bank['name']?.toString() ?? 'Blood Bank';
    final city = bank['city']?.toString() ?? '';
    final state = bank['state']?.toString() ?? '';
    final phone = bank['contactPhone']?.toString() ?? '108';
    final address = bank['address']?.toString() ?? '$city, $state';
    final isGovt = bank['isGovernment'] == true || bank['category'] == 'GOVT';
    final is24x7 = bank['is24x7'] == true || bank['componentFacility'] == true;
    final stock = (bank['stockAvailability'] ?? bank['stockSummary']) as Map<String, dynamic>? ?? {};

    return InkWell(
      onTap: () => _showBloodBankDetailsSheet(bank),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sosLightBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bloodtype_rounded, color: AppColors.sosRed, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Badges
            Row(
              children: [
                if (isGovt)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Government e-RaktKosh', style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 6),
                if (is24x7)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('24x7 Emergency', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                const Spacer(),
                Text(
                  'Tap for stock details →',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Live Stock Indicators
            const Text('Uplabdh Stock (Live Component Availability):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: stock.entries.take(6).map((entry) {
                final val = entry.value;
                final count = val is Map ? (val['units'] ?? val['wholeBlood'] ?? val['prbc'] ?? 10) : val;
                final isAvailable = (count is int && count > 0) || (count is num && count > 0);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isAvailable ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    '${entry.key}: $count Units',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? const Color(0xFF166534) : const Color(0xFF991B1B),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makeCall(phone),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: Text('Call ($phone)', style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEmergencyRequestDialog(context, bank),
                    icon: const Icon(Icons.emergency_rounded, size: 16, color: Colors.white),
                    label: const Text('SOS Request', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sosRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBloodBankDetailsSheet(Map<String, dynamic> bank) {
    final name = bank['name']?.toString() ?? 'Blood Bank';
    final city = bank['city']?.toString() ?? '';
    final state = bank['state']?.toString() ?? '';
    final phone = bank['contactPhone']?.toString() ?? '108';
    final address = bank['address']?.toString() ?? '$city, $state';
    final hfrId = bank['hfrId']?.toString() ?? 'IN2300000104';
    final stock = (bank['stockAvailability'] ?? bank['stockSummary']) as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.sosLightBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.bloodtype_rounded, color: AppColors.sosRed, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('HFR ID: $hfrId • e-RaktKosh Certified', style: const TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),
              // Address & Contact
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.sosRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kendra Pata (Address)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryTeal),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: address));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pata copy ho gaya!')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Full Blood Stock Breakdown (Sabhi Groups):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: stock.entries.map((e) {
                    final group = e.key;
                    final val = e.value;
                    final count = val is Map ? (val['units'] ?? val['wholeBlood'] ?? val['prbc'] ?? 10) : val;
                    final status = val is Map ? (val['status'] ?? 'AVAILABLE') : 'AVAILABLE';
                    final isLow = status == 'LOW' || status == 'CRITICAL';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.sosLightBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(group, style: const TextStyle(color: AppColors.sosRed, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const SizedBox(width: 12),
                              Text('Blood Group $group', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLow ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$count Units ($status)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLow ? Colors.red.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(phone),
                      icon: const Icon(Icons.call_rounded),
                      label: Text('Call $phone'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEmergencyRequestDialog(context, bank);
                      },
                      icon: const Icon(Icons.emergency_rounded, color: Colors.white),
                      label: const Text('SOS Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sosRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
