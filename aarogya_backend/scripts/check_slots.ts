import { prisma } from '../src/config/prisma';

async function main() {
  const doctors = await prisma.doctorProfile.findMany({
    include: {
      user: {
        select: {
          id: true,
          email: true,
          verificationStatus: true,
          isActive: true,
        },
      },
      availabilities: true,
    },
  });

  console.log(`Found ${doctors.length} doctors:`);
  for (const d of doctors) {
    console.log(`\nDoctor: ${d.fullName} (ID: ${d.id}, UserID: ${d.userId})`);
    console.log(`  Email: ${d.user.email}`);
    console.log(`  Verification: ${d.user.verificationStatus}, Active: ${d.user.isActive}`);
    console.log(`  isOnline: ${d.isOnline}, status: ${d.status}`);
    console.log(`  Availabilities count: ${d.availabilities.length}`);
    d.availabilities.forEach((a, i) => {
      console.log(`    Slot ${i + 1}: ${a.startTime.toISOString()} - ${a.endTime.toISOString()} [${a.status}]`);
    });
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
