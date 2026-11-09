import 'package:flutter/material.dart';
import '../../models/hospital_bed_model.dart';
import '../../services/hospital_management_service.dart';
import '../../theme/app_colors.dart';

class HospitalBedsScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const HospitalBedsScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<HospitalBedsScreen> createState() => _HospitalBedsScreenState();
}

class _HospitalBedsScreenState extends State<HospitalBedsScreen> {
  final _service = HospitalManagementService();
  List<HospitalBedModel> _beds = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadBeds();
  }

  Future<void> _loadBeds() async {
    setState(() => _isLoading = true);
    final beds = await _service.getHospitalBeds(widget.hospitalId);
    if (mounted) {
      setState(() {
        _beds = beds;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeBedStatus(HospitalBedModel bed, String newStatus, {String? patientName}) async {
    final updated = await _service.updateBedStatus(
      hospitalId: widget.hospitalId,
      bedId: bed.id,
      status: newStatus,
      occupiedByPatient: patientName,
    );

    if (updated != null && mounted) {
      setState(() {
        final index = _beds.indexWhere((b) => b.id == bed.id);
        if (index != -1) {
          _beds[index] = updated;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryTeal,
          content: Text('Bed ${bed.bedNumber} marked as $newStatus'),
        ),
      );
    }
  }

  void _showStatusDialog(HospitalBedModel bed) {
    final patientController = TextEditingController(text: bed.occupiedByPatient ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Manage Bed ${bed.bedNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department: ${bed.departmentName} (${bed.bedType})'),
            const SizedBox(height: 12),
            TextField(
              controller: patientController,
              decoration: const InputDecoration(
                labelText: 'Admitted Patient Name',
                hintText: 'e.g. Ramesh Kumar',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _changeBedStatus(bed, 'AVAILABLE');
            },
            child: const Text('Discharge / Set Available', style: TextStyle(color: Colors.green)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _changeBedStatus(bed, 'OCCUPIED', patientName: patientController.text.trim());
            },
            child: const Text('Admit / Occupy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _beds.where((b) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'ICU') return b.bedType == 'ICU';
      if (_selectedFilter == 'AVAILABLE') return b.isAvailable;
      if (_selectedFilter == 'OCCUPIED') return !b.isAvailable;
      return true;
    }).toList();

    final availableIcu = _beds.where((b) => b.bedType == 'ICU' && b.isAvailable).length;
    final totalIcu = _beds.where((b) => b.bedType == 'ICU').length;
    final availableNormal = _beds.where((b) => b.bedType != 'ICU' && b.isAvailable).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.hospitalName),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBeds,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Metrics Overview Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCol('ICU Beds', '$availableIcu / $totalIcu', Colors.teal),
                      const VerticalDivider(width: 20),
                      _buildMetricCol('Normal Beds', '$availableNormal Available', Colors.blue),
                      const VerticalDivider(width: 20),
                      _buildMetricCol('Total Wards', '${_beds.length} Beds', AppColors.primaryDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'ICU', 'AVAILABLE', 'OCCUPIED'].map((filter) {
                      final selected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                          onSelected: (_) => setState(() => _selectedFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Bed Cards Grid
                ...filtered.map((bed) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.cardBorder),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: bed.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
                        child: Icon(
                          bed.isIcu ? Icons.emergency : Icons.bed,
                          color: bed.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(bed.bedNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(bed.bedType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        bed.isAvailable
                            ? '${bed.departmentName} • Ready for admission'
                            : 'Occupied by: ${bed.occupiedByPatient ?? "Emergency In-Patient"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: bed.isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_note, color: AppColors.primaryTeal),
                        onPressed: () => _showStatusDialog(bed),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

