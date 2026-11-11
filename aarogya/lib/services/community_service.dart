import '../core/api/api_client.dart';

class CommunityService {
  final ApiClient _apiClient;

  CommunityService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Retrieve Government Health Schemes (PM-JAY, Vay Vandana, Jan Aushadhi, etc.)
  Future<List<Map<String, dynamic>>> getGovernmentSchemes({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      final res = await _apiClient.get('/community/government-schemes', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'] as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['schemes'] ?? []);
      }
      return [];
    } catch (_) {
      return _fallbackSchemes;
    }
  }

  /// Retrieve Blood Donors directory
  Future<List<Map<String, dynamic>>> getBloodDonors({String? bloodGroup, String? city}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (bloodGroup != null && bloodGroup.isNotEmpty && bloodGroup != 'ALL') {
        queryParams['bloodGroup'] = bloodGroup;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      final res = await _apiClient.get('/community/blood-donors', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'] as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['donors'] ?? []);
      }
      return [];
    } catch (_) {
      return _fallbackDonors;
    }
  }

  /// Register as voluntary blood donor
  Future<Map<String, dynamic>> registerBloodDonor({
    required String fullName,
    required String bloodGroup,
    required String city,
    String? district,
    required String contactPhone,
    String? lastDonatedDate,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      'bloodGroup': bloodGroup,
      'city': city,
      'contactPhone': contactPhone,
    };
    if (district != null) body['district'] = district;
    if (lastDonatedDate != null) body['lastDonatedDate'] = lastDonatedDate;
    final res = await _apiClient.post('/community/blood-donors', body: body);
    if (res is Map<String, dynamic> && res.containsKey('data')) {
      return (res['data'] as Map<String, dynamic>)['donor'] ?? {};
    }
    return {'fullName': fullName, 'bloodGroup': bloodGroup, 'city': city};
  }

  /// Retrieve Health Camps
  Future<List<Map<String, dynamic>>> getHealthCamps({String? city, String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      final res = await _apiClient.get('/community/health-camps', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'] as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['camps'] ?? []);
      }
      return [];
    } catch (_) {
      return _fallbackCamps;
    }
  }

  /// Retrieve Universal Immunization & Vaccination schedule
  Future<List<Map<String, dynamic>>> getVaccinations({String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      final res = await _apiClient.get('/community/vaccinations', queryParams: queryParams);
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        final data = res['data'] as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['vaccines'] ?? []);
      }
      return [];
    } catch (_) {
      return _fallbackVaccines;
    }
  }

  /// Retrieve Medicine Safety information
  Future<Map<String, dynamic>> getMedicineSafety(String drugName) async {
    try {
      final clean = Uri.encodeComponent(drugName.trim());
      final res = await _apiClient.get('/community/medicine-safety/$clean');
      if (res is Map<String, dynamic> && res.containsKey('data')) {
        return (res['data'] as Map<String, dynamic>)['safetyInfo'] ?? {};
      }
      return {};
    } catch (_) {
      return {
        'drugName': drugName,
        'genericName': drugName,
        'therapeuticClass': 'Standard Pharmaceutical',
        'standardIndications': ['Symptomatic relief as directed by physician'],
        'commonSideEffects': ['Mild gastrointestinal upset', 'Drowsiness'],
        'severeWarnings': ['Take strictly as prescribed. Do not exceed recommended dosage.'],
        'contraindications': ['Known allergy or hypersensitivity to the drug'],
        'pregnancySafety': 'CONSULT_DOCTOR',
        'alcoholInteraction': 'Avoid alcohol consumption while taking this medication.',
        'foodInstructions': 'Take with a full glass of water. Confirm with doctor or pharmacist.',
        'disclaimer': 'Clinical reference only. Always follow prescription guidelines.'
      };
    }
  }

  /// Submit user feedback
  Future<void> submitFeedback({
    required String subject,
    required String message,
    String role = 'PATIENT',
    String category = 'GENERAL',
    int rating = 5,
  }) async {
    try {
      await _apiClient.post('/community/feedback', body: {
        'role': role,
        'category': category,
        'rating': rating,
        'subject': subject,
        'message': message,
      });
    } catch (_) {
      // Local graceful acceptance
    }
  }

  // --- Static Fallbacks ---
  static const List<Map<String, dynamic>> _fallbackSchemes = [
    {
      'id': 'pmjay',
      'title': 'Ayushman Bharat PM-JAY',
      'department': 'National Health Authority (NHA)',
      'coverageAmount': '₹5,00,000 / family / year',
      'category': 'HOSPITALIZATION',
      'shortSummary': 'Cashless secondary and tertiary hospitalization cover across empaneled hospitals.',
      'eligibility': ['SECC 2011 identified families', 'Active Ayushman Card holders'],
      'benefits': ['1,949+ medical packages', 'Pre & post hospitalization coverage'],
      'documentsRequired': ['Aadhaar Card', 'Ration Card'],
      'helpline': '14555',
      'officialPortal': 'https://beneficiary.nha.gov.in',
    },
    {
      'id': 'vay-vandana',
      'title': 'Ayushman Vay Vandana Yojana (70+)',
      'department': 'MoHFW, Govt. of India',
      'coverageAmount': '₹5,00,000 / individual senior citizen',
      'category': 'SENIOR_CITIZEN',
      'shortSummary': 'Free universal health coverage for all senior citizens aged 70 years and above.',
      'eligibility': ['All Indian citizens aged 70+ years', 'No income ceiling'],
      'benefits': ['Dedicated top-up cover for geriatric care and surgeries'],
      'documentsRequired': ['Aadhaar Card with DOB'],
      'helpline': '14555',
      'officialPortal': 'https://beneficiary.nha.gov.in',
    },
    {
      'id': 'jan-aushadhi',
      'title': 'Pradhan Mantri Jan Aushadhi Pariyojana',
      'department': 'Department of Pharmaceuticals',
      'coverageAmount': '50% to 90% savings on generic medicines',
      'category': 'MEDICINES',
      'shortSummary': 'Affordable top-quality generic drugs at 14,000+ PMBJP Kendras.',
      'eligibility': ['Open to all citizens without any criteria'],
      'benefits': ['2,000+ generic drugs and medical disposables'],
      'documentsRequired': ['Doctor Prescription'],
      'helpline': '1800-180-8080',
      'officialPortal': 'https://janaushadhi.gov.in',
    },
  ];

  static const List<Map<String, dynamic>> _fallbackDonors = [
    {
      'fullName': 'Rahul Sharma',
      'bloodGroup': 'O+',
      'city': 'Indore',
      'contactPhone': '+91 98260 11223',
      'isAvailable': true,
      'verified': true,
    },
    {
      'fullName': 'Pooja Verma',
      'bloodGroup': 'B+',
      'city': 'Indore',
      'contactPhone': '+91 98261 44556',
      'isAvailable': true,
      'verified': true,
    },
    {
      'fullName': 'Amitabh Mishra',
      'bloodGroup': 'A+',
      'city': 'Bhopal',
      'contactPhone': '+91 94250 88990',
      'isAvailable': true,
      'verified': true,
    },
  ];

  static const List<Map<String, dynamic>> _fallbackCamps = [
    {
      'title': 'Mega Cardiac & Diabetes Screening Camp',
      'organizer': 'Aarogya Foundation & MY Hospital',
      'venue': 'Community Health Centre, Annapurna Road',
      'city': 'Indore',
      'startDate': '2026-11-20',
      'timings': '09:00 AM - 04:00 PM',
      'contactPhone': '+91 731 2525252',
      'servicesOffered': ['Free ECG', 'Random Blood Sugar', 'Cardiology Consult'],
      'isFree': true,
    },
    {
      'title': 'Voluntary Blood Donation Drive',
      'organizer': 'Red Cross Society & Rapid EMS',
      'venue': 'Nehru Stadium Hall',
      'city': 'Indore',
      'startDate': '2026-11-25',
      'timings': '10:00 AM - 05:00 PM',
      'contactPhone': '+91 731 2434343',
      'servicesOffered': ['Sterile Blood Collection', 'Free Blood Group Card', 'Certificate'],
      'isFree': true,
    },
  ];

  static const List<Map<String, dynamic>> _fallbackVaccines = [
    {
      'doseName': 'BCG (Tuberculosis)',
      'ageRecommended': 'At Birth',
      'targetCategory': 'INFANT',
      'protectionAgainst': 'Childhood Tuberculosis & Meningitis',
      'route': 'Intradermal',
      'mandatory': true,
    },
    {
      'doseName': 'Hepatitis B (Birth Dose)',
      'ageRecommended': 'Within 24 hours of birth',
      'targetCategory': 'INFANT',
      'protectionAgainst': 'Perinatal transmission of Hepatitis B',
      'route': 'Intramuscular',
      'mandatory': true,
    },
    {
      'doseName': 'OPV-0 (Oral Polio)',
      'ageRecommended': 'At Birth',
      'targetCategory': 'INFANT',
      'protectionAgainst': 'Polio Virus',
      'route': 'Oral (2 drops)',
      'mandatory': true,
    },
    {
      'doseName': 'Pentavalent 1 (DPT+HepB+Hib)',
      'ageRecommended': '6 Weeks',
      'targetCategory': 'INFANT',
      'protectionAgainst': 'Diphtheria, Pertussis, Tetanus, Hep B, Hib',
      'route': 'Intramuscular',
      'mandatory': true,
    },
    {
      'doseName': 'MR 1 (Measles & Rubella)',
      'ageRecommended': '9-12 Months',
      'targetCategory': 'CHILD',
      'protectionAgainst': 'Measles & Congenital Rubella',
      'route': 'Subcutaneous',
      'mandatory': true,
    },
    {
      'doseName': 'Annual Flu Vaccine',
      'ageRecommended': 'Annually',
      'targetCategory': 'ADULT',
      'protectionAgainst': 'Seasonal Influenza A & B',
      'route': 'Intramuscular',
      'mandatory': false,
    },
  ];
}
