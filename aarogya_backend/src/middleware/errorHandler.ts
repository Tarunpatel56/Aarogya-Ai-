import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/AppError';
import { logger } from '../utils/logger';
import { env } from '../config/env';

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // Operational errors (handled application errors)
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error(`[AppError ${err.statusCode}] ${err.message}`, {
        details: err.details,
        stack: err.stack,
      });
    } else {
      logger.warn(`[AppError ${err.statusCode}] ${err.message}`, {
        details: err.details,
      });
    }

    res.status(err.statusCode).json({
      success: false,
      error: {
        message: err.message,
        statusCode: err.statusCode,
        ...(err.details ? { details: err.details } : {}),
      },
    });
    return;
  }

  // Unhandled / unexpected errors
  logger.error(`[UnhandledError] ${err.message}`, {
    stack: err.stack,
  });

  const isProduction = env.NODE_ENV === 'production';

  res.status(500).json({
    success: false,
    error: {
      message: isProduction ? 'Internal Server Error' : err.message,
      statusCode: 500,
      ...(!isProduction && err.stack ? { stack: err.stack } : {}),
    },
  });
}
