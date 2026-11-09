import crypto from 'crypto';
import jwt, { SignOptions } from 'jsonwebtoken';
import { Role, VerificationStatus } from '@prisma/client';
import { env } from '../config/env';
import { prisma } from '../config/prisma';
import { UnauthorizedError } from '../utils/AppError';

export interface AccessTokenPayload {
  sub: string;
  email: string;
  role: Role;
  verificationStatus: VerificationStatus;
  jti: string;
}

export interface GeneratedTokens {
  accessToken: string;
  refreshToken: string;
  expiresInSeconds: number;
}

/**
 * Parses expiry strings like '15m', '7d', '1h' into milliseconds.
 */
function parseExpiryToMs(expiry: string): number {
  const match = expiry.match(/^(\d+)([smhd])$/);
  if (!match) return 15 * 60 * 1000; // default 15m

  const value = parseInt(match[1], 10);
  const unit = match[2];

  switch (unit) {
    case 's':
      return value * 1000;
    case 'm':
      return value * 60 * 1000;
    case 'h':
      return value * 60 * 60 * 1000;
    case 'd':
      return value * 24 * 60 * 60 * 1000;
    default:
      return 15 * 60 * 1000;
  }
}

export const tokenService = {
  /**
   * Generates a SHA-256 hash of an opaque token string.
   * Raw tokens are never stored in the database.
   */
  hashToken(rawToken: string): string {
    return crypto.createHash('sha256').update(rawToken).digest('hex');
  },

  /**
   * Signs a short-lived JWT access token.
   */
  signAccessToken(user: { id: string; email: string; role: Role; verificationStatus: VerificationStatus }): string {
    const payload: AccessTokenPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      verificationStatus: user.verificationStatus,
      jti: crypto.randomUUID(),
    };

    const options: SignOptions = {
      expiresIn: env.JWT_ACCESS_EXPIRY as any,
      algorithm: 'HS256',
    };

    return jwt.sign(payload, env.JWT_ACCESS_SECRET, options);
  },

  /**
   * Verifies an access token and extracts its payload.
   */
  verifyAccessToken(token: string): AccessTokenPayload {
    try {
      return jwt.verify(token, env.JWT_ACCESS_SECRET, { algorithms: ['HS256'] }) as AccessTokenPayload;
    } catch (err: any) {
      if (err.name === 'TokenExpiredError') {
        throw new UnauthorizedError('Access token has expired', { code: 'TOKEN_EXPIRED' });
      }
      throw new UnauthorizedError('Invalid access token', { code: 'TOKEN_INVALID' });
    }
  },

  /**
   * Issues a new pair of access and refresh tokens for a user.
   */
  async createSession(
    user: { id: string; email: string; role: Role; verificationStatus: VerificationStatus },
    metadata?: { userAgent?: string; ipAddress?: string }
  ): Promise<GeneratedTokens> {
    const accessToken = this.signAccessToken(user);

    // Generate cryptographically random opaque refresh token
    const rawRefreshToken = crypto.randomBytes(64).toString('hex');
    const tokenHash = this.hashToken(rawRefreshToken);
    const familyId = crypto.randomUUID();

    const refreshExpiryMs = parseExpiryToMs(env.JWT_REFRESH_EXPIRY);
    const expiresAt = new Date(Date.now() + refreshExpiryMs);

    await prisma.refreshToken.create({
      data: {
        tokenHash,
        userId: user.id,
        familyId,
        expiresAt,
        userAgent: metadata?.userAgent,
        ipAddress: metadata?.ipAddress,
      },
    });

    const accessExpirySeconds = Math.floor(parseExpiryToMs(env.JWT_ACCESS_EXPIRY) / 1000);

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresInSeconds: accessExpirySeconds,
    };
  },

  /**
   * Performs refresh token rotation with reuse detection.
   */
  async rotateRefreshToken(
    rawToken: string,
    metadata?: { userAgent?: string; ipAddress?: string }
  ): Promise<GeneratedTokens> {
    const tokenHash = this.hashToken(rawToken);

    const tokenRecord = await prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });

    if (!tokenRecord) {
      throw new UnauthorizedError('Invalid refresh token');
    }

    // Reuse detection: If token was already revoked, someone is replaying an old token.
    // Invalidate the ENTIRE token family immediately!
    if (tokenRecord.isRevoked) {
      await prisma.refreshToken.updateMany({
        where: { familyId: tokenRecord.familyId },
        data: { isRevoked: true },
      });
      throw new UnauthorizedError(
        'Compromised refresh token reuse detected. All sessions in this family have been terminated.',
        { code: 'REFRESH_TOKEN_REUSE_DETECTED' }
      );
    }

    if (tokenRecord.expiresAt < new Date()) {
      throw new UnauthorizedError('Refresh token has expired', { code: 'REFRESH_TOKEN_EXPIRED' });
    }

    if (!tokenRecord.user.isActive) {
      throw new UnauthorizedError('User account is disabled');
    }

    // Atomically revoke old token and create replacement within the same familyId
    const newRawRefreshToken = crypto.randomBytes(64).toString('hex');
    const newTokenHash = this.hashToken(newRawRefreshToken);
    const refreshExpiryMs = parseExpiryToMs(env.JWT_REFRESH_EXPIRY);
    const expiresAt = new Date(Date.now() + refreshExpiryMs);

    await prisma.$transaction([
      prisma.refreshToken.update({
        where: { id: tokenRecord.id },
        data: { isRevoked: true },
      }),
      prisma.refreshToken.create({
        data: {
          tokenHash: newTokenHash,
          userId: tokenRecord.userId,
          familyId: tokenRecord.familyId,
          expiresAt,
          userAgent: metadata?.userAgent,
          ipAddress: metadata?.ipAddress,
        },
      }),
    ]);

    const newAccessToken = this.signAccessToken(tokenRecord.user);
    const accessExpirySeconds = Math.floor(parseExpiryToMs(env.JWT_ACCESS_EXPIRY) / 1000);

    return {
      accessToken: newAccessToken,
      refreshToken: newRawRefreshToken,
      expiresInSeconds: accessExpirySeconds,
    };
  },

  /**
   * Revokes a specific refresh token (used on logout).
   */
  async revokeToken(rawToken: string): Promise<void> {
    const tokenHash = this.hashToken(rawToken);
    await prisma.refreshToken.updateMany({
      where: { tokenHash, isRevoked: false },
      data: { isRevoked: true },
    });
  },

  /**
   * Revokes all active refresh tokens for a user across all devices (logout-all).
   */
  async revokeAllUserTokens(userId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { userId, isRevoked: false },
      data: { isRevoked: true },
    });
  },
};
