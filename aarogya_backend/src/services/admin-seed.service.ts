import { prisma } from '../config/prisma';
import { passwordService } from './password.service';
import { Role, VerificationStatus } from '@prisma/client';
import { logger } from '../utils/logger';

export async function ensureSuperAdminAndDefaultAccounts(): Promise<void> {
  try {
    // 1. Super Admin
    const adminEmail = 'superadmin@aarogya.ai';
    const adminPasswordHash = await passwordService.hash('Admin@123');

    const admin = await prisma.user.upsert({
      where: { email: adminEmail },
      update: {
        role: Role.PLATFORM_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        passwordHash: adminPasswordHash,
        isActive: true,
      },
      create: {
        email: adminEmail,
        passwordHash: adminPasswordHash,
        role: Role.PLATFORM_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });

    logger.info(`Super Admin account (${admin.email}) ensured & active with PLATFORM_ADMIN role.`);

    // 2. Default Ambulance Drivers
    const drivers = [
      { email: 'driver@aarogya.ai', pass: 'Driver@123', name: 'Lead EMS Driver', veh: 'DL-01-AMB-108' },
      { email: 'vikram@gmail.com', pass: 'Vikram@123', name: 'Vikram Singh (EMS Pilot)', veh: 'MP-09-AMB-999' },
    ];

    for (const d of drivers) {
      const pHash = await passwordService.hash(d.pass);
      const user = await prisma.user.upsert({
        where: { email: d.email },
        update: {
          role: Role.AMBULANCE_DRIVER,
          verificationStatus: VerificationStatus.VERIFIED,
          passwordHash: pHash,
          isActive: true,
        },
        create: {
          email: d.email,
          passwordHash: pHash,
          role: Role.AMBULANCE_DRIVER,
          verificationStatus: VerificationStatus.VERIFIED,
          isActive: true,
        },
      });

      await prisma.ambulanceStaffProfile.upsert({
        where: { userId: user.id },
        update: {
          fullName: d.name,
          staffRole: Role.AMBULANCE_DRIVER,
          licenseNumber: `DL-${d.name.substring(0, 4).toUpperCase()}-01`,
          assignedVehicleNumber: d.veh,
        },
        create: {
          userId: user.id,
          fullName: d.name,
          staffRole: Role.AMBULANCE_DRIVER,
          licenseNumber: `DL-${d.name.substring(0, 4).toUpperCase()}-01`,
          assignedVehicleNumber: d.veh,
        },
      });
      logger.info(`Ambulance Driver (${d.email}) ensured.`);
    }

    // 3. Default Patient Accounts
    const patients = [
      { email: 'krishna@gmail.com', pass: 'Krishna@123', name: 'Krishna Patel' },
      { email: 'tarun@gmail.com', pass: 'Tarun@123', name: 'Tarun Patel' },
      { email: 'tarunpatel0@gmail.com', pass: 'Tarun@123', name: 'Tarun Patel' },
      { email: 'rahul.sharma@aarogya.ai', pass: 'Patient@123', name: 'Rahul Sharma' },
    ];

    for (const p of patients) {
      const pHash = await passwordService.hash(p.pass);
      const user = await prisma.user.upsert({
        where: { email: p.email },
        update: {
          role: Role.PATIENT,
          verificationStatus: VerificationStatus.VERIFIED,
          passwordHash: pHash,
          isActive: true,
        },
        create: {
          email: p.email,
          passwordHash: pHash,
          role: Role.PATIENT,
          verificationStatus: VerificationStatus.VERIFIED,
          isActive: true,
        },
      });

      await prisma.patientProfile.upsert({
        where: { userId: user.id },
        update: {
          fullName: p.name,
          gender: 'MALE',
          bloodGroup: 'B+',
        },
        create: {
          userId: user.id,
          fullName: p.name,
          gender: 'MALE',
          bloodGroup: 'B+',
        },
      });
      logger.info(`Patient (${p.email}) ensured.`);
    }

    // 4. Default Doctor Accounts
    const doctors = [
      { email: 'doctor@aarogya.ai', pass: 'Doctor@123', name: 'Dr. Aarogya Specialist', spec: 'Cardiology', nmc: 'NMC-CARD-101' },
      { email: 'rahul@gmail.com', pass: 'Doctor@123', name: 'Dr. Rahul Sharma', spec: 'General Medicine', nmc: 'NMC-GEN-102' },
      { email: 'ronit@gmail.com', pass: 'Ronit@123', name: 'Dr. Ronit Sharma', spec: 'General Physician & Tele-ICU', nmc: 'NMC-RON-103' },
    ];

    for (const doc of doctors) {
      const pHash = await passwordService.hash(doc.pass);
      const user = await prisma.user.upsert({
        where: { email: doc.email },
        update: {
          role: Role.DOCTOR,
          verificationStatus: VerificationStatus.VERIFIED,
          passwordHash: pHash,
          isActive: true,
        },
        create: {
          email: doc.email,
          passwordHash: pHash,
          role: Role.DOCTOR,
          verificationStatus: VerificationStatus.VERIFIED,
          isActive: true,
        },
      });

      await prisma.doctorProfile.upsert({
        where: { userId: user.id },
        update: {
          fullName: doc.name,
          specialization: doc.spec,
          qualifications: 'MBBS, MD',
          nmcRegistrationNumber: doc.nmc,
          experienceYears: 10,
          consultationFee: 500,
        },
        create: {
          userId: user.id,
          fullName: doc.name,
          specialization: doc.spec,
          qualifications: 'MBBS, MD',
          nmcRegistrationNumber: doc.nmc,
          experienceYears: 10,
          consultationFee: 500,
        },
      });
      logger.info(`Doctor (${doc.email}) ensured.`);
    }

  } catch (err: any) {
    logger.error('Failed to ensure default admin accounts on startup', { error: err.message });
  }
}
