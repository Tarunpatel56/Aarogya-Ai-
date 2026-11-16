import 'package:get/get.dart';

/// Comprehensive on-device dictionary translating dynamic API data,
/// database fields, statuses, specializations and medical terms
/// into pure Hindi (शुद्ध हिंदी) or pure English without any Hinglish.
class ApiDataTranslator {
  static bool get isHindi => Get.locale?.languageCode == 'hi';

  /// Translate Doctor Specializations from API
  static String translateSpecialization(String? spec) {
    if (spec == null || spec.trim().isEmpty) return isHindi ? 'सामान्य चिकित्सा' : 'General Care';
    if (!isHindi) return spec;

    final lower = spec.trim().toLowerCase();
    for (final entry in _specializations.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return spec;
  }

  /// Translate Statuses (Appointments, SOS, Token, Verification) from API
  static String translateStatus(String? status) {
    if (status == null || status.trim().isEmpty) return isHindi ? 'अज्ञात' : 'Unknown';
    if (!isHindi) return _formatEnglishStatus(status);

    final upper = status.trim().toUpperCase();
    return _statuses[upper] ?? status;
  }

  /// Translate Facility Types & Departments
  static String translateFacilityType(String? type) {
    if (type == null || type.trim().isEmpty) return isHindi ? 'स्वास्थ्य केंद्र' : 'Health Facility';
    if (!isHindi) return type;

    final lower = type.trim().toLowerCase();
    for (final entry in _facilities.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return type;
  }

  /// Translate Medical Lab Tests & Radiology
  static String translateMedicalTest(String? test) {
    if (test == null || test.trim().isEmpty) return '';
    if (!isHindi) return test;

    final lower = test.trim().toLowerCase();
    for (final entry in _tests.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return test;
  }

  /// Translate Gender
  static String translateGender(String? gender) {
    if (gender == null || gender.trim().isEmpty) return isHindi ? 'निर्दिष्ट नहीं' : 'Not Specified';
    if (!isHindi) return gender;

    final g = gender.trim().toUpperCase();
    if (g.startsWith('M')) return 'पुरुष';
    if (g.startsWith('F')) return 'महिला';
    return 'अन्य';
  }

  /// Translate Family Relationship
  static String translateRelationship(String? rel) {
    if (rel == null || rel.trim().isEmpty) return isHindi ? 'आश्रित' : 'Dependent';
    if (!isHindi) return rel;

    final r = rel.trim().toLowerCase();
    return _relationships[r] ?? rel;
  }

  /// Translate Availability / Stock Status
  static String translateAvailability(String? avail) {
    if (avail == null) return isHindi ? 'उपलब्ध' : 'Available';
    if (!isHindi) return avail;

    final lower = avail.trim().toLowerCase();
    if (lower.contains('avail') || lower.contains('in stock') || lower.contains('true')) {
      return 'उपलब्ध';
    }
    if (lower.contains('unavail') || lower.contains('out of stock') || lower.contains('false')) {
      return 'अनुपलब्ध';
    }
    return avail;
  }

  /// Translate General dynamic sentence/phrase from API
  static String translateText(String text) {
    if (text.isEmpty || !isHindi) return text;

    var translated = text;
    for (final entry in _commonPhrases.entries) {
      translated = translated.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }
    return translated;
  }

  // --- Internal Dictionaries ---

  static String _formatEnglishStatus(String s) {
    final lower = s.replaceAll('_', ' ').toLowerCase();
    if (lower.isEmpty) return s;
    return lower[0].toUpperCase() + lower.substring(1);
  }

  static const Map<String, String> _specializations = {
    'general physician': 'सामान्य चिकित्सक',
    'general practitioner': 'सामान्य चिकित्सक',
    'general medicine': 'सामान्य चिकित्सा',
    'cardiologist': 'हृदय रोग विशेषज्ञ',
    'cardiology': 'हृदय रोग विशेषज्ञ',
    'dermatologist': 'त्वचा रोग विशेषज्ञ',
    'dermatology': 'त्वचा रोग विशेषज्ञ',
    'orthopedic': 'हड्डी एवं जोड़ विशेषज्ञ',
    'orthopedics': 'हड्डी एवं जोड़ विशेषज्ञ',
    'pediatrician': 'बाल रोग विशेषज्ञ',
    'pediatrics': 'बाल रोग विशेषज्ञ',
    'neurologist': 'तंत्रिका तंत्र विशेषज्ञ',
    'neurology': 'तंत्रिका तंत्र विशेषज्ञ',
    'gynecologist': 'स्त्री एवं प्रसूति रोग विशेषज्ञ',
    'gynecology': 'स्त्री एवं प्रसूति रोग विशेषज्ञ',
    'obstetrics': 'प्रसूति रोग विशेषज्ञ',
    'ophthalmologist': 'नेत्र रोग विशेषज्ञ',
    'ophthalmology': 'नेत्र रोग विशेषज्ञ',
    'ent': 'नाक-कान-गला विशेषज्ञ',
    'otolaryngology': 'नाक-कान-गला विशेषज्ञ',
    'psychiatrist': 'मनोचिकित्सक',
    'psychiatry': 'मनोचिकित्सा',
    'dentist': 'दंत चिकित्सक',
    'dental': 'दंत चिकित्सा',
    'pulmonologist': 'श्वसन एवं फेफड़ा रोग विशेषज्ञ',
    'pulmonology': 'श्वसन रोग विशेषज्ञ',
    'gastroenterologist': 'पेट एवं पाचन रोग विशेषज्ञ',
    'gastroenterology': 'पाचन रोग विशेषज्ञ',
    'nephrologist': 'गुर्दा रोग विशेषज्ञ',
    'nephrology': 'गुर्दा रोग विशेषज्ञ',
    'endocrinologist': 'मधुमेह एवं हार्मोन विशेषज्ञ',
    'endocrinology': 'हार्मोन विशेषज्ञ',
    'oncologist': 'कैंसर रोग विशेषज्ञ',
    'oncology': 'कैंसर चिकित्सा',
    'physiotherapist': 'फिजियोथेरेपिस्ट',
    'physiotherapy': 'भौतिक चिकित्सा (फिजियोथेरेपी)',
    'radiologist': 'रेडियोलॉजिस्ट (एक्स-रे/एमआरआई)',
    'urologist': 'मूत्र रोग विशेषज्ञ',
  };

  static const Map<String, String> _statuses = {
    'PENDING': 'लंबित',
    'CONFIRMED': 'पुष्ट',
    'COMPLETED': 'पूर्ण',
    'CANCELLED': 'रद्द',
    'SCHEDULED': 'निर्धारित',
    'ACTIVE': 'सक्रिय',
    'INACTIVE': 'निष्क्रिय',
    'DISPATCHED': 'रवाना',
    'EN_ROUTE': 'मार्ग में',
    'IN_TRANSIT': 'मार्ग में',
    'ARRIVED': 'पहुँच गया',
    'VERIFIED': 'सत्यापित',
    'UNVERIFIED': 'असत्यापित',
    'REJECTED': 'अस्वीकृत',
    'IN_PROGRESS': 'प्रगति पर',
    'RESOLVED': 'समाधान हो गया',
    'EXPIRED': 'समाप्त',
    'PAID': 'भुगतान संपन्न',
    'UNPAID': 'अदत्त',
    'OPEN': 'खुला है',
    'CLOSED': 'बंद है',
  };

  static const Map<String, String> _facilities = {
    'district hospital': 'जिला अस्पताल',
    'community health center': 'सामुदायिक स्वास्थ्य केंद्र (सीएचसी)',
    'primary health center': 'प्राथमिक स्वास्थ्य केंद्र (पीएचसी)',
    'civil hospital': 'सिविल अस्पताल',
    'blood bank': 'रक्त बैंक',
    'jan aushadhi': 'जन औषधि केंद्र',
    'pharmacy': 'दवाई की दुकान',
    'clinic': 'चिकित्सालय',
    'hospital': 'अस्पताल',
    'emergency': 'आपातकालीन वार्ड',
    'icu': 'गहन चिकित्सा इकाई (आईसीयू)',
    'opd': 'ओपीडी (बाह्य रोगी विभाग)',
    'ipd': 'आईपीडी (आंतरिक रोगी विभाग)',
  };

  static const Map<String, String> _tests = {
    'complete blood count': 'संपूर्ण रक्त गणना (सीबीसी)',
    'cbc': 'संपूर्ण रक्त गणना (सीबीसी)',
    'lipid profile': 'लिपिड प्रोफाइल (कोलेस्ट्रॉल)',
    'blood sugar': 'रक्त शर्करा (ग्लूकोज)',
    'fasting glucose': 'खाली पेट ग्लूकोज',
    'post prandial': 'भोजनोपरांत ग्लूकोज',
    'hba1c': 'ग्लाइकोसिलेटेड हीमोग्लोबिन (HbA1c)',
    'chest x-ray': 'छाती का एक्स-रे',
    'x-ray': 'एक्स-रे',
    'brain mri': 'मस्तिष्क एमआरआई',
    'mri': 'एमआरआई',
    'ecg': 'इलेक्ट्रोकार्डियोग्राम (ईसीजी)',
    'ultrasound': 'अल्ट्रासाउंड सोनोग्राफी',
    'lft': 'यकृत कार्य परीक्षण (एलएफटी)',
    'kft': 'गुर्दा कार्य परीक्षण (केएफटी)',
    'thyroid': 'थायराइड परीक्षण',
  };

  static const Map<String, String> _relationships = {
    'father': 'पिता',
    'mother': 'माता',
    'spouse': 'जीवनसाथी',
    'husband': 'पति',
    'wife': 'पत्नी',
    'son': 'पुत्र',
    'daughter': 'पुत्री',
    'child': 'बच्चा',
    'brother': 'भाई',
    'sister': 'बहन',
    'self': 'स्वयं',
    'other': 'अन्य',
  };

  static const Map<String, String> _commonPhrases = {
    'no upcoming appointments': 'कोई आगामी अपॉइंटमेंट नहीं है',
    'tap to book': 'परामर्श बुक करने हेतु स्पर्श करें',
    'emergency alert': 'आपातकालीन चेतावनी',
    'ambulance on the way': 'एम्बुलेंस मार्ग में है',
    'verified profile': 'सत्यापित प्रोफ़ाइल',
    'all rights reserved': 'सर्वाधिकार सुरक्षित',
  };
}
