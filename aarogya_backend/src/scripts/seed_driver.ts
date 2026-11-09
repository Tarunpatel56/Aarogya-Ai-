import { prisma } from '../config/prisma';
import { passwordService } from '../services/password.service';
import { Role, VerificationStatus } from '@prisma/client';

async function seedDriver() {
  const email = 'driver@aarogya.ai';
  const password = 'Driver@123';
  const passwordHash = await passwordService.hash(password);

  console.log('Seeding default ambulance driver account...');

  const existing = await prisma.user.findFirst({
    where: { email: { equals: email, mode: 'insensitive' } },
  });

  if (existing) {
    await prisma.user.update({
      where: { id: existing.id },
      data: {
        passwordHash,
        role: Role.AMBULANCE_DRIVER,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });

    await prisma.ambulanceStaffProfile.upsert({
      where: { userId: existing.id },
      create: {
        userId: existing.id,
        fullName: 'Vikram Singh (EMS Lead)',
        staffRole: Role.AMBULANCE_DRIVER,
        licenseNumber: 'DL-EMS-2026-99',
        assignedVehicleNumber: 'DL-01-AMB-108',
        certificationLevel: 'Paramedic EMT-A',
      },
      update: {
        fullName: 'Vikram Singh (EMS Lead)',
        staffRole: Role.AMBULANCE_DRIVER,
        licenseNumber: 'DL-EMS-2026-99',
        assignedVehicleNumber: 'DL-01-AMB-108',
        certificationLevel: 'Paramedic EMT-A',
      },
    });

    console.log(`[SUCCESS] Existing account ${email} updated with password ${password} and verified AMBULANCE_DRIVER role.`);
  } else {
    const newUser = await prisma.user.create({
      data: {
        email,
        phone: '9810923812',
        passwordHash,
        role: Role.AMBULANCE_DRIVER,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });

    await prisma.ambulanceStaffProfile.create({
      data: {
        userId: newUser.id,
        fullName: 'Vikram Singh (EMS Lead)',
        staffRole: Role.AMBULANCE_DRIVER,
        licenseNumber: 'DL-EMS-2026-99',
        assignedVehicleNumber: 'DL-01-AMB-108',
        certificationLevel: 'Paramedic EMT-A',
      },
    });

    console.log(`[SUCCESS] New AMBULANCE_DRIVER account ${email} created with password ${password}.`);
  }

  await prisma.$disconnect();
}

seedDriver().catch(console.error);
