import { prisma } from '../config/prisma';
import { passwordService } from '../services/password.service';

async function updateTestUsers() {
  const users = [
    { email: 'krishna@gmail.com', pass: 'Krishna@123' },
    { email: 'tarunpatel0@gmail.com', pass: 'Tarun@123' },
    { email: 'vikram@gmail.com', pass: 'Vikram@123' },
    { email: 'driver@aarogya.ai', pass: 'Driver@123' },
    { email: 'driver@gmail.com', pass: 'Driver@123', createAsDriver: true },
    { email: 'superadmin@aarogya.ai', pass: 'SuperAdmin@123!' },
  ];

  for (const item of users) {
    const existing = await prisma.user.findUnique({ where: { email: item.email } });
    const passwordHash = await passwordService.hash(item.pass);

    if (existing) {
      // Check if current password matches
      const matches = await passwordService.verify(existing.passwordHash, item.pass);
      console.log(`User ${item.email} password matches ${item.pass}? -> ${matches}`);
      if (!matches) {
        await prisma.user.update({
          where: { id: existing.id },
          data: { passwordHash, isEmailVerified: true },
        });
        console.log(`Updated password for ${item.email} to '${item.pass}'`);
      }
    } else if (item.createAsDriver) {
      await prisma.user.create({
        data: {
          email: item.email,
          passwordHash,
          role: 'AMBULANCE_DRIVER',
          isEmailVerified: true,
          ambulanceStaffProfile: {
            create: {
              fullName: 'Aarogya Rapid Driver',
              licenseNumber: 'DL-AAROGYA-2026',
              staffRole: 'AMBULANCE_DRIVER',
              assignedVehicleNumber: 'MH-02-EMS-108',
            }
          }
        }
      });
      console.log(`Created driver ${item.email} with password '${item.pass}'`);
    }
  }
}

updateTestUsers().finally(() => prisma.$disconnect());
