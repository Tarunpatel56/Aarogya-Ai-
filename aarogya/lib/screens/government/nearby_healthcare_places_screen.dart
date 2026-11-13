import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/government_health_service.dart';
import '../../services/device_location_service.dart';

class NearbyHealthcarePlacesScreen extends StatefulWidget {
  final GovernmentHealthService? service;

  const NearbyHealthcarePlacesScreen({super.key, this.service});

  @override
  State<NearbyHealthcarePlacesScreen> createState() => _NearbyHealthcarePlacesScreenState();
}

class _NearbyHealthcarePlacesScreenState extends State<NearbyHealthcarePlacesScreen> {
  late final GovernmentHealthService _service;
  bool _isLoading = true;
  DeviceLocation? _currentLocation;
  List<Map<String, dynamic>> _places = [];
  String _sourceEngine = 'AAROGYA_GEOLOCATION_ENGINE';

  String _selectedCategory = 'ALL';
  int _selectedRadiusKm = 10;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'label': 'All Healthcare', 'value': 'ALL', 'icon': 'local_hospital'},
    {'label': 'Hospitals', 'value': 'HOSPITAL', 'icon': 'local_hospital'},
    {'label': 'Clinics', 'value': 'CLINIC', 'icon': 'medical_services'},
    {'label': 'Pharmacies', 'value': 'PHARMACY', 'icon': 'local_pharmacy'},
    {'label': 'Diagnostic Labs', 'value': 'DIAGNOSTIC_LAB', 'icon': 'biotech'},
    {'label': 'Jan Aushadhi', 'value': 'JAN_AUSHADHI', 'icon': 'medication'},
    {'label': 'Blood Banks', 'value': 'BLOOD_BANK', 'icon': 'bloodtype'},
  ];

  final List<int> _radii = [2, 5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GovernmentHealthService();
    _loadLocationAndPlaces();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocationAndPlaces() async {
    setState(() => _isLoading = true);
    try {
      final loc = await DeviceLocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() => _currentLocation = loc);

      final res = await _service.searchNearbyHealthcare(
        latitude: loc.latitude,
        longitude: loc.longitude,
        category: _selectedCategory,
        radiusMeters: _selectedRadiusKm * 1000,
        keyword: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
      );

      if (!mounted) return;
      setState(() {
        _places = List<Map<String, dynamic>>.from(res['places'] ?? []);
        _sourceEngine = res['source']?.toString() ?? 'AAROGYA_GEOLOCATION_ENGINE';
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _callPlace(String? phone) {
    if (phone == null || phone.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Helpline contact: $phone'),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Nearby Healthcare Finder',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.primaryTeal),
            tooltip: 'Re-locate',
            onPressed: _loadLocationAndPlaces,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Category Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _loadLocationAndPlaces(),
                    decoration: InputDecoration(
                      hintText: 'Search hospital, clinic, lab or medicine store...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryTeal),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryTeal),
                        onPressed: _loadLocationAndPlaces,
                      ),
                      filled: true,
                      fillColor: AppColors.scaffoldBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category Chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSel = _selectedCategory == cat['value'];
                        return ChoiceChip(
                          label: Text(
                            cat['label']!,
                            style: TextStyle(
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primaryTeal,
                          backgroundColor: AppColors.scaffoldBg,
                          onSelected: (val) {
                            setState(() => _selectedCategory = cat['value']!);
                            _loadLocationAndPlaces();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Radius Selector
                  Row(
                    children: [
                      const Icon(Icons.radar_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Radius: ${_selectedRadiusKm}km',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      ..._radii.map((r) {
                        final isSel = _selectedRadiusKm == r;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedRadiusKm = r);
                            _loadLocationAndPlaces();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primaryTeal.withValues(alpha: 0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isSel ? AppColors.primaryTeal : Colors.grey.shade300),
                            ),
                            child: Text(
                              '${r}km',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSel ? AppColors.primaryTeal : AppColors.textSecondary),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            // Engine status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF0FDF4),
              child: Row(
                children: [
                  const Icon(Icons.satellite_alt_rounded, size: 14, color: Color(0xFF166534)),
                  const SizedBox(width: 6),
                  Text(
                    _sourceEngine == 'GOOGLE_PLACES_API'
                        ? 'Connected: Google Maps Platform Places API (New)'
                        : 'Aarogya Geolocation Engine (Verified Indian Healthcare)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                  ),
                  const Spacer(),
                  if (_currentLocation != null)
                    Text(
                      _currentLocation!.cityName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                ],
              ),
            ),

            // Places List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                  : _places.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Is radius me koi verified healthcare suvidha nahi mili.\nKripya radius badhayein ya doosra keyword search karein.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _places.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) => _buildPlaceCard(_places[idx]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> p) {
    final name = p['name']?.toString() ?? 'Healthcare Facility';
    final address = p['address']?.toString() ?? '';
    final category = p['category']?.toString() ?? 'HEALTHCARE';
    final dist = (p['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final phone = p['phone']?.toString();
    final rating = (p['rating'] as num?)?.toDouble();
    final is24x7 = p['is24x7'] == true;

    Color catColor = AppColors.primaryTeal;
    IconData catIcon = Icons.local_hospital_rounded;

    if (category == 'BLOOD_BANK') {
      catColor = AppColors.sosRed;
      catIcon = Icons.bloodtype_rounded;
    } else if (category == 'JAN_AUSHADHI') {
      catColor = const Color(0xFF0284C7);
      catIcon = Icons.medication_rounded;
    } else if (category == 'PHARMACY') {
      catColor = const Color(0xFF059669);
      catIcon = Icons.local_pharmacy_rounded;
    } else if (category == 'DIAGNOSTIC_LAB') {
      catColor = const Color(0xFF7C3AED);
      catIcon = Icons.biotech_rounded;
    }

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 24),
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
                    const SizedBox(height: 3),
                    Text(address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${dist.toStringAsFixed(1)} km',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryTeal),
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              if (is24x7)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('24x7 Open', style: TextStyle(color: Colors.green.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const Spacer(),
              if (phone != null && phone.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _callPlace(phone),
                  icon: const Icon(Icons.call, size: 14),
                  label: Text('Call ($phone)', style: const TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryTeal),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

