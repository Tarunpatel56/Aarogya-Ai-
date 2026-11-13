import { prisma } from '../config/prisma';
import argon2 from 'argon2';

async function checkUsers() {
  const users = await prisma.user.findMany({
    select: {
      id: true,
      email: true,
      role: true,
      passwordHash: true,
    }
  });
  console.log('Total users:', users.length);
  for (const u of users) {
    console.log(`- ${u.email} (${u.role})`);
  }

  // Check krishna@gmail.com and tarunpatel0@gmail.com
  const testUsers = ['krishna@gmail.com', 'tarunpatel0@gmail.com', 'driver@gmail.com', 'driver@aarogya.ai'];
  for (const email of testUsers) {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (!existing) {
      console.log(`User ${email} does not exist.`);
    } else {
      console.log(`User ${email} exists, role: ${existing.role}`);
    }
  }
}

checkUsers().finally(() => prisma.$disconnect());
