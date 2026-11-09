import rateLimit from 'express-rate-limit';
import { env } from '../config/env';

/**
 * Rate limiter for sensitive authentication endpoints (login, register, token refresh).
 * Throttles brute-force password guessing and credential stuffing attacks.
 */
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: env.NODE_ENV === 'test' ? 1000 : 15, // 15 attempts per 15 minutes in non-test env
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      message: 'Too many authentication requests from this IP. Please try again after 15 minutes.',
      statusCode: 429,
    },
  },
  skip: () => env.NODE_ENV === 'test' && process.env.TEST_RATE_LIMIT !== 'true',
});
