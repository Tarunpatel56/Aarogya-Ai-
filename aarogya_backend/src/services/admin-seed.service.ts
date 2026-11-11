import { prisma } from '../config/prisma';
import { passwordService } from './password.service';
import { Role, VerificationStatus } from '@prisma/client';
import { logger } from '../utils/logger';

export async function ensureSuperAdminAndDefaultAccounts(): Promise<void> {
  try {
    const adminEmail = 'superadmin@aarogya.ai';
    const adminPasswordHash = await passwordService.hash('Admin@12345');

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

    // Also ensure default verified ambulance pilot exists
    const driverEmail = 'driver@aarogya.ai';
    const driverPasswordHash = await passwordService.hash('Driver@123');

    const driverUser = await prisma.user.upsert({
      where: { email: driverEmail },
      update: {
        role: Role.AMBULANCE_DRIVER,
        verificationStatus: VerificationStatus.VERIFIED,
        passwordHash: driverPasswordHash,
        isActive: true,
      },
      create: {
        email: driverEmail,
        passwordHash: driverPasswordHash,
        role: Role.AMBULANCE_DRIVER,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });

    await prisma.ambulanceStaffProfile.upsert({
      where: { userId: driverUser.id },
      update: {
        fullName: 'Lead EMS Driver',
        staffRole: Role.AMBULANCE_DRIVER,
        licenseNumber: 'DL-LEAD-01',
        assignedVehicleNumber: 'DL-01-AMB-108',
      },
      create: {
        userId: driverUser.id,
        fullName: 'Lead EMS Driver',
        staffRole: Role.AMBULANCE_DRIVER,
        licenseNumber: 'DL-LEAD-01',
        assignedVehicleNumber: 'DL-01-AMB-108',
      },
    });

    logger.info(`Lead Ambulance Driver (${driverUser.email}) ensured & active.`);
  } catch (err: any) {
    logger.error('Failed to ensure default admin accounts on startup', { error: err.message });
  }
}
