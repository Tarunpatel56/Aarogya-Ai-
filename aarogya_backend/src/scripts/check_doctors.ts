import { prisma } from '../config/prisma';

async function main() {
  const doctors = await prisma.doctorProfile.findMany({
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          verificationStatus: true,
          isActive: true,
        },
      },
    },
  });

  console.log(`Found ${doctors.length} doctors in database:`);
  for (const d of doctors) {
    console.log(`- ID: ${d.id} | Name: "${d.fullName}" | Email: ${d.user.email} | Status: ${d.user.verificationStatus} | NMC: ${d.nmcRegistrationNumber} | Specialization: ${d.specialization}`);
  }
}

main().finally(async () => {
  await prisma.$disconnect();
});

