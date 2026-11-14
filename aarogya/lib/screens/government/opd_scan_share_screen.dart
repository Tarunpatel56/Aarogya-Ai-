import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';
import '../../core/storage/token_storage.dart';

class OpdScanShareScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const OpdScanShareScreen({super.key, this.service});

  @override
  State<OpdScanShareScreen> createState() => _OpdScanShareScreenState();
}

class _OpdScanShareScreenState extends State<OpdScanShareScreen> {
  late final GovernmentHealthService _service;
  final ITokenStorage _tokenStorage = SecureTokenStorage();

  bool _isGeneratingToken = false;
  Map<String, dynamic>? _generatedToken;
  String? _patientProfileId;

  String _selectedHospitalHipId = 'IN2310000001';
  String _selectedDepartment = 'General Medicine';
  String _selectedCity = 'Indore';

  final List<String> _cityFilterChips = ['Indore', 'Bhopal', 'Delhi', 'All Cities'];

  final List<Map<String, String>> _allHospitals = [
    {'name': 'Maharaja Yeshwantrao (MY) Hospital Indore (ABDM Smart Counter 01)', 'hipId': 'IN2310000001', 'city': 'Indore'},
    {'name': 'Government Super Speciality Hospital Indore (ABDM Counter 02)', 'hipId': 'IN2310000002', 'city': 'Indore'},
    {'name': 'District Civil Hospital Indore (Ayushman OPD Counter)', 'hipId': 'IN2310000008', 'city': 'Indore'},
    {'name': 'Chacha Nehru Bal Chikitsalaya Indore (Pediatric OPD)', 'hipId': 'IN2310000005', 'city': 'Indore'},
    {'name': 'PC Sethi Maternity Hospital Indore (MCH OPD)', 'hipId': 'IN2310000006', 'city': 'Indore'},
    {'name': 'Bombay Hospital & Research Centre Indore (Digital OPD Desk)', 'hipId': 'IN2310000003', 'city': 'Indore'},
    {'name': 'Choithram Hospital Indore (ABDM Digital Desk)', 'hipId': 'IN2310000004', 'city': 'Indore'},
    {'name': 'Sri Aurobindo Medical College (SAIMS) Indore', 'hipId': 'IN2310000007', 'city': 'Indore'},
    {'name': 'AIIMS Bhopal (Central OPD Block)', 'hipId': 'IN2310000009', 'city': 'Bhopal'},
    {'name': 'AIIMS New Delhi (ABDM OPD Counter)', 'hipId': 'IN0810000001', 'city': 'Delhi'},
    {'name': 'Safdarjung Hospital OPD Block', 'hipId': 'IN0810000002', 'city': 'Delhi'},
  ];

  final List<String> _departments = [
    'General Medicine',
    'Cardiology',
    'Orthopaedics',
    'Paediatrics',
    'Gynaecology & Obstetrics',
    'ENT & Ophthalmology',
    'Dermatology',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _tokenStorage.getUser();
    final id = user?['patientProfile']?['id']?.toString() ??
        user?['profile']?['id']?.toString() ??
        user?['id']?.toString();
    // Always ensure a non-null profileId — use user id or stable fallback
    _patientProfileId = (id != null && id.isNotEmpty) ? id : 'patient-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _generateOpdToken() async {
    if (_patientProfileId == null || _patientProfileId!.isEmpty) {
      await _loadProfile();
    }
    // Guaranteed non-null at this point from _loadProfile
    final profileId = _patientProfileId!;

    setState(() => _isGeneratingToken = true);
    try {
      final res = await _service.scanAndShareOpd(
        hipId: _selectedHospitalHipId,
        patientProfileId: profileId,
        department: _selectedDepartment,
        counterId: 'Counter 03',
      );

      if (mounted) {
        setState(() {
          _generatedToken = res;
          _isGeneratingToken = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingToken = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OPD Token generation me truti: $e'), backgroundColor: AppColors.sosRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'ABDM OPD Scan & Share',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // How it works banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryTeal, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Line Me Lagna Band!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF166534))),
                        SizedBox(height: 4),
                        Text(
                          'Hospital OPD Counter par laga QR code scan karein aur 10 second me digital OPD Token prapt karein.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scan / Select Hospital Counter Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hospital & Department Chunein', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('Indore ya anya shahar chunein aur digital OPD token prapt karein:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  // City Filter Chips
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cityFilterChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final c = _cityFilterChips[idx];
                        final isSel = _selectedCity == c;
                        return ChoiceChip(
                          label: Text(c, style: TextStyle(color: isSel ? Colors.white : AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                          selected: isSel,
                          selectedColor: AppColors.primaryTeal,
                          backgroundColor: AppColors.scaffoldBg,
                          onSelected: (val) {
                            setState(() {
                              _selectedCity = c;
                              final available = _allHospitals.where((h) => c == 'All Cities' || h['city'] == c).toList();
                              if (available.isNotEmpty) {
                                _selectedHospitalHipId = available.first['hipId']!;
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: _selectedHospitalHipId,
                    isExpanded: true,
                    items: _allHospitals
                        .where((h) => _selectedCity == 'All Cities' || h['city'] == _selectedCity)
                        .map((h) => DropdownMenuItem(value: h['hipId'], child: Text(h['name']!, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedHospitalHipId = val);
                    },
                    decoration: InputDecoration(
                      labelText: 'Hospital (Indore & ABDM Registry)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    items: _departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDepartment = val);
                    },
                    decoration: InputDecoration(
                      labelText: 'OPD Department / Vibhaag',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isGeneratingToken ? null : _generateOpdToken,
                    icon: _isGeneratingToken
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.qr_code_rounded, color: Colors.white),
                    label: const Text('Scan & Share: Instant Token Generate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            if (_generatedToken != null) ...[
              const SizedBox(height: 20),
              _buildTokenDisplayCard(_generatedToken!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTokenDisplayCard(Map<String, dynamic> token) {
    final tokenNumber = token['tokenNumber']?.toString() ?? 'OPD-108';
    final hospital = token['hospitalName']?.toString() ?? 'Civil Hospital';
    final counter = token['counterNumber']?.toString() ?? 'Counter 03';
    final dept = token['department']?.toString() ?? 'General Medicine';
    final waitMinutes = token['estimatedWaitMinutes']?.toString() ?? '15';
    final abhaAddress = token['abhaAddress']?.toString() ?? 'Citizen ABHA Verified';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 20),
                  SizedBox(width: 6),
                  Text('TOKEN GENERATED', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Live Queue', style: const TextStyle(fontSize: 10, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tokenNumber,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryTeal,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(hospital, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('$dept • $counter', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Anumanit Samay', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('~ $waitMinutes Mins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                ],
              ),
              Container(height: 24, width: 1, color: Colors.grey.shade300),
              Column(
                children: [
                  const Text('ABHA Status', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(abhaAddress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryTeal)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
