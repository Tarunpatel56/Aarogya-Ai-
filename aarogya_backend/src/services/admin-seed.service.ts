import { prisma } from '../config/prisma';
import { passwordService } from './password.service';
import { Role, VerificationStatus } from '@prisma/client';
import { logger } from '../utils/logger';

export async function ensureSuperAdminAndDefaultAccounts(): Promise<void> {
  try {
    // 1. Super Admin (System Bootstrap Account)
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
  } catch (err: any) {
    logger.error('Failed to ensure default admin accounts on startup', { error: err.message });
  }
}
