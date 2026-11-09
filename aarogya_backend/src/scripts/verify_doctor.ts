import { prisma } from '../config/prisma';
import { VerificationStatus } from '@prisma/client';

async function main() {
  const targetEmail = process.argv[2];

  if (targetEmail) {
    const user = await prisma.user.findFirst({
      where: { email: targetEmail },
      include: { doctorProfile: true },
    });

    if (!user || !user.doctorProfile) {
      console.error(`Doctor not found with email: ${targetEmail}`);
      process.exit(1);
    }

    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { verificationStatus: VerificationStatus.VERIFIED },
      }),
      prisma.doctorProfile.update({
        where: { id: user.doctorProfile.id },
        data: {
          verifiedAt: new Date(),
          status: 'ACTIVE',
        },
      }),
    ]);

    console.log(`✅ Successfully VERIFIED doctor: ${user.doctorProfile.fullName} (${user.email})`);
    console.log(`This doctor is now immediately discoverable on the Aarogya Patient App!`);
  } else {
    // Verify ALL pending doctors
    const pendingDoctors = await prisma.doctorProfile.findMany({
      where: {
        user: {
          verificationStatus: VerificationStatus.PENDING,
        },
      },
      include: { user: true },
    });

    if (pendingDoctors.length === 0) {
      console.log('No pending doctors found. All doctors are already verified!');
      return;
    }

    console.log(`Found ${pendingDoctors.length} pending doctor(s). Verifying now...`);

    for (const doc of pendingDoctors) {
      await prisma.$transaction([
        prisma.user.update({
          where: { id: doc.userId },
          data: { verificationStatus: VerificationStatus.VERIFIED },
        }),
        prisma.doctorProfile.update({
          where: { id: doc.id },
          data: {
            verifiedAt: new Date(),
            status: 'ACTIVE',
          },
        }),
      ]);
      console.log(`✅ VERIFIED: ${doc.fullName} (${doc.user.email}) - NMC: ${doc.nmcRegistrationNumber}`);
    }

    console.log(`\n🎉 All ${pendingDoctors.length} doctors have been VERIFIED and are now live on Aarogya App!`);
  }
}

main().finally(async () => {
  await prisma.$disconnect();
});

