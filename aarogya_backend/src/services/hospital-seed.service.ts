import { prisma } from '../config/prisma';
import { logger } from '../utils/logger';

export const VERIFIED_HOSPITALS_SEED = [
  {
    name: 'AIIMS (All India Institute of Medical Sciences)',
    licenseNumber: 'DL-HOSP-AIIMS-001',
    address: 'Sri Aurobindo Marg, Ansari Nagar East',
    city: 'New Delhi',
    state: 'Delhi',
    latitude: 28.5672,
    longitude: 77.2100,
    contactPhone: '+91-11-26588500',
    emergencyPhone: '102',
    availableIcuBeds: 24,
    totalIcuBeds: 120,
    availableNormalBeds: 145,
    totalNormalBeds: 850,
    hasEmergencyBay: true,
    hasTraumaCenter: true,
    verifiedAt: new Date(),
  },
  {
    name: 'Safdarjung Hospital & Vardhman Mahavir Medical College',
    licenseNumber: 'DL-HOSP-SJH-002',
    address: 'Ring Road, Opposite AIIMS, Safdarjung Enclave',
    city: 'New Delhi',
    state: 'Delhi',
    latitude: 28.5701,
    longitude: 77.2081,
    contactPhone: '+91-11-26165060',
    emergencyPhone: '102',
    availableIcuBeds: 18,
    totalIcuBeds: 90,
    availableNormalBeds: 92,
    totalNormalBeds: 600,
    hasEmergencyBay: true,
    hasTraumaCenter: true,
    verifiedAt: new Date(),
  },
  {
    name: 'Max Super Speciality Hospital, Saket',
    licenseNumber: 'DL-HOSP-MAX-003',
    address: '1, 2, Press Enclave Marg, Saket',
    city: 'New Delhi',
    state: 'Delhi',
    latitude: 28.5284,
    longitude: 77.2120,
    contactPhone: '+91-11-26515050',
    emergencyPhone: '+91-11-40554055',
    availableIcuBeds: 14,
    totalIcuBeds: 65,
    availableNormalBeds: 76,
    totalNormalBeds: 320,
    hasEmergencyBay: true,
    hasTraumaCenter: true,
    verifiedAt: new Date(),
  },
  {
    name: 'Indraprastha Apollo Hospital',
    licenseNumber: 'DL-HOSP-APOLLO-004',
    address: 'Delhi-Mathura Road, Sarita Vihar',
    city: 'New Delhi',
    state: 'Delhi',
    latitude: 28.5363,
    longitude: 77.2882,
    contactPhone: '+91-11-26925858',
    emergencyPhone: '1066',
    availableIcuBeds: 20,
    totalIcuBeds: 85,
    availableNormalBeds: 110,
    totalNormalBeds: 450,
    hasEmergencyBay: true,
    hasTraumaCenter: true,
    verifiedAt: new Date(),
  },
  {
    name: 'Fortis Escorts Heart Institute',
    licenseNumber: 'DL-HOSP-FORTIS-005',
    address: 'Okhla Road, Sukhdev Vihar, New Friends Colony',
    city: 'New Delhi',
    state: 'Delhi',
    latitude: 28.5606,
    longitude: 77.2774,
    contactPhone: '+91-11-47135000',
    emergencyPhone: '+91-11-47135001',
    availableIcuBeds: 12,
    totalIcuBeds: 50,
    availableNormalBeds: 45,
    totalNormalBeds: 210,
    hasEmergencyBay: true,
    hasTraumaCenter: false,
    verifiedAt: new Date(),
  },
  {
    name: 'Sir Ganga Ram Hospital',
    licenseNumber: 'DL-HOSP-SGRH-006',
    address: 'Sir Ganga Ram Hospital Marg, Old Rajinder Nagar',
    city: 'New Delhi',
    state: 'Delhi',
    latitude: 28.6387,
    longitude: 77.1896,
    contactPhone: '+91-11-42254000',
    emergencyPhone: '+91-11-25861463',
    availableIcuBeds: 16,
    totalIcuBeds: 70,
    availableNormalBeds: 88,
    totalNormalBeds: 380,
    hasEmergencyBay: true,
    hasTraumaCenter: false,
    verifiedAt: new Date(),
  },
];

export async function ensureVerifiedHospitalsSeeded(): Promise<void> {
  try {
    const count = await prisma.hospital.count();
    if (count === 0) {
      logger.info('Populating initial verified hospital facilities...');
      for (const h of VERIFIED_HOSPITALS_SEED) {
        await prisma.hospital.upsert({
          where: { licenseNumber: h.licenseNumber },
          create: h,
          update: h,
        });
      }
      logger.info(`Successfully seeded ${VERIFIED_HOSPITALS_SEED.length} verified hospitals.`);
    }
  } catch (err: any) {
    logger.warn('Hospital seed skipped or already satisfied:', { error: err.message });
  }
}

