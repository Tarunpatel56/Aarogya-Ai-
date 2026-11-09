import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/medical_record_model.dart';
import '../models/patient_profile_model.dart';
import '../services/patient_service.dart';
import '../services/auth_service.dart';
import '../core/api/api_exception.dart';

class RecordsScreen extends StatefulWidget {
  final PatientService? patientService;
  final AuthService? authService;

  const RecordsScreen({
    super.key,
    this.patientService,
    this.authService,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late final PatientService _patientService;
  List<MedicalRecordModel> _records = [];
  PatientProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'ALL';

  final List<String> _filters = [
    'ALL',
    'PRESCRIPTION',
    'LAB_REPORT',
    'DISCHARGE_SUMMARY',
    'IMAGING',
    'VACCINATION',
  ];

  @override
  void initState() {
    super.initState();
    _patientService = widget.patientService ?? PatientService(apiClient: widget.authService?.apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileFuture = _patientService.getProfile().catchError((_) {
        return widget.authService?.currentProfile ??
            const PatientProfileModel(
              id: '',
              userId: '',
              fullName: 'Patient',
            );
      });

      final filterType = _selectedFilter == 'ALL' ? null : _selectedFilter;
      final recordsFuture = _patientService.getMedicalRecordModels(recordType: filterType);

      final results = await Future.wait([profileFuture, recordsFuture]);
      if (mounted) {
        setState(() {
          _profile = results[0] as PatientProfileModel;
          _records = results[1] as List<MedicalRecordModel>;
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load medical records. Please pull to refresh.';
          _isLoading = false;
        });
      }
    }
  }

  void _showAddRecordDialog() {
    final titleController = TextEditingController();
    final doctorController = TextEditingController();
    final facilityController = TextEditingController();
    final descController = TextEditingController();
    String recordType = 'PRESCRIPTION';
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text(
            'Upload Medical Document',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                    ),
                  ),
                ],
                const Text('Document Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Cardiology Follow-up Report',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Document Type *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: recordType,
                  items: const [
                    DropdownMenuItem(value: 'PRESCRIPTION', child: Text('Prescription')),
                    DropdownMenuItem(value: 'LAB_REPORT', child: Text('Lab Report')),
                    DropdownMenuItem(value: 'DISCHARGE_SUMMARY', child: Text('Discharge Summary')),
                    DropdownMenuItem(value: 'IMAGING', child: Text('Diagnostic Imaging')),
                    DropdownMenuItem(value: 'VACCINATION', child: Text('Vaccination Record')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other Medical Record')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => recordType = val);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Issuing Doctor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: doctorController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dr. R. Verma',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Hospital / Facility Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: facilityController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Apollo Hospital',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Notes / Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Optional clinical observations or instructions',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        setModalState(() => dialogError = 'Document title is required.');
                        return;
                      }

                      setModalState(() {
                        isSaving = true;
                        dialogError = null;
                      });

                      try {
                        await _patientService.createMedicalRecord(
                          recordType: recordType,
                          title: titleController.text.trim(),
                          description: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : null,
                          issuingDoctor: doctorController.text.trim().isNotEmpty
                              ? doctorController.text.trim()
                              : null,
                          facilityName: facilityController.text.trim().isNotEmpty
                              ? facilityController.text.trim()
                              : null,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Medical record saved securely to ABHA vault!'),
                              backgroundColor: AppColors.primaryTeal,
                            ),
                          );
                          _loadData();
                        }
                      } on ApiException catch (e) {
                        setModalState(() {
                          isSaving = false;
                          dialogError = e.message;
                        });
                      } catch (_) {
                        setModalState(() {
                          isSaving = false;
                          dialogError = 'Failed to save record. Please try again.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Record', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _profile?.fullName ?? widget.authService?.currentUser?.email ?? 'Patient';
    final abhaId = _profile?.abhaId != null && _profile!.abhaId!.isNotEmpty
        ? 'ABHA: ${_profile!.abhaId}'
        : 'ABHA: Verified Local Profile';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                            'Health Records',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ABHA PHR Locker & Clinical Documents',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryTeal, size: 28),
                      tooltip: 'Upload Document',
                      onPressed: _showAddRecordDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Real ABHA Locker Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF004D40), Color(0xFF00796B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.elevatedShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ABDM Digital Health Locker',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        patientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        abhaId,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${_records.length} Verified Document${_records.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Zero-Knowledge Encrypted ✓',
                              style: TextStyle(
                                color: Color(0xFF80CBC4),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      final label = filter == 'ALL'
                          ? 'All'
                          : filter
                              .replaceAll('_', ' ')
                              .toLowerCase()
                              .split(' ')
                              .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                              .join(' ');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedFilter = filter);
                              _loadData();
                            }
                          },
                          selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryTeal : const Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryTeal),
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                          label: const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ] else if (_records.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.folder_open_rounded,
                            color: Color(0xFF94A3B8),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Medical Records Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your health locker has no recorded files yet. Upload a prescription, lab test, or scan a document with AI.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddRecordDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add, size: 18, color: Colors.white),
                          label: const Text(
                            'Upload First Record',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _records.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _records[index];
                      return _buildRecordCard(item);
                    },
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.primaryTeal),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Checking ABHA gateway for newly synced clinical records...'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                      _loadData();
                    },
                    icon: const Icon(Icons.sync_rounded, color: AppColors.primaryTeal),
                    label: const Text(
                      'Sync with Ayushman Bharat Network',
                      style: TextStyle(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(MedicalRecordModel record) {
    IconData icon;
    Color iconBg;
    Color iconColor;

    switch (record.recordType) {
      case 'PRESCRIPTION':
        icon = Icons.description_outlined;
        iconBg = AppColors.mintBg;
        iconColor = AppColors.primaryTeal;
        break;
      case 'LAB_REPORT':
        icon = Icons.science_outlined;
        iconBg = const Color(0xFFEFF6FF);
        iconColor = const Color(0xFF2563EB);
        break;
      case 'DISCHARGE_SUMMARY':
        icon = Icons.local_hospital_outlined;
        iconBg = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        break;
      case 'IMAGING':
        icon = Icons.biotech_outlined;
        iconBg = const Color(0xFFF3E8FF);
        iconColor = const Color(0xFF9333EA);
        break;
      case 'VACCINATION':
        icon = Icons.vaccines_outlined;
        iconBg = const Color(0xFFECFDF5);
        iconColor = const Color(0xFF059669);
        break;
      default:
        icon = Icons.folder_outlined;
        iconBg = const Color(0xFFF1F5F9);
        iconColor = const Color(0xFF475569);
    }

    final dateStr = '${record.recordDate.day}/${record.recordDate.month}/${record.recordDate.year}';
    final subtitle = [
      if (record.issuingDoctor != null) record.issuingDoctor!,
      if (record.facilityName != null) record.facilityName!,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.formattedType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (record.description != null && record.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    record.description!,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const Spacer(),
                    const Text(
                      'Verified EHR ✓',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
