import argon2 from 'argon2';

/**
 * Password hashing and verification service using Argon2id.
 */
export const passwordService = {
  /**
   * Hashes a plaintext password using Argon2id.
   */
  async hash(password: string): Promise<string> {
    return argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 2 ** 16, // 64 MB
      timeCost: 3,
      parallelism: 4,
    });
  },

  /**
   * Verifies a plaintext password against an Argon2id hash.
   * Employs constant-time verification to prevent timing attacks.
   */
  async verify(hash: string, plaintext: string): Promise<boolean> {
    try {
      return await argon2.verify(hash, plaintext);
    } catch {
      return false;
    }
  },
};
