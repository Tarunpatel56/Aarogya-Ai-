export interface GovernmentScheme {
  id: string;
  title: string;
  department: string;
  coverageAmount: string;
  category: 'HOSPITALIZATION' | 'MEDICINES' | 'MATERNITY' | 'SENIOR_CITIZEN' | 'FINANCIAL_AID';
  shortSummary: string;
  eligibility: string[];
  benefits: string[];
  documentsRequired: string[];
  helpline: string;
  officialPortal: string;
}

export interface BloodDonor {
  id: string;
  fullName: string;
  bloodGroup: string;
  city: string;
  district?: string;
  contactPhone: string;
  lastDonatedDate?: string;
  isAvailable: boolean;
  verified: boolean;
  createdAt: string;
}

export interface HealthCamp {
  id: string;
  title: string;
  organizer: string;
  category: 'GENERAL_CHECKUP' | 'BLOOD_DONATION' | 'EYE_SCREENING' | 'DIABETES' | 'PEDIATRIC';
  venue: string;
  city: string;
  startDate: string;
  endDate?: string;
  timings: string;
  servicesOffered: string[];
  contactPhone: string;
  isFree: boolean;
}

export interface VaccineDose {
  id: string;
  doseName: string;
  ageRecommended: string;
  targetCategory: 'INFANT' | 'CHILD' | 'ADOLESCENT' | 'ADULT' | 'SENIOR';
  protectionAgainst: string;
  route: string;
  importance: string;
  mandatory: boolean;
}

export interface MedicineSafetyInfo {
  drugName: string;
  genericName: string;
  therapeuticClass: string;
  standardIndications: string[];
  commonSideEffects: string[];
  severeWarnings: string[];
  contraindications: string[];
  pregnancySafety: 'SAFE' | 'CAUTION' | 'CONTRAINDICATED' | 'CONSULT_DOCTOR';
  alcoholInteraction: string;
  foodInstructions: string;
  disclaimer: string;
}

export interface PlatformAnnouncement {
  id: string;
  title: string;
  message: string;
  priority: 'INFO' | 'WARNING' | 'CRITICAL';
  targetRoles: string[];
  publishedBy: string;
  createdAt: string;
  expiresAt?: string;
  isActive: boolean;
}

export interface UserFeedback {
  id: string;
  userId?: string;
  userEmail?: string;
  role: string;
  category: 'BUG' | 'FEATURE_REQUEST' | 'SERVICE_EXPERIENCE' | 'GENERAL';
  rating: number;
  subject: string;
  message: string;
  status: 'PENDING' | 'REVIEWED' | 'RESOLVED';
  createdAt: string;
}

export interface HealthTip {
  id: string;
  category: 'HEART' | 'NUTRITION' | 'MENTAL_HEALTH' | 'FITNESS' | 'IMMUNITY';
  title: string;
  tip: string;
  actionableStep: string;
  author: string;
}

class CommunityService {
  private schemes: GovernmentScheme[] = [
    {
      id: 'pmjay',
      title: 'Ayushman Bharat PM-JAY (Pradhan Mantri Jan Arogya Yojana)',
      department: 'National Health Authority (NHA), Ministry of Health & Family Welfare',
      coverageAmount: '₹5,00,000 per family per year',
      category: 'HOSPITALIZATION',
      shortSummary: 'World’s largest government-funded healthcare assurance scheme offering secondary and tertiary hospitalization cover.',
      eligibility: [
        'Families listed in SECC 2011 deprived rural and identified occupational urban categories',
        'Active Ayushman Card / Golden Card holders',
        'No limitation on family size, age, or gender',
        'Pre-existing conditions covered from day one'
      ],
      benefits: [
        'Cashless and paperless access to medical services at empaneled hospitals across India',
        '1,949+ medical procedures including oncology, cardiology, neurosurgery, and joint replacements',
        'Covers 3 days of pre-hospitalization and 15 days of post-hospitalization expenses',
        'Diagnostics, medicines, ICU charges, and food services included'
      ],
      documentsRequired: [
        'Aadhaar Card or ABHA ID',
        'Ration Card / Family ID',
        'Active mobile number'
      ],
      helpline: '14555 / 1800-111-565',
      officialPortal: 'https://beneficiary.nha.gov.in',
    },
    {
      id: 'vay-vandana',
      title: 'Ayushman Vay Vandana Yojana (Senior Citizens 70+)',
      department: 'Ministry of Health & Family Welfare, Govt. of India',
      coverageAmount: '₹5,00,000 per individual senior citizen per year',
      category: 'SENIOR_CITIZEN',
      shortSummary: 'Universal health coverage extension for all senior citizens aged 70 and above, regardless of family income or economic status.',
      eligibility: [
        'Any Indian citizen aged 70 years and older (based on Aadhaar age)',
        'No income ceiling or wealth criteria',
        'Standalone card even if family is already enrolled under PM-JAY'
      ],
      benefits: [
        'Exclusive top-up ₹5 Lakh cover dedicated exclusively to the senior citizen',
        'Cashless coverage at 29,000+ empaneled public and private hospitals across India',
        'Coverage for geriatric conditions, chronic joint replacements, bypass surgeries, and dialysis'
      ],
      documentsRequired: [
        'Aadhaar Card with verified Date of Birth',
        'Active mobile number linked to Aadhaar'
      ],
      helpline: '14555',
      officialPortal: 'https://beneficiary.nha.gov.in',
    },
    {
      id: 'jan-aushadhi',
      title: 'Pradhan Mantri Bhartiya Janaushadhi Pariyojana (PMBJP)',
      department: 'Department of Pharmaceuticals, Ministry of Chemicals & Fertilizers',
      coverageAmount: '50% to 90% subsidy on retail pharmacy pricing',
      category: 'MEDICINES',
      shortSummary: 'Making high-quality generic medicines accessible to all citizens through dedicated PMBJP Kendras.',
      eligibility: [
        'Open to every Indian citizen without any income or residency restrictions',
        'Valid doctor prescription required for scheduled drugs'
      ],
      benefits: [
        'Over 2,047 generic medicines and 300 surgical items at 50-90% lower price than branded drugs',
        'All medicines tested in NABL-accredited laboratories for potency and safety',
        'Over 14,000 PMBJP Kendras operating in every district across the country'
      ],
      documentsRequired: [
        'Doctor Prescription'
      ],
      helpline: '1800-180-8080',
      officialPortal: 'https://janaushadhi.gov.in',
    },
    {
      id: 'pmsma',
      title: 'Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA)',
      department: 'Maternal Health Division, MoHFW',
      coverageAmount: '100% Free specialist antenatal care & diagnostics',
      category: 'MATERNITY',
      shortSummary: 'Guaranteed, comprehensive antenatal checkups on the 9th of every month for pregnant women.',
      eligibility: [
        'All pregnant women in their 2nd and 3rd trimesters across rural and urban India'
      ],
      benefits: [
        'Free consultations by OB-GYN specialists and medical officers',
        'Free blood tests, ultrasound scans, glucose checks, and hemoglobin tests',
        'Identification of High-Risk Pregnancies (HRP) with color-coded stickers on Mother-Child Cards',
        'Free iron, folic acid, calcium supplements, and emergency obstetric counseling'
      ],
      documentsRequired: [
        'Mother-Child Protection (MCP) Card / RCH ID',
        'Aadhaar or Government ID'
      ],
      helpline: '1800-180-1104',
      officialPortal: 'https://pmsma.mohfw.gov.in',
    },
    {
      id: 'ran',
      title: 'Rashtriya Arogya Nidhi (RAN)',
      department: 'Ministry of Health & Family Welfare, Govt. of India',
      coverageAmount: 'Up to ₹15,00,000 one-time financial grant',
      category: 'FINANCIAL_AID',
      shortSummary: 'Financial assistance for poor patients suffering from major life-threatening diseases for treatment at super-speciality government hospitals.',
      eligibility: [
        'Patients living below state poverty line (BPL)',
        'Treatment undergoing at 27 recognized apex government institutes (AIIMS, PGI, NIMHANS, etc.)',
        'Not eligible if already covered under PM-JAY or other medical claims'
      ],
      benefits: [
        'Revolving fund for prompt emergency interventions, organ transplants, and cancer therapies',
        'Direct disbursement to the treating government super-specialty hospital'
      ],
      documentsRequired: [
        'Income Certificate / BPL Ration Card',
        'Clinical estimate certificate signed by Medical Superintendent',
        'Application Form countersigned by Head of Department'
      ],
      helpline: '011-23061323',
      officialPortal: 'https://main.mohfw.gov.in/ran',
    },
  ];

  private bloodDonors: BloodDonor[] = [
    {
      id: 'bd-1',
      fullName: 'Rahul Sharma',
      bloodGroup: 'O+',
      city: 'Indore',
      district: 'Indore',
      contactPhone: '+91 98260 11223',
      lastDonatedDate: '2026-08-15',
      isAvailable: true,
      verified: true,
      createdAt: '2026-09-01T10:00:00Z',
    },
    {
      id: 'bd-2',
      fullName: 'Pooja Verma',
      bloodGroup: 'B+',
      city: 'Indore',
      district: 'Indore',
      contactPhone: '+91 98261 44556',
      lastDonatedDate: '2026-07-20',
      isAvailable: true,
      verified: true,
      createdAt: '2026-08-10T14:30:00Z',
    },
    {
      id: 'bd-3',
      fullName: 'Amitabh Mishra',
      bloodGroup: 'A+',
      city: 'Bhopal',
      district: 'Bhopal',
      contactPhone: '+91 94250 88990',
      lastDonatedDate: '2026-06-11',
      isAvailable: true,
      verified: true,
      createdAt: '2026-07-05T09:15:00Z',
    },
    {
      id: 'bd-4',
      fullName: 'Sunil Rathore',
      bloodGroup: 'AB+',
      city: 'Indore',
      district: 'Indore',
      contactPhone: '+91 97555 33441',
      lastDonatedDate: '2026-09-01',
      isAvailable: true,
      verified: true,
      createdAt: '2026-09-10T11:00:00Z',
    },
    {
      id: 'bd-5',
      fullName: 'Kavita Joshi',
      bloodGroup: 'O-',
      city: 'Indore',
      district: 'Indore',
      contactPhone: '+91 99933 66778',
      lastDonatedDate: '2026-05-18',
      isAvailable: true,
      verified: true,
      createdAt: '2026-06-01T16:20:00Z',
    },
    {
      id: 'bd-6',
      fullName: 'Vikas Dubey',
      bloodGroup: 'B-',
      city: 'Bhopal',
      district: 'Bhopal',
      contactPhone: '+91 98930 22334',
      lastDonatedDate: '2026-04-12',
      isAvailable: true,
      verified: true,
      createdAt: '2026-05-15T12:00:00Z',
    },
  ];

  private healthCamps: HealthCamp[] = [
    {
      id: 'camp-1',
      title: 'Free Mega Cardiac & Diabetes Health Screening Camp',
      organizer: 'Aarogya Foundation & MY Hospital Clinical Trust',
      category: 'GENERAL_CHECKUP',
      venue: 'Community Health Centre, Annapurna Road',
      city: 'Indore',
      startDate: '2026-11-20',
      endDate: '2026-11-21',
      timings: '09:00 AM - 04:00 PM',
      servicesOffered: [
        'Free 12-lead ECG & Blood Glucose testing',
        'Consultation with Senior Cardiologists',
        'BMI & Hypertension risk profiling',
        'Free generic cardioprotective medicines distribution'
      ],
      contactPhone: '+91 731 2525252',
      isFree: true,
    },
    {
      id: 'camp-2',
      title: 'Voluntary Blood Donation & Platelet Drive',
      organizer: 'Red Cross Society Indore & Aarogya Rapid EMS',
      category: 'BLOOD_DONATION',
      venue: 'Nehru Stadium Hall, Near Residency Area',
      city: 'Indore',
      startDate: '2026-11-25',
      timings: '10:00 AM - 05:00 PM',
      servicesOffered: [
        'Voluntary blood donation collection with sterile bags',
        'Free complete blood count (CBC) & blood group card',
        'Donor donor certificate and emergency blood voucher',
        'Nutritional refreshments & recovery lounge'
      ],
      contactPhone: '+91 731 2434343',
      isFree: true,
    },
    {
      id: 'camp-3',
      title: 'Senior Citizen Cataract & Eye Vision Camp',
      organizer: 'Drishti Foundation in association with District Health Mission',
      category: 'EYE_SCREENING',
      venue: 'Red Cross Hospital Premises, Shivaji Nagar',
      city: 'Bhopal',
      startDate: '2026-11-28',
      timings: '09:30 AM - 03:30 PM',
      servicesOffered: [
        'Slit-lamp examination & refractive vision assessment',
        'Cataract screening with free surgical referral under NPCB',
        'Free reading glasses for eligible senior citizens'
      ],
      contactPhone: '+91 755 2778899',
      isFree: true,
    },
  ];

  private vaccines: VaccineDose[] = [
    {
      id: 'vac-1',
      doseName: 'BCG (Bacillus Calmette-Guérin)',
      ageRecommended: 'At Birth (or up to 1 year)',
      targetCategory: 'INFANT',
      protectionAgainst: 'Tuberculosis (TB) including TB meningitis',
      route: 'Intradermal (Left upper arm)',
      importance: 'Crucial for newborn immune priming against severe pediatric tuberculosis.',
      mandatory: true,
    },
    {
      id: 'vac-2',
      doseName: 'Hepatitis B (Birth Dose)',
      ageRecommended: 'Within 24 hours of birth',
      targetCategory: 'INFANT',
      protectionAgainst: 'Perinatal transmission of Hepatitis B virus',
      route: 'Intramuscular (Anterolateral mid-thigh)',
      importance: 'Prevents chronic liver cirrhosis and neonatal Hepatitis B infection.',
      mandatory: true,
    },
    {
      id: 'vac-3',
      doseName: 'OPV-0 (Oral Polio Vaccine)',
      ageRecommended: 'At Birth',
      targetCategory: 'INFANT',
      protectionAgainst: 'Poliomyelitis (Poliovirus 1 & 3)',
      route: 'Oral (2 drops)',
      importance: 'Maintains national polio-free status and mucosal immunity.',
      mandatory: true,
    },
    {
      id: 'vac-4',
      doseName: 'Pentavalent 1 (DPT + Hep B + Hib)',
      ageRecommended: '6 Weeks',
      targetCategory: 'INFANT',
      protectionAgainst: 'Diphtheria, Pertussis, Tetanus, Hepatitis B, Haemophilus influenzae b',
      route: 'Intramuscular',
      importance: 'Combines 5 vital immunogens into one single sterile shot.',
      mandatory: true,
    },
    {
      id: 'vac-5',
      doseName: 'Rotavirus Vaccine Dose 1',
      ageRecommended: '6 Weeks',
      targetCategory: 'INFANT',
      protectionAgainst: 'Rotavirus severe dehydrating diarrhea',
      route: 'Oral (5 drops)',
      importance: 'Drastically reduces infant mortality from acute gastroenteritis.',
      mandatory: true,
    },
    {
      id: 'vac-6',
      doseName: 'PCV 1 (Pneumococcal Conjugate Vaccine)',
      ageRecommended: '6 Weeks',
      targetCategory: 'INFANT',
      protectionAgainst: 'Streptococcus pneumoniae (Pneumonia, Sepsis, Meningitis)',
      route: 'Intramuscular',
      importance: 'Shields delicate lungs against invasive pneumococcal infections.',
      mandatory: true,
    },
    {
      id: 'vac-7',
      doseName: 'MR Dose 1 (Measles & Rubella)',
      ageRecommended: '9 Completed Months (up to 12 months)',
      targetCategory: 'CHILD',
      protectionAgainst: 'Measles and Congenital Rubella Syndrome',
      route: 'Subcutaneous (Right upper arm)',
      importance: 'Eliminates epidemic measles and protects against childhood blindness/encephalitis.',
      mandatory: true,
    },
    {
      id: 'vac-8',
      doseName: 'DPT Booster 1',
      ageRecommended: '16 to 24 Months',
      targetCategory: 'CHILD',
      protectionAgainst: 'Diphtheria, Whooping Cough, and Tetanus',
      route: 'Intramuscular',
      importance: 'Reinforces waning early childhood antibodies against toxic spasms.',
      mandatory: true,
    },
    {
      id: 'vac-9',
      doseName: 'Td (Tetanus & adult Diphtheria)',
      ageRecommended: '10 Years & 16 Years',
      targetCategory: 'ADOLESCENT',
      protectionAgainst: 'Tetanus and respiratory diphtheria toxoids',
      route: 'Intramuscular',
      importance: 'Sustains protective immunity into teenage and adult years.',
      mandatory: true,
    },
    {
      id: 'vac-10',
      doseName: 'Annual Influenza (Flu) Vaccine',
      ageRecommended: 'Annually (Adults & Seniors 60+)',
      targetCategory: 'ADULT',
      protectionAgainst: 'Seasonal Influenza A & B circulating strains',
      route: 'Intramuscular',
      importance: 'Reduces cardiovascular events and respiratory hospitalizations in senior citizens.',
      mandatory: false,
    },
  ];

  private medicineDatabase: Record<string, MedicineSafetyInfo> = {
    paracetamol: {
      drugName: 'Paracetamol',
      genericName: 'Acetaminophen',
      therapeuticClass: 'Analgesic & Antipyretic',
      standardIndications: ['Mild to moderate pain', 'Fever reduction', 'Headache', 'Myalgia'],
      commonSideEffects: ['Nausea', 'Mild rash', 'Constipation (rare)'],
      severeWarnings: [
        'Maximum daily dose is 4,000 mg (4 grams) in adults. Do not exceed to avoid acute hepatotoxicity.',
        'Avoid taking concurrently with other cough/cold formulations containing acetaminophen.'
      ],
      contraindications: ['Severe active hepatic impairment', 'Severe acute liver failure'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Avoid regular alcohol; concurrent heavy alcohol intake drastically increases liver damage risk.',
      foodInstructions: 'Can be taken with or without food. Taking with water reduces gastric fullness.',
      disclaimer: 'Informational guideline only. Always consult a certified physician for dosage tailored to your weight and medical history.',
    },
    metformin: {
      drugName: 'Metformin',
      genericName: 'Metformin Hydrochloride',
      therapeuticClass: 'Biguanide Antidiabetic Agent',
      standardIndications: ['Type 2 Diabetes Mellitus', 'Polycystic Ovary Syndrome (PCOS insulin resistance)'],
      commonSideEffects: ['Abdominal discomfort', 'Diarrhea', 'Metallic taste', 'Flatulence'],
      severeWarnings: [
        'Rare but severe risk of Lactic Acidosis in patients with renal impairment (eGFR < 30 mL/min).',
        'Must be withheld 48 hours prior to IV iodinated contrast radiological procedures.'
      ],
      contraindications: ['Severe renal impairment (eGFR < 30)', 'Acute metabolic acidosis', 'Severe heart failure'],
      pregnancySafety: 'CAUTION',
      alcoholInteraction: 'Potentiates risk of hypoglycemia and lactic acidosis; strictly limit alcohol.',
      foodInstructions: 'Always take with or immediately after meals to minimize gastrointestinal upset.',
      disclaimer: 'Informational guideline only. Maintain regular HbA1c and renal function tests.',
    },
    amoxicillin: {
      drugName: 'Amoxicillin',
      genericName: 'Amoxicillin Trihydrate',
      therapeuticClass: 'Aminopenicillin Antibiotic',
      standardIndications: ['Bacterial respiratory tract infections', 'Otitis media', 'Streptococcal pharyngitis', 'UTIs'],
      commonSideEffects: ['Mild diarrhea', 'Nausea', 'Skin rash'],
      severeWarnings: [
        'Immediate risk of anaphylaxis in individuals with known penicillin or beta-lactam allergies.',
        'Complete the full prescribed course even if symptoms subside to prevent antimicrobial resistance.'
      ],
      contraindications: ['Documented hypersensitivity to penicillin or cephalosporins'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Moderate alcohol does not directly inactivate amoxicillin, but impairs immune recovery.',
      foodInstructions: 'May be taken with or without food. Taking with a light meal improves gastrointestinal tolerance.',
      disclaimer: 'Informational guideline only. Effective only against bacterial, not viral (common cold/flu) infections.',
    },
    atorvastatin: {
      drugName: 'Atorvastatin',
      genericName: 'Atorvastatin Calcium',
      therapeuticClass: 'HMG-CoA Reductase Inhibitor (Statin)',
      standardIndications: ['Hypercholesterolemia', 'Dyslipidemia', 'Cardiovascular event risk reduction in coronary disease'],
      commonSideEffects: ['Mild myalgia', 'Arthralgia', 'Mild elevation in transaminases'],
      severeWarnings: [
        'Report unexplained muscle pain, tenderness, or weakness immediately (risk of rhabdomyolysis).',
        'Periodic liver enzymes (ALT/AST) monitoring recommended.'
      ],
      contraindications: ['Active liver disease', 'Unexplained persistent liver enzyme elevations', 'Pregnancy & breastfeeding'],
      pregnancySafety: 'CONTRAINDICATED',
      alcoholInteraction: 'Chronic alcohol consumption increases the risk of hepatic injury.',
      foodInstructions: 'Take once daily at any time of day, with or without food. Avoid large amounts of grapefruit juice.',
      disclaimer: 'Informational guideline only. Do not discontinue without consulting your cardiologist.',
    },
    amlodipine: {
      drugName: 'Amlodipine',
      genericName: 'Amlodipine Besylate',
      therapeuticClass: 'Dihydropyridine Calcium Channel Blocker',
      standardIndications: ['Essential Hypertension', 'Chronic Stable Angina', 'Vasospastic Angina'],
      commonSideEffects: ['Peripheral edema (ankle swelling)', 'Flushing', 'Dizziness', 'Headache'],
      severeWarnings: [
        'Sudden cessation can precipitate rebound severe hypertension.',
        'May cause symptomatic hypotension in volume-depleted patients.'
      ],
      contraindications: ['Severe aortic stenosis', 'Cardiogenic shock', 'Severe hypotension (SBP < 90 mmHg)'],
      pregnancySafety: 'CAUTION',
      alcoholInteraction: 'Additive vasodilatory effects may trigger dizziness, lightheadedness, or postural syncope.',
      foodInstructions: 'Take at the same time each day, with or without meals.',
      disclaimer: 'Informational guideline only. Monitor resting blood pressure routinely.',
    },
  };

  private announcements: PlatformAnnouncement[] = [
    {
      id: 'ann-1',
      title: 'Free National Immunization & Booster Drive Launched',
      message: 'Universal immunization boosters are now accessible at all Aarogya empaneled clinics with automated ABHA EHR sync.',
      priority: 'INFO',
      targetRoles: ['PATIENT', 'DOCTOR', 'DRIVER'],
      publishedBy: 'Super Admin Medical Board',
      createdAt: new Date().toISOString(),
      isActive: true,
    },
    {
      id: 'ann-2',
      title: 'Monsoon Dengue & Vector-Borne Advisory',
      message: 'Platelet counts and rapid diagnostic tests are available with zero wait times at community diagnostic hubs.',
      priority: 'WARNING',
      targetRoles: ['PATIENT'],
      publishedBy: 'Aarogya Compliance Desk',
      createdAt: new Date(Date.now() - 86400000).toISOString(),
      isActive: true,
    },
  ];

  private feedbackList: UserFeedback[] = [
    {
      id: 'fb-1',
      role: 'PATIENT',
      userEmail: 'patient@aarogya.in',
      category: 'SERVICE_EXPERIENCE',
      rating: 5,
      subject: 'Rapid SOS ambulance dispatch was under 7 minutes',
      message: 'The paramedic reached fast and the vitals were synchronized to the hospital prior to our arrival. Exceptional system.',
      status: 'RESOLVED',
      createdAt: new Date(Date.now() - 172800000).toISOString(),
    },
  ];

  private healthTips: HealthTip[] = [
    {
      id: 'tip-1',
      category: 'HEART',
      title: 'Optimal Resting Heart Rate Care',
      tip: 'A normal resting heart rate for adults ranges between 60 to 100 beats per minute. Consistent brisk walking for 30 minutes lowers resting cardiac load.',
      actionableStep: 'Target 150 minutes of moderate aerobic activity per week.',
      author: 'Dr. Aarogya Cardiology Desk',
    },
    {
      id: 'tip-2',
      category: 'NUTRITION',
      title: 'Hydration & Renal Electrolyte Balance',
      tip: 'Adequate hydration supports kidney filtration, regulates core body temperature, and prevents urinary tract micro-calcifications.',
      actionableStep: 'Drink 2.5 to 3 liters of water evenly spaced throughout the daytime.',
      author: 'Aarogya Clinical Nutrition Team',
    },
    {
      id: 'tip-3',
      category: 'MENTAL_HEALTH',
      title: 'Circadian Sleep Hygiene',
      tip: 'Limiting high-intensity blue light exposure 60 minutes prior to sleep boosts natural melatonin synthesis, improving deep restorative REM cycles.',
      actionableStep: 'Keep bedroom temperature cool and maintain fixed sleep-wake times.',
      author: 'Neuro-Wellness Wing',
    },
    {
      id: 'tip-4',
      category: 'FITNESS',
      title: 'Joint Mobility & Posture Maintenance',
      tip: 'Sedentary desk work leads to hip flexor tightness and thoracic kyphosis. Brief 2-minute mobility breaks restore spinal disc hydration.',
      actionableStep: 'Perform standing pelvic tilts and thoracic extensions every 60 minutes.',
      author: 'Aarogya Physiotherapy Department',
    },
  ];

  // Government Schemes
  getSchemes(category?: string): GovernmentScheme[] {
    if (!category || category === 'ALL') return this.schemes;
    return this.schemes.filter((s) => s.category.toUpperCase() === category.toUpperCase());
  }

  getSchemeById(id: string): GovernmentScheme | undefined {
    return this.schemes.find((s) => s.id === id);
  }

  // Blood Donors
  getBloodDonors(bloodGroup?: string, city?: string): BloodDonor[] {
    return this.bloodDonors.filter((d) => {
      let match = true;
      if (bloodGroup && bloodGroup.trim().length > 0 && bloodGroup !== 'ALL') {
        match = match && d.bloodGroup.toUpperCase() === bloodGroup.trim().toUpperCase();
      }
      if (city && city.trim().length > 0) {
        match = match && d.city.toLowerCase().includes(city.trim().toLowerCase());
      }
      return match;
    });
  }

  registerBloodDonor(data: Omit<BloodDonor, 'id' | 'createdAt' | 'verified'>): BloodDonor {
    const newDonor: BloodDonor = {
      id: `bd-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
      verified: true,
      createdAt: new Date().toISOString(),
    };
    this.bloodDonors.unshift(newDonor);
    return newDonor;
  }

  // Health Camps
  getHealthCamps(city?: string, category?: string): HealthCamp[] {
    return this.healthCamps.filter((c) => {
      let match = true;
      if (city && city.trim().length > 0) {
        match = match && c.city.toLowerCase().includes(city.trim().toLowerCase());
      }
      if (category && category !== 'ALL') {
        match = match && c.category.toUpperCase() === category.toUpperCase();
      }
      return match;
    });
  }

  createHealthCamp(data: Omit<HealthCamp, 'id'>): HealthCamp {
    const newCamp: HealthCamp = {
      id: `camp-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
    };
    this.healthCamps.unshift(newCamp);
    return newCamp;
  }

  // Vaccines
  getVaccines(targetCategory?: string): VaccineDose[] {
    if (!targetCategory || targetCategory === 'ALL') return this.vaccines;
    return this.vaccines.filter((v) => v.targetCategory.toUpperCase() === targetCategory.toUpperCase());
  }

  // Medicine Safety
  getMedicineSafety(drugQuery: string): MedicineSafetyInfo {
    const cleanQuery = drugQuery.trim().toLowerCase();
    const exactKey = Object.keys(this.medicineDatabase).find(
      (k) => cleanQuery.includes(k) || k.includes(cleanQuery)
    );

    if (exactKey) {
      return this.medicineDatabase[exactKey];
    }

    // Default intelligent clinical safety advisory for queried chemical
    const capitalized = drugQuery.charAt(0).toUpperCase() + drugQuery.slice(1);
    return {
      drugName: capitalized,
      genericName: capitalized,
      therapeuticClass: 'General Pharmaceutical Formulation',
      standardIndications: [
        `Prescription indicated clinical management with ${capitalized}`,
        'Symptom alleviation under medical direction'
      ],
      commonSideEffects: ['Mild nausea', 'Drowsiness or dizziness', 'Dry mouth', 'Mild gastrointestinal discomfort'],
      severeWarnings: [
        'Do not exceed the dosage explicitly recommended by your registered doctor.',
        'Immediately seek emergency medical attention if you experience breathing difficulty, facial swelling, or severe urticaria.'
      ],
      contraindications: ['Known hypersensitivity to this active chemical compound or related drug classes'],
      pregnancySafety: 'CONSULT_DOCTOR',
      alcoholInteraction: 'Caution is strongly advised. Alcohol can amplify central nervous system depression and alter hepatic drug clearance.',
      foodInstructions: 'Consume with a full glass of water. Consult your pharmacist regarding whether to take before or after meals.',
      disclaimer: 'Informational guideline only. Always verify interactions and contraindications with your treating physician or licensed pharmacist.',
    };
  }

  // Announcements
  getAnnouncements(role?: string): PlatformAnnouncement[] {
    return this.announcements.filter((a) => {
      if (!a.isActive) return false;
      if (!role || role === 'ALL') return true;
      return a.targetRoles.includes(role.toUpperCase()) || a.targetRoles.includes('ALL');
    });
  }

  createAnnouncement(data: Omit<PlatformAnnouncement, 'id' | 'createdAt' | 'isActive'>): PlatformAnnouncement {
    const newAnn: PlatformAnnouncement = {
      id: `ann-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
      isActive: true,
      createdAt: new Date().toISOString(),
    };
    this.announcements.unshift(newAnn);
    return newAnn;
  }

  // Feedback
  submitFeedback(data: Omit<UserFeedback, 'id' | 'createdAt' | 'status'>): UserFeedback {
    const newFb: UserFeedback = {
      id: `fb-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
      status: 'PENDING',
      createdAt: new Date().toISOString(),
    };
    this.feedbackList.unshift(newFb);
    return newFb;
  }

  getFeedbackList(status?: string): UserFeedback[] {
    if (!status || status === 'ALL') return this.feedbackList;
    return this.feedbackList.filter((f) => f.status.toUpperCase() === status.toUpperCase());
  }

  // Health Tips
  getHealthTips(category?: string): HealthTip[] {
    if (!category || category === 'ALL') return this.healthTips;
    return this.healthTips.filter((t) => t.category.toUpperCase() === category.toUpperCase());
  }

  createHealthTip(data: Omit<HealthTip, 'id'>): HealthTip {
    const newTip: HealthTip = {
      id: `tip-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
    };
    this.healthTips.unshift(newTip);
    return newTip;
  }
}

export const communityService = new CommunityService();
