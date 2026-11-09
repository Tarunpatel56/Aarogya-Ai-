import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/hospital_model.dart';
import '../../services/hospital_service.dart';
import '../../core/api/api_exception.dart';

class NearbyHospitalsScreen extends StatefulWidget {
  final HospitalService? hospitalService;

  const NearbyHospitalsScreen({super.key, this.hospitalService});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  late final HospitalService _service;
  List<HospitalModel> _allHospitals = [];
  List<HospitalModel> _filteredHospitals = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = widget.hospitalService ?? HospitalService();
    _loadHospitals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _service.getNearbyHospitals(
        latitude: 28.5672,
        longitude: 77.2100,
        radiusKm: 30,
      );

      if (!mounted) return;
      setState(() {
        _allHospitals = list;
        _isLoading = false;
      });
      _applyFilter();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load hospitals: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredHospitals = _allHospitals.filter((h) {
        final matchesQuery = query.isEmpty ||
            h.name.toLowerCase().contains(query) ||
            h.address.toLowerCase().contains(query);

        if (!matchesQuery) return false;

        if (_selectedFilter == 'EMERGENCY_ONLY') {
          return h.hasEmergencyBay;
        } else if (_selectedFilter == 'ICU_AVAILABLE') {
          return h.availableIcuBeds > 0;
        } else if (_selectedFilter == 'NEAR_5KM') {
          return (h.distanceKm ?? 999) <= 5.0;
        }
        return true;
      }).toList();
    });
  }

  void _callHospital(HospitalModel hospital) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dialing ${hospital.name} emergency: ${hospital.emergencyPhone}'),
        backgroundColor: AppColors.primaryTeal,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openDirections(HospitalModel hospital) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening navigation to ${hospital.name} (${hospital.distanceKm ?? 0} km)'),
        backgroundColor: const Color(0xFF1D4ED8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Nearby Hospitals & Verified Beds',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHospitals,
            tooltip: 'Refresh live bed counts',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilter(),
                  decoration: InputDecoration(
                    hintText: 'Search hospital name or area...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('ALL', 'All Hospitals'),
                      const SizedBox(width: 8),
                      _buildChip('EMERGENCY_ONLY', 'Emergency Bay'),
                      const SizedBox(width: 8),
                      _buildChip('ICU_AVAILABLE', 'ICU Beds Available'),
                      const SizedBox(width: 8),
                      _buildChip('NEAR_5KM', 'Within 5 km'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Hospital List Feed
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryTeal)))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _filteredHospitals.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadHospitals,
                            color: AppColors.primaryTeal,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredHospitals.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _buildHospitalCard(_filteredHospitals[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedFilter = key);
        _applyFilter();
      },
      selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primaryTeal : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHospitalCard(HospitalModel h) {
    final bool hasIcu = h.availableIcuBeds > 0;
    final Color icuColor = hasIcu ? const Color(0xFF15803D) : const Color(0xFFDC2626);

    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      h.address,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (h.distanceKm != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.near_me, size: 12, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        '${h.distanceKm} km',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges: Emergency Bay & Trauma Center
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (h.hasEmergencyBay)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.emergency_outlined, size: 12, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        '24/7 Emergency Bay',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ),
              if (h.hasTraumaCenter)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'Trauma Center',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Live Verified Beds Counter
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: icuColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERIFIED ICU BEDS',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${h.availableIcuBeds} Available / ${h.totalIcuBeds}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: icuColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NORMAL BEDS',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${h.availableNormalBeds} / ${h.totalNormalBeds}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: Call & Directions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callHospital(h),
                  icon: const Icon(Icons.call, size: 16, color: Color(0xFFDC2626)),
                  label: Text(
                    'Emergency: ${h.emergencyPhone}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openDirections(h),
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Directions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_hospital_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('No hospitals found matching filter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _selectedFilter = 'ALL');
              _applyFilter();
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load hospitals',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHospitals,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

extension FilterExtension<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    return where(test).toList();
  }
}
