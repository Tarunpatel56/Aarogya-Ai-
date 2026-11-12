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
  category: 'GENERAL_CHECKUP' | 'BLOOD_DONATION' | 'EYE_SCREENING' | 'DIABETES' | 'PEDIATRIC' | 'MATERNITY' | 'IMMUNIZATION';
  sourceType?: 'GOVT_RECURRING' | 'DOCTOR_PARTNER' | 'ADMIN_VERIFIED';
  venue: string;
  city: string;
  startDate: string;
  endDate?: string;
  timings: string;
  servicesOffered: string[];
  contactPhone: string;
  isFree: boolean;
}

export interface BloodSosAlert {
  id: string;
  bloodGroup: string;
  hospitalName: string;
  city: string;
  contactPhone: string;
  unitsNeeded: number;
  notes?: string;
  createdAt: string;
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
  brandAliases?: string[];
  simpleUsesHindi?: string[];
  safeDosageHindi?: string;
  genericSavingsHindi?: string;
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
    {
      id: 'jsy',
      title: 'Janani Suraksha Yojana (JSY)',
      department: 'National Health Mission (NHM), MoHFW',
      coverageAmount: '₹1,400 (Rural) / ₹1,000 (Urban) Direct DBT Cash Benefit',
      category: 'MATERNITY',
      shortSummary: 'Safe motherhood initiative encouraging institutional delivery among pregnant women in BPL/SC/ST households.',
      eligibility: [
        'All pregnant women delivering in government health facilities or accredited clinics',
        'BPL / SC / ST pregnant women across rural and urban India'
      ],
      benefits: [
        'Direct cash assistance transferred via DBT to mother bank account',
        'Free transport to and from hospital under Janani Shishu Suraksha Karyakram (JSSK)',
        'Zero expense delivery, free medications, diet, and newborn care'
      ],
      documentsRequired: [
        'Aadhaar Card',
        'Mother-Child Protection (MCP) Card',
        'Bank Account Passbook / DBT details'
      ],
      helpline: '104 / 1800-180-1104',
      officialPortal: 'https://nhm.gov.in',
    },
    {
      id: 'hmdg',
      title: "Health Minister's Discretionary Grant (HMDG)",
      department: 'Ministry of Health & Family Welfare, Govt. of India',
      coverageAmount: 'Up to ₹1,25,000 direct grant',
      category: 'FINANCIAL_AID',
      shortSummary: 'Emergency financial grant for impoverished patients suffering from major chronic illnesses requiring specialized intervention.',
      eligibility: [
        'Annual family income less than ₹1,25,000',
        'Receiving treatment at government super-speciality hospitals'
      ],
      benefits: [
        'Direct reimbursement for pacemakers, stents, joint prosthesis, and urgent surgery',
        'Disbursed swiftly to hospital medical administration'
      ],
      documentsRequired: [
        'Income Certificate issued by Tehsildar or SDM',
        'Hospital Estimate Certificate signed by HOD',
        'Ration Card / Aadhaar Card'
      ],
      helpline: '011-23061323',
      officialPortal: 'https://main.mohfw.gov.in',
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
      id: 'camp-pmsma',
      title: 'PMSMA Monthly Free Maternal Care & Sonography Camp',
      organizer: 'Ministry of Health & Family Welfare (MoHFW)',
      category: 'MATERNITY',
      sourceType: 'GOVT_RECURRING',
      venue: 'All District Hospitals, CHCs & Civil Hospitals',
      city: 'National (All Cities)',
      startDate: 'Every 9th of Month',
      timings: '09:00 AM - 03:00 PM',
      servicesOffered: [
        'Free comprehensive antenatal checkup by OB-GYN specialists',
        'Free Ultrasound Sonography (USG) & Blood/Urine screening',
        'High-Risk Pregnancy (HRP) red-flag identification & counseling',
        'Free iron, folic acid, and calcium supplements distribution'
      ],
      contactPhone: '1800-180-1104',
      isFree: true,
    },
    {
      id: 'camp-uip',
      title: 'National Universal Immunization & Pulse Polio Drive',
      organizer: 'National Health Mission (NHM) & Anganwadi Network',
      category: 'IMMUNIZATION',
      sourceType: 'GOVT_RECURRING',
      venue: 'Govt Primary Health Centres (PHC) & Anganwadi Booths',
      city: 'National (All Cities)',
      startDate: 'Monthly 1st Sunday & Wednesday',
      timings: '08:00 AM - 04:00 PM',
      servicesOffered: [
        'Free 2 drops Oral Polio Vaccine (OPV) for children under 5',
        'Pentavalent, Rotavirus & Measles-Rubella (MR) immunization',
        'Vitamin A syrup dose and childhood growth chart tracking',
        'Maternal Td booster immunization'
      ],
      contactPhone: '1075',
      isFree: true,
    },
    {
      id: 'camp-1',
      title: 'Free Mega Cardiac & Diabetes Health Screening Camp',
      organizer: 'Aarogya Foundation & MY Hospital Clinical Trust',
      category: 'GENERAL_CHECKUP',
      sourceType: 'DOCTOR_PARTNER',
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
      sourceType: 'ADMIN_VERIFIED',
      venue: 'Nehru Stadium Hall, Near Residency Area',
      city: 'Indore',
      startDate: '2026-11-25',
      timings: '10:00 AM - 05:00 PM',
      servicesOffered: [
        'Voluntary blood donation collection with sterile bags',
        'Free complete blood count (CBC) & blood group card',
        'Donor certificate and emergency blood voucher',
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
      sourceType: 'ADMIN_VERIFIED',
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
      drugName: 'Paracetamol (Crosin / Dolo 650)',
      genericName: 'Acetaminophen / Paracetamol 500mg-650mg',
      therapeuticClass: 'Analgesic & Antipyretic (Bukhar aur Dard Nivarak)',
      brandAliases: ['crosin', 'dolo', 'dolo 650', 'calpol', 'pacimol', 'pyregesic', 'pcm', 'crocin'],
      standardIndications: ['Mild to moderate pain', 'Fever reduction', 'Headache', 'Myalgia'],
      simpleUsesHindi: [
        'Bukhar utarne aur taapman normal karne ke liye (Fever reduction)',
        'Sar dard, badan dard aur daant dard me turant aaram',
        'Thakan aur halka jodon ka dard dur karne me'
      ],
      safeDosageHindi: 'Din me 3 se 4 baar se zyada na lein (4-6 ghante ka antar zaroor rakhein). 24 ghante me 4,000 mg (4 gram) se zyada galti se bhi na lein!',
      genericSavingsHindi: 'PM Jan Aushadhi Kendra par ₹10-₹15 me 10 goli milti hain, jabki branded Dolo/Crosin ₹35-₹50 me aati hai (70%+ bachat)!',
      commonSideEffects: ['Khali pet lene par halki ulti ya acidity', 'Halka pet dard'],
      severeWarnings: [
        '24 ghante me 4 gram (4,000 mg) se zyada dose lene par liver damage ka khatra hota hai.',
        'Kayi cough syrup ya cold tablets me pehle se paracetamol hota hai, unke sath bina check kare na lein.'
      ],
      contraindications: ['Severe active hepatic impairment (Liver ki bimari)', 'Severe acute liver failure'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Sharab (Alcohol) ke sath bilkul na lein; isse liver par behad bura asar pad sakta hai.',
      foodInstructions: 'Khane ke baad ya pehle ek glass taaze paani ke sath le sakte hain.',
      disclaimer: 'Aam bukhar aur dard ke liye surakshit hai. Agar bukhar 3 din se zyada rahe to doctor ko zaroor dikhayein.',
    },
    pantoprazole: {
      drugName: 'Pantoprazole + Domperidone (Pan-D)',
      genericName: 'Pantoprazole 40mg + Domperidone 30mg SR',
      therapeuticClass: 'Proton Pump Inhibitor (PPI) & Prokinetic (Acidity & Gas)',
      brandAliases: ['pan-d', 'pan d', 'pantocid', 'pantop', 'pantop-d', 'pantodac', 'dompan'],
      standardIndications: ['Gastroesophageal Reflux Disease (GERD)', 'Gastric acidity', 'Peptic ulcer disease', 'Nausea associated with acid reflux'],
      simpleUsesHindi: [
        'Seene me tez jalan (Heartburn), acidity aur gas se turant rahat',
        'Khana gale me wapas aana (Acid Reflux) aur khatti dakar rokna',
        'Ulti aur ji michlana theek karna'
      ],
      safeDosageHindi: 'Subah khali pet (nahaar munh) 1 capsule gungune paani ke sath lein, khana khane se 30-45 minute pehle.',
      genericSavingsHindi: 'PM Jan Aushadhi Kendra par ₹25-₹35 me 10 capsule milte hain, jabki branded Pan-D ₹150-₹220 me aati hai (80%+ bachat)!',
      commonSideEffects: ['Halka sar dard', 'Halka dast (diarrhea) ya muh sukhna'],
      severeWarnings: [
        'Lagatar 2-3 hafte se zyada bina doctor ki salah ke na khayein.',
        'Lambe samay tak lene se Calcium aur Vitamin B12 absorption kam ho sakta hai.'
      ],
      contraindications: ['Gastrointestinal hemorrhage or mechanical bowel obstruction'],
      pregnancySafety: 'CAUTION',
      alcoholInteraction: 'Sharab se pet me acid aur jalan badhti hai, isliye dawa ke sath sharab se parhez karein.',
      foodInstructions: 'Subah khana khane se kam se kam 30 minute pehle khali pet lein.',
      disclaimer: 'Acidity me behad asardar hai. Chronic lakshan hone par gastroenterologist se jaanch karayein.',
    },
    combiflam: {
      drugName: 'Combiflam / Flexon',
      genericName: 'Ibuprofen 400mg + Paracetamol 325mg',
      therapeuticClass: 'NSAID & Analgesic (Tez Dard aur Sujan Nivarak)',
      brandAliases: ['combiflam', 'flexon', 'brufen', 'brufen-plus', 'ibuprofen'],
      standardIndications: ['Severe headache', 'Dental pain', 'Musculoskeletal pain', 'Post-traumatic inflammation', 'Arthritis joint pain'],
      simpleUsesHindi: [
        'Tez badan dard, daant dard aur chot lagne par dard me aaram',
        'Jodon me sujan, kamar dard aur moch (sprain) me turant rahat',
        'Tez bukhar aur sharir tootne par asardar'
      ],
      safeDosageHindi: 'Hamesha khana khane ya doodh peene ke BAAD hi lein. Khali pet bilkul na lein (pet me chhale ya ulcer ka khatra hota hai). Din me 2-3 baar se zyada na lein.',
      genericSavingsHindi: 'PM Jan Aushadhi Kendra par Ibuprofen+Paracetamol ₹12-₹18 me 10 goli milti hain, jabki branded ₹45-₹65 me aati hai.',
      commonSideEffects: ['Khali pet lene par pet me jalan aur acidity', 'Halka ji michlana'],
      severeWarnings: [
        'Pet me ulcer ya bleeding ki history wale mareez ise na lein.',
        'Asthma ya kidney ki bimari wale mareez bina doctor ki anumati ke na lein.'
      ],
      contraindications: ['Active peptic ulcer disease', 'Severe renal impairment', 'Aspirin-induced asthma'],
      pregnancySafety: 'CONTRAINDICATED',
      alcoholInteraction: 'Sharab ke sath lene se pet me bleeding aur liver damage ka bada khatra hota hai.',
      foodInstructions: 'Hamesha pet bhar ke khana khane ke baad ek glass paani ke sath hi lein.',
      disclaimer: 'Tez dard ke liye asardar hai par zaroorat padne par hi lein. Aadat na banayein.',
    },
    meftal: {
      drugName: 'Meftal-Spas',
      genericName: 'Mefenamic Acid 250mg + Dicyclomine 10mg',
      therapeuticClass: 'Antispasmodic & NSAID (Pet Dard aur Marod Nivarak)',
      brandAliases: ['meftal-spas', 'meftal spas', 'meftal', 'mefenamic', 'spasmo'],
      standardIndications: ['Menstrual cramps (Dysmenorrhea)', 'Abdominal spasmodic pain', 'Colic pain', 'Ureteric colic'],
      simpleUsesHindi: [
        'Mahilao me mahwari (Periods) ke dauran hone wale asahaniya pet dard me aaram',
        'Pet me tez marod, cramps aur loose motion ke dard me rahat',
        'Kidney stone ya intestine me aithan ka dard dur karne me'
      ],
      safeDosageHindi: 'Jab pet me tez dard ya cramps uthein tab 1 goli lein. Din me 2 se 3 baar se zyada na lein.',
      genericSavingsHindi: 'PM Jan Aushadhi Kendra par Mefenamic+Dicyclomine ₹15-₹22 me 10 goli milti hain (Branded ₹55-₹80).',
      commonSideEffects: ['Muh sukhna', 'Halki susti ya chakkar aana', 'Halki acidity'],
      severeWarnings: [
        'Bina dard ke regular roop se na lein.',
        'Agar pet dard ke sath tez ulti ya khoon aaye to turant hospital jayein.'
      ],
      contraindications: ['Glaucoma', 'Myasthenia gravis', 'Severe obstructive uropathy'],
      pregnancySafety: 'CAUTION',
      alcoholInteraction: 'Sharab ke sath susti aur chakkar badh sakte hain.',
      foodInstructions: 'Khane ke baad ya halka snack lene ke baad paani ke sath lein.',
      disclaimer: 'Periods aur aithan ke dard ke liye prabhavi hai. Jyada din lagatar na lein.',
    },
    azithromycin: {
      drugName: 'Azithromycin (Azithral 500)',
      genericName: 'Azithromycin 500mg',
      therapeuticClass: 'Macrolide Antibiotic (Bacterial Infection Nivarak)',
      brandAliases: ['azithral', 'azithromycin', 'zithrox', 'aziwok', 'azithral 500', 'zady'],
      standardIndications: ['Upper and lower respiratory tract infections', 'Pharyngitis & tonsillitis', 'Community-acquired pneumonia', 'Bacterial skin infections'],
      simpleUsesHindi: [
        'Gale me kharash, tonsils, pakan aur chest infection me rahat',
        'Khansi, balgham aur saans ki nali ka bacterial infection theek karna',
        'Kaan aur skin ke bacterial infection me asardar'
      ],
      safeDosageHindi: 'Din me sirf 1 goli (500mg), nishchit samay par. Lagatar 3 ya 5 din tak doctor ke anusar. Course beech me na chodein!',
      genericSavingsHindi: 'Jan Aushadhi Kendra par 3 goli ₹20-₹28 me milti hain, jabki branded ₹110-₹140 me aati hai (80%+ bachat)!',
      commonSideEffects: ['Halka dast (loose stools)', 'Pet me gudgudahat ya halki ulti'],
      severeWarnings: [
        'Yeh antibiotic hai, sadharan sardi-zukam (viral flu) me kaam nahi karti.',
        'Poora course 3 ya 5 din lena zaroori hai, warna bacteria dawa ke prati dheet ban jate hain (Resistance).'
      ],
      contraindications: ['Known allergy to macrolide antibiotics', 'Severe hepatic dysfunction'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Sharab antibiotic ke asar ko kam karti hai aur dehydration badhati hai.',
      foodInstructions: 'Khana khane se 1 ghanta pehle ya khane ke 2 ghante baad lein.',
      disclaimer: 'Kewal doctor ke prescription par hi lein. Course adhura mat chodiye.',
    },
    cetirizine: {
      drugName: 'Cetirizine (Okacet / Cetzine)',
      genericName: 'Cetirizine Hydrochloride 10mg',
      therapeuticClass: 'Antihistamine (Sardi, Chheenk aur Allergy Nivarak)',
      brandAliases: ['cetirizine', 'okacet', 'cetzine', 'allegra', 'avil', 'zyrtec'],
      standardIndications: ['Allergic rhinitis', 'Seasonal pollinosis', 'Urticaria (hives)', 'Allergic conjunctivitis'],
      simpleUsesHindi: [
        'Baar-baar chheenk aana, naak behna aur sardi-zukam me turant rahat',
        'Aankhon se paani aana, laal hona aur gale me khujli',
        'Shareer par pitti uchhalna (skin rashes) aur khujli theek karna'
      ],
      safeDosageHindi: 'Raat ko sote samay 1 goli (10mg) paani ke sath lein. Din me driving karte waqt lene se bachein kyunki isse neend aati hai.',
      genericSavingsHindi: 'Jan Aushadhi Kendra par 10 goli sirf ₹6-₹10 me milti hain (Branded ₹30-₹50).',
      commonSideEffects: ['Susti aur neend aana (Drowsiness)', 'Muh sukhna', 'Thakan'],
      severeWarnings: [
        'Dawa lene ke baad gaadi chalana ya bhari machinery operate karna avoid karein.',
        'Chhote bachhon ko bina paediatrician ki salah ke na dein.'
      ],
      contraindications: ['End-stage renal disease (CrCl < 10 mL/min)'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Sharab ke sath bilkul na lein – isse behad jyada neend aur chakkar aa sakte hain.',
      foodInstructions: 'Khane ke baad ya pehle le sakte hain. Raat ko lena sabse behtar hota hai.',
      disclaimer: 'Allergy aur sardi me turant aaram deti hai.',
    },
    amoxicillin: {
      drugName: 'Augmentin 625 / Amoxicillin',
      genericName: 'Amoxicillin 500mg + Potassium Clavulanate 125mg',
      therapeuticClass: 'Broad-Spectrum Penicillin Antibiotic',
      brandAliases: ['amoxicillin', 'augmentin', 'moxikind-cv', 'amoxyclav', 'mox'],
      standardIndications: ['Bacterial respiratory tract infections', 'Otitis media', 'Streptococcal pharyngitis', 'UTIs', 'Dental abscess'],
      simpleUsesHindi: [
        'Kaan, naak, gale aur daant ke gehre bacterial infection me',
        'Fefdo me sankraman (Pneumonia, Bronchitis)',
        'Peshaw ki nali (UTI) aur ghav (wound) pakne par asardar'
      ],
      safeDosageHindi: 'Subah aur shaam 1-1 goli khana khane ke baad. Doctor ke nirdharit dino tak poora course karein.',
      genericSavingsHindi: 'Jan Aushadhi Kendra par Amox+Clav ₹60-₹85 me 10 tablet milti hain (Branded ₹200-₹260).',
      commonSideEffects: ['Halka dast (diarrhea)', 'Nausea', 'Skin rash'],
      severeWarnings: [
        'Agar penicillin se allergy ho to turant doctor ko batayein (Anaphylaxis risk).',
        'Adhura course chhodne par sankraman dobara lout sakta hai.'
      ],
      contraindications: ['Documented hypersensitivity to penicillin or cephalosporins'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Sharab peene se body dehydration aur immunity kam hoti hai.',
      foodInstructions: 'Hamesha khana khane ke sath lein taaki pet kharab na ho.',
      disclaimer: 'Antibiotic dawa hai. Kewal certified doctor ke prescription par lein.',
    },
    metformin: {
      drugName: 'Metformin (Glycomet)',
      genericName: 'Metformin Hydrochloride 500mg - 1000mg',
      therapeuticClass: 'Biguanide Antidiabetic Agent (Blood Sugar Control)',
      brandAliases: ['metformin', 'glycomet', 'glyciphage', 'glucophage'],
      standardIndications: ['Type 2 Diabetes Mellitus', 'Polycystic Ovary Syndrome (PCOS insulin resistance)'],
      simpleUsesHindi: [
        'Type 2 Sugar (Diabetes) ke mareezo me blood sugar control karna',
        'Sharir me insulin ki karyakshamta badhana',
        'Mahilao me PCOS me hormonal santulan banana'
      ],
      safeDosageHindi: 'Khana khane ke theek baad ya khane ke sath hi lein. Khali pet lene se pet me marod ho sakti hai.',
      genericSavingsHindi: 'Jan Aushadhi Kendra par 10 goli sirf ₹7-₹12 me milti hain (Branded ₹30-₹60).',
      commonSideEffects: ['Pet me gas', 'Loose motions ya dast', 'Muh me metallic swad'],
      severeWarnings: [
        'Kidney ki bimari wale mareez regular kidney jaanch (eGFR) karayein.',
        'CT Scan ya X-ray jisme contrast dye di jaani ho usse 48 ghante pehle band karein.'
      ],
      contraindications: ['Severe renal impairment (eGFR < 30)', 'Acute metabolic acidosis', 'Severe heart failure'],
      pregnancySafety: 'CAUTION',
      alcoholInteraction: 'Sharab ke sath lactic acidosis aur low sugar (hypoglycemia) ka khatra badhta hai.',
      foodInstructions: 'Hamesha khana khate waqt ya khane ke turant baad lein.',
      disclaimer: 'Niyamit blood sugar aur HbA1c test karwate rahein.',
    },
    ors: {
      drugName: 'Electral / WHO-ORS',
      genericName: 'Oral Rehydration Salts (WHO Formula)',
      therapeuticClass: 'Electrolyte Replenisher (Dehydration Nivarak)',
      brandAliases: ['electral', 'ors', 'oral rehydration', 'enerzal'],
      standardIndications: ['Dehydration due to diarrhea and vomiting', 'Heat exhaustion', 'Electrolyte imbalance'],
      simpleUsesHindi: [
        'Dast (Diarrhea) aur ulti me sharir me paani aur namak ki kami poori karna',
        'Garmi aur dhoop me loo lagne ya chakkhar aane par urja dena',
        'Dehydration se jaan bachana'
      ],
      safeDosageHindi: '1 packet poora 1 litre peene ke saaf paani me gholein. Ghole hue paani ko 24 ghante ke andar piyein.',
      genericSavingsHindi: 'Jan Aushadhi Kendra par ₹10-₹15 me bada packet milta hai (Branded ₹25-₹35).',
      commonSideEffects: ['Koi side effect nahi. Sharir ke liye amrit saman hai.'],
      severeWarnings: [
        'Chhote bachhon ko thoda-thoda karke chammach se pilayein.',
        'Bina paani ki sahi matra ke powder direct na khayein.'
      ],
      contraindications: ['Severe intractable vomiting requiring IV rehydration'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Dehydration me sharab bilkul na piyein.',
      foodInstructions: 'Din bhar thoda-thoda ghoont-ghoont karke piyein.',
      disclaimer: 'Har ghar me emergency ke liye ORS ka packet hamesha hona chahiye.',
    },
    digene: {
      drugName: 'Digene / Gelusil',
      genericName: 'Magnesium + Aluminium Hydroxide + Simethicone',
      therapeuticClass: 'Antacid & Antiflatulent (Instant Acidity & Gas Relief)',
      brandAliases: ['digene', 'gelusil', 'mucaine'],
      standardIndications: ['Hyperacidity', 'Heartburn', 'Flatulence', 'Sour stomach'],
      simpleUsesHindi: [
        'Seene me achanak jalan (Heartburn) hone par 2 minute me thandak',
        'Khana khane ke baad pet phoolna aur gas ke dabav se rahat',
        'Khatti dakar aur pet me acid ka asar kam karna'
      ],
      safeDosageHindi: 'Khana khane ke baad ya jalan hone par 2 chammach syrup piyein ya 2 goli chaba kar khayein.',
      genericSavingsHindi: 'Jan Aushadhi Kendra par ₹40-₹50 me 200ml bottle milti hai (Branded ₹120-₹160).',
      commonSideEffects: ['Adhik lene par halka kabz ya dast'],
      severeWarnings: [
        'Anya dawaon ke sath lene me 1-2 ghante ka antar rakhein taaki absorption na ruke.'
      ],
      contraindications: ['Severe renal failure or hypophosphatemia'],
      pregnancySafety: 'SAFE',
      alcoholInteraction: 'Sharab se pet ki lining chhil sakti hai, isliye sharab avoid karein.',
      foodInstructions: 'Khana khane ke 30 minute baad ya sote waqt lein.',
      disclaimer: 'Aam gas aur jalan me turant rahat milti hai.',
    },
    atorvastatin: {
      drugName: 'Atorvastatin',
      genericName: 'Atorvastatin Calcium',
      therapeuticClass: 'HMG-CoA Reductase Inhibitor (Statin / Cholesterol Control)',
      brandAliases: ['atorvastatin', 'atorva', 'lipitor', 'storvas'],
      standardIndications: ['Hypercholesterolemia', 'Dyslipidemia', 'Cardiovascular event risk reduction'],
      simpleUsesHindi: [
        'Khoon me kharab cholesterol (LDL) aur triglycerides kam karna',
        'Heart attack aur stroke ke khatre ko kam karna',
        'Khoon ki nalion me plaque jamne se rokna'
      ],
      safeDosageHindi: 'Raat ko sote samay 1 goli rozana ek niyamit samay par lein.',
      genericSavingsHindi: 'Jan Aushadhi Kendra par ₹15-₹25 me 10 goli milti hain (Branded ₹90-₹150).',
      commonSideEffects: ['Pindliyon ya manspeshiyon me halka dard (Myalgia)', 'Halka sir dard'],
      severeWarnings: [
        'Bina doctor ke mashware ke dawa achanak band na karein.',
        'Agar manspeshiyon me achanak asahaniya dard ho to turant doctor ko batayein.'
      ],
      contraindications: ['Active liver disease', 'Pregnancy & breastfeeding'],
      pregnancySafety: 'CONTRAINDICATED',
      alcoholInteraction: 'Sharab cholesterol badhati hai aur liver par dabaav badhati hai.',
      foodInstructions: 'Raat ke khane ke baad paani ke sath lein.',
      disclaimer: 'Cardiologist ki salah se niyamit roop se lein.',
    },
    amlodipine: {
      drugName: 'Amlodipine / Telmisartan',
      genericName: 'Amlodipine 5mg / Telmisartan 40mg',
      therapeuticClass: 'Antihypertensive (Blood Pressure Control)',
      brandAliases: ['amlodipine', 'amlong', 'telma', 'telmisartan', 'stamlo'],
      standardIndications: ['Essential Hypertension', 'Chronic Stable Angina', 'Cardiovascular risk management'],
      simpleUsesHindi: [
        'High Blood Pressure (BP) ko normal range me rakhna',
        'Dil par dabaav kam karna aur dil ki bimari se bachana',
        'Seene ke dard (Angina) me rahat'
      ],
      safeDosageHindi: 'Roz subah naste ke baad 1 goli fix time par lein. Kabhi bhi goli miss na karein.',
      genericSavingsHindi: 'Jan Aushadhi Kendra par ₹8-₹14 me 10 goli milti hain (Branded ₹60-₹110).',
      commonSideEffects: ['Pairon ke takhno me halki sujan (Ankle swelling)', 'Halka chakkar aana'],
      severeWarnings: [
        'Achanak dawa band karne se BP tezi se badh sakta hai.',
        'Rozana ghar par BP monitor karein aur record rakhein.'
      ],
      contraindications: ['Severe aortic stenosis', 'Cardiogenic shock', 'Severe hypotension'],
      pregnancySafety: 'CAUTION',
      alcoholInteraction: 'Sharab BP ko aniyantrit karti hai, isliye sharab se bachein.',
      foodInstructions: 'Roz subah ek hi samay par paani ke sath lein.',
      disclaimer: 'High BP me niyamit dawa aur kam namak khana zaroori hai.',
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

  private bloodSosRequests: BloodSosAlert[] = [];

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

  createBloodSosRequest(data: Omit<BloodSosAlert, 'id' | 'createdAt'>): BloodSosAlert {
    const alert: BloodSosAlert = {
      id: `sos-blood-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      ...data,
      createdAt: new Date().toISOString(),
    };
    this.bloodSosRequests.unshift(alert);
    return alert;
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
    const cleanQuery = drugQuery.trim().toLowerCase().replace(/[^a-z0-9]/g, '');

    // 1. Direct key match or alias match
    for (const [key, info] of Object.entries(this.medicineDatabase)) {
      const cleanKey = key.toLowerCase().replace(/[^a-z0-9]/g, '');
      if (cleanQuery.includes(cleanKey) || cleanKey.includes(cleanQuery)) {
        return info;
      }
      if (info.brandAliases && info.brandAliases.some(alias => {
        const cleanAlias = alias.toLowerCase().replace(/[^a-z0-9]/g, '');
        return cleanQuery.includes(cleanAlias) || cleanAlias.includes(cleanQuery);
      })) {
        return info;
      }
    }

    // Default intelligent clinical safety advisory for queried medicine
    const capitalized = drugQuery.charAt(0).toUpperCase() + drugQuery.slice(1);
    return {
      drugName: capitalized,
      genericName: capitalized,
      therapeuticClass: 'General Pharmaceutical Formulation',
      standardIndications: [
        `Prescription indicated clinical management with ${capitalized}`,
        'Symptom alleviation under medical direction'
      ],
      simpleUsesHindi: [
        `${capitalized} doctor dwara batayi gayi bimari ke upchar ke liye li jaati hai`,
        'Bimari ke lakshano aur asuvidha me rahat ke liye'
      ],
      safeDosageHindi: 'Doctor ya pharmacist dwara bataye anusaar niyamit samay par lein. Apne man se dose kam ya zyada na karein.',
      genericSavingsHindi: 'PM Jan Aushadhi Kendra par iski generic dawa 50% se 80% saste daamo me uplabdh ho sakti hai.',
      commonSideEffects: ['Halki ulti ya ji michlana', 'Halka sar dard ya susti (drowsiness)', 'Pet me halki gas'],
      severeWarnings: [
        'Doctor dwara nirdharit dose se zyada galti se bhi na lein.',
        'Agar saans lene me takleef ya allergy ke lakshan dikhein to turant doctor se milein.'
      ],
      contraindications: ['Is dawa se ya kisi anya dawa se allergy hone par na lein'],
      pregnancySafety: 'CONSULT_DOCTOR',
      alcoholInteraction: 'Is dawa ke chalte sharab (alcohol) ka sevan bilkul na karein.',
      foodInstructions: 'Ek glass taaze paani ke sath lein. Doctor se zaroor poochein ki khana khane ke pehle ya baad me lena hai.',
      disclaimer: 'Yeh jankari sirf aapki suvidha ke liye hai. Koi bhi nayi dawa lene se pehle doctor se zaroor salah lein.'
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

