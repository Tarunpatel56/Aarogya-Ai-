import http from 'http';
import { app } from './app';
import { env } from './config/env';
import { prisma } from './config/prisma';
import { logger } from './utils/logger';
import { ensureVerifiedHospitalsSeeded } from './services/hospital-seed.service';
import { ensureSuperAdminAndDefaultAccounts } from './services/admin-seed.service';
import { socketService } from './services/socket.service';

const server = http.createServer(app);

// Initialize real-time Socket.IO communication
socketService.init(server);

server.listen(env.PORT, async () => {
  logger.info(`=======================================================`);
  logger.info(`🚀 Aarogya Unified Healthcare Backend is running`);
  logger.info(`📡 Port:        ${env.PORT}`);
  logger.info(`⚡ WebSockets:  Socket.IO active on port ${env.PORT}`);
  logger.info(`🌍 Environment: ${env.NODE_ENV}`);
  logger.info(`🩺 Health:     http://localhost:${env.PORT}/health`);
  logger.info(`=======================================================`);

  // Ensure verified hospitals directory is populated with live ICU bed telemetry
  await ensureVerifiedHospitalsSeeded();

  // Guarantee Super Admin and verified Ambulance Pilot accounts exist across local & cloud deployments
  await ensureSuperAdminAndDefaultAccounts();
});

// Graceful shutdown handling
async function gracefulShutdown(signal: string) {
  logger.info(`Received ${signal}. Starting graceful shutdown...`);

  server.close(async () => {
    logger.info('HTTP server closed.');
    try {
      await prisma.$disconnect();
      logger.info('Database connection closed.');
    } catch (err: any) {
      logger.error('Error closing database connection', { error: err.message });
    }
    process.exit(0);
  });

  // Force shutdown after timeout
  setTimeout(() => {
    logger.error('Forced shutdown due to timeout');
    process.exit(1);
  }, 10000).unref();
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
