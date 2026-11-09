import { PrismaClient } from '@prisma/client';
import { env } from './env';
import { logger } from '../utils/logger';

declare global {
  // eslint-disable-next-line no-var
  var prismaGlobal: PrismaClient | undefined;
}

export const prisma =
  global.prismaGlobal ||
  new PrismaClient({
    log: env.NODE_ENV === 'development' ? ['warn', 'error'] : ['error'],
  });

if (env.NODE_ENV !== 'production') {
  global.prismaGlobal = prisma;
}

export interface DatabaseHealthResult {
  connected: boolean;
  latencyMs?: number;
  error?: string;
}

/**
 * Checks database connectivity with a strict timeout.
 * Returns health status without throwing unhandled exceptions.
 */
export async function checkDatabaseHealth(timeoutMs = 2000): Promise<DatabaseHealthResult> {
  if (!env.DATABASE_URL || env.DATABASE_URL.includes('YOUR_PASSWORD')) {
    return {
      connected: false,
      error: 'DATABASE_URL is not configured or contains placeholder credentials',
    };
  }

  const startTime = Date.now();
  try {
    const timeoutPromise = new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error(`Database check timed out after ${timeoutMs}ms`)), timeoutMs)
    );

    const queryPromise = prisma.$queryRaw`SELECT 1`;

    await Promise.race([queryPromise, timeoutPromise]);
    const latencyMs = Date.now() - startTime;

    return {
      connected: true,
      latencyMs,
    };
  } catch (error: any) {
    logger.warn('Database health check failed', { error: error.message });
    return {
      connected: false,
      error: error.message || 'Database connection error',
    };
  }
}
