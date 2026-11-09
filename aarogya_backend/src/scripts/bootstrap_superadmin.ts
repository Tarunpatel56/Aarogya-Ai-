import { prisma } from '../config/prisma';
import { passwordService } from '../services/password.service';
import { Role, VerificationStatus } from '@prisma/client';
import { logger } from '../utils/logger';

/**
 * Super Admin Bootstrap Script
 * 
 * Usage:
 *   npx tsx src/scripts/bootstrap_superadmin.ts --email admin@aarogya.ai --password "MySuperSecret123!" --name "Lead Administrator"
 * Or via environment variables:
 *   BOOTSTRAP_SUPERADMIN_EMAIL=admin@aarogya.ai BOOTSTRAP_SUPERADMIN_PASSWORD="MySuperSecret123!" npx tsx src/scripts/bootstrap_superadmin.ts
 */
async function bootstrapSuperAdmin() {
  const args = process.argv.slice(2);
  let email = process.env.BOOTSTRAP_SUPERADMIN_EMAIL;
  let password = process.env.BOOTSTRAP_SUPERADMIN_PASSWORD;
  let fullName = process.env.BOOTSTRAP_SUPERADMIN_NAME || 'Super Administrator';

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--email' && args[i + 1]) {
      email = args[i + 1];
      i++;
    } else if (args[i] === '--password' && args[i + 1]) {
      password = args[i + 1];
      i++;
    } else if (args[i] === '--name' && args[i + 1]) {
      fullName = args[i + 1];
      i++;
    }
  }

  if (!email || !email.includes('@')) {
    console.error('Error: A valid --email argument or BOOTSTRAP_SUPERADMIN_EMAIL environment variable is required.');
    process.exit(1);
  }

  if (!password || password.length < 8) {
    console.error('Error: A secure --password of at least 8 characters or BOOTSTRAP_SUPERADMIN_PASSWORD is required.');
    process.exit(1);
  }

  const cleanEmail = email.trim().toLowerCase();
  console.log(`Configuring Super Admin account for: ${cleanEmail}...`);

  const passwordHash = await passwordService.hash(password);

  const existingUser = await prisma.user.findUnique({
    where: { email: cleanEmail },
  });

  if (existingUser) {
    // Elevate existing account to Super Admin
    await prisma.user.update({
      where: { id: existingUser.id },
      data: {
        role: Role.PLATFORM_ADMIN,
        passwordHash,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
        isEmailVerified: true,
      },
    });

    logger.info('Super Admin account elevated successfully', {
      userId: existingUser.id,
      email: cleanEmail,
      role: 'SUPER_ADMIN',
    });
    console.log(`[SUCCESS] Existing user "${cleanEmail}" successfully elevated to SUPER_ADMIN with verified status.`);
  } else {
    // Create new Super Admin account
    const newUser = await prisma.user.create({
      data: {
        email: cleanEmail,
        passwordHash,
        role: Role.PLATFORM_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
        isEmailVerified: true,
      },
    });

    logger.info('New Super Admin account created successfully', {
      userId: newUser.id,
      email: cleanEmail,
      role: 'SUPER_ADMIN',
    });
    console.log(`[SUCCESS] New SUPER_ADMIN account created successfully for "${cleanEmail}".`);
  }

  await prisma.$disconnect();
  process.exit(0);
}

bootstrapSuperAdmin().catch((err) => {
  console.error('[ERROR] Failed to bootstrap Super Admin account:', err.message);
  process.exit(1);
});

