import { Router, Request, Response } from 'express';
import { checkDatabaseHealth } from '../config/prisma';
import { env } from '../config/env';

const router = Router();

router.get('/', async (_req: Request, res: Response) => {
  const dbHealth = await checkDatabaseHealth();

  const isHealthy = dbHealth.connected;
  const statusCode = isHealthy ? 200 : 503;

  res.status(statusCode).json({
    success: true,
    status: isHealthy ? 'healthy' : 'degraded',
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    environment: env.NODE_ENV,
    version: '1.0.0',
    services: {
      api: {
        status: 'up',
      },
      database: {
        status: dbHealth.connected ? 'connected' : 'disconnected',
        ...(dbHealth.latencyMs !== undefined ? { latencyMs: dbHealth.latencyMs } : {}),
        ...(dbHealth.error ? { message: dbHealth.error } : {}),
      },
    },
  });
});

export const healthRoutes = router;
