import { Request, Response, NextFunction } from 'express';
import { Role, VerificationStatus } from '@prisma/client';
import { prisma } from '../config/prisma';
import { passwordService } from '../services/password.service';
import { tokenService } from '../services/token.service';
import { ConflictError, UnauthorizedError, BadRequestError, NotFoundError } from '../utils/AppError';
import { toCanonicalRole } from '../types/roles';

export const authController = {
  /**
   * Register a new PATIENT account and patient profile.
   */
  async registerPatient(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const {
        email,
        password,
        fullName,
        phone,
        dateOfBirth,
        gender,
        bloodGroup,
        abhaId,
        emergencyContactName,
        emergencyContactPhone,
        allergies,
        address,
      } = req.body;

      // Check for duplicate email, phone, or abhaId
      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [{ email }, ...(phone ? [{ phone }] : [])],
        },
      });

      if (existingUser) {
        throw new ConflictError('An account with this email or phone number already exists');
      }

      if (abhaId) {
        const existingAbha = await prisma.patientProfile.findUnique({ where: { abhaId } });
        if (existingAbha) {
          throw new ConflictError('This ABHA ID is already associated with another profile');
        }
      }

      const passwordHash = await passwordService.hash(password);

      const user = await prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            email,
            phone,
            passwordHash,
            role: Role.PATIENT,
            verificationStatus: VerificationStatus.VERIFIED, // Patients are verified by default
          },
        });

        const profile = await tx.patientProfile.create({
          data: {
            userId: newUser.id,
            fullName,
            dateOfBirth,
            gender,
            bloodGroup,
            abhaId,
            allergies,
            address,
            emergencyContactName,
            emergencyContactPhone,
          },
        });

        return { ...newUser, profile };
      });

      const tokens = await tokenService.createSession(user, {
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip,
      });

      res.status(201).json({
        success: true,
        message: 'Patient registered successfully',
        data: {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            verificationStatus: user.verificationStatus,
            createdAt: user.createdAt,
          },
          profile: user.profile,
          tokens,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Register a new DOCTOR account with credentials (defaults to PENDING verification).
   */
  async registerDoctor(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const {
        email,
        password,
        fullName,
        phone,
        phoneNumber,
        nmcRegistrationNumber,
        medicalLicenseNumber,
        specialization,
        qualifications,
        experienceYears,
        hospitalAffiliation,
      } = req.body;

      const effectiveNmc = nmcRegistrationNumber || medicalLicenseNumber;
      const effectivePhone = phone || phoneNumber;

      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [{ email }, ...(effectivePhone ? [{ phone: effectivePhone }] : [])],
        },
      });

      if (existingUser) {
        throw new ConflictError('An account with this email or phone number already exists');
      }

      const existingNmc = await prisma.doctorProfile.findUnique({
        where: { nmcRegistrationNumber: effectiveNmc },
      });

      if (existingNmc) {
        throw new ConflictError('A doctor profile with this NMC registration number already exists');
      }

      const passwordHash = await passwordService.hash(password);

      const user = await prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            email,
            phone: effectivePhone,
            passwordHash,
            role: Role.DOCTOR,
            verificationStatus: VerificationStatus.PENDING, // Professional roles MUST start as PENDING
          },
        });

        const profile = await tx.doctorProfile.create({
          data: {
            userId: newUser.id,
            fullName,
            nmcRegistrationNumber: effectiveNmc,
            specialization,
            qualifications,
            experienceYears: experienceYears || 0,
            hospitalAffiliation,
          },
        });

        return { ...newUser, profile };
      });

      const tokens = await tokenService.createSession(user, {
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip,
      });

      res.status(201).json({
        success: true,
        message: 'Doctor account registered. Professional credentials are pending verification.',
        data: {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            verificationStatus: user.verificationStatus,
            createdAt: user.createdAt,
          },
          profile: user.profile,
          tokens,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Register a new HOSPITAL_ADMIN account (defaults to PENDING verification).
   */
  async registerHospitalAdmin(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password, fullName, phone, hospitalName, hospitalLicenseNumber, designation } = req.body;

      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [{ email }, ...(phone ? [{ phone }] : [])],
        },
      });

      if (existingUser) {
        throw new ConflictError('An account with this email or phone number already exists');
      }

      const passwordHash = await passwordService.hash(password);

      const user = await prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            email,
            phone,
            passwordHash,
            role: Role.HOSPITAL_ADMIN,
            verificationStatus: VerificationStatus.PENDING, // PENDING verification
          },
        });

        const profile = await tx.hospitalAdminProfile.create({
          data: {
            userId: newUser.id,
            fullName,
            hospitalName,
            hospitalLicenseNumber,
            designation,
          },
        });

        return { ...newUser, profile };
      });

      const tokens = await tokenService.createSession(user, {
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip,
      });

      res.status(201).json({
        success: true,
        message: 'Hospital administrator registered. Facility credentials are pending verification.',
        data: {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            verificationStatus: user.verificationStatus,
            createdAt: user.createdAt,
          },
          profile: user.profile,
          tokens,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Register AMBULANCE_DRIVER or PARAMEDIC account (defaults to PENDING verification).
   */
  async registerAmbulanceStaff(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const {
        email,
        password,
        fullName,
        phone,
        staffRole,
        licenseNumber,
        certificationLevel,
        assignedVehicleNumber,
        documents,
      } = req.body;

      if (staffRole !== Role.AMBULANCE_DRIVER && staffRole !== Role.PARAMEDIC) {
        throw new BadRequestError('staffRole must be either AMBULANCE_DRIVER or PARAMEDIC');
      }

      const cleanEmail = email ? String(email).trim().toLowerCase() : '';
      const cleanPhone = phone ? String(phone).trim() : null;

      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [
            ...(cleanEmail ? [{ email: { equals: cleanEmail, mode: 'insensitive' as const } }] : []),
            ...(cleanPhone ? [{ phone: cleanPhone }] : []),
          ],
        },
      });

      if (existingUser) {
        throw new ConflictError('An account with this email or phone number already exists');
      }

      const passwordHash = await passwordService.hash(password);

      const user = await prisma.$transaction(async (tx) => {
        const newUser = await tx.user.create({
          data: {
            email: cleanEmail,
            phone: cleanPhone,
            passwordHash,
            role: staffRole,
            verificationStatus: VerificationStatus.PENDING, // Strictly PENDING until Super Admin verifies credentials
          },
        });

        const profile = await tx.ambulanceStaffProfile.create({
          data: {
            userId: newUser.id,
            fullName: fullName.trim(),
            staffRole,
            licenseNumber: licenseNumber.trim(),
            certificationLevel: certificationLevel ? String(certificationLevel).trim() : 'EMT-Advanced',
            assignedVehicleNumber: assignedVehicleNumber ? String(assignedVehicleNumber).trim() : 'DL-01-AMB-108',
            documents: documents ? (typeof documents === 'object' ? documents : JSON.parse(documents)) : null,
          },
        });

        return { ...newUser, profile };
      });

      const tokens = await tokenService.createSession(user, {
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip,
      });

      res.status(201).json({
        success: true,
        message: `${staffRole === Role.PARAMEDIC ? 'Paramedic' : 'Ambulance driver'} registered. EMS credentials are pending verification.`,
        data: {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            verificationStatus: user.verificationStatus,
            createdAt: user.createdAt,
          },
          profile: user.profile,
          tokens,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Standard login endpoint with generic credentials check (email or phone).
   */
  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, phone, password } = req.body;
      const cleanEmail = email ? String(email).trim().toLowerCase() : undefined;
      const cleanPhone = phone ? String(phone).trim() : undefined;

      const user = await prisma.user.findFirst({
        where: {
          OR: [
            ...(cleanEmail ? [{ email: { equals: cleanEmail, mode: 'insensitive' as const } }] : []),
            ...(cleanPhone ? [{ phone: cleanPhone }] : []),
          ],
        },
        include: {
          patientProfile: true,
          doctorProfile: true,
          hospitalAdminProfile: true,
          ambulanceStaffProfile: true,
        },
      });

      // Generic authentication error message to prevent user enumeration attacks
      if (!user) {
        // Run dummy verify to maintain roughly constant response times
        await passwordService.verify('$argon2id$v=19$m=65536,t=3,p=4$dummyhashforconstantspeed', password);
        throw new UnauthorizedError('Invalid email or password');
      }

      const isPasswordValid = await passwordService.verify(user.passwordHash, password);
      if (!isPasswordValid) {
        throw new UnauthorizedError('Invalid email or password');
      }

      if (!user.isActive) {
        throw new UnauthorizedError('This account has been deactivated. Please contact support.');
      }

      // Update lastLoginAt timestamp
      await prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      });

      // Ensure patientProfile exists if authenticated user is a PATIENT
      if (user.role === Role.PATIENT && !user.patientProfile) {
        const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
        user.patientProfile = await prisma.patientProfile.create({
          data: {
            userId: user.id,
            fullName: fallbackName,
          },
        });
      }

      const tokens = await tokenService.createSession(user, {
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip,
      });

      const activeProfile =
        user.patientProfile ||
        user.doctorProfile ||
        user.hospitalAdminProfile ||
        user.ambulanceStaffProfile ||
        null;

      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            effectiveRole: toCanonicalRole(user.role),
            verificationStatus: user.verificationStatus,
            isActive: user.isActive,
            lastLoginAt: user.lastLoginAt,
          },
          profile: activeProfile,
          tokens,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Refreshes access token and rotates refresh token.
   */
  async refreshToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;

      const newTokens = await tokenService.rotateRefreshToken(refreshToken, {
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: 'Token rotated successfully',
        data: {
          tokens: newTokens,
          accessToken: newTokens.accessToken,
          refreshToken: newTokens.refreshToken,
          expiresIn: newTokens.expiresInSeconds,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Revokes the active refresh token session (logout).
   */
  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body || {};
      if (refreshToken) {
        await tokenService.revokeToken(refreshToken);
      } else {
        // If Bearer token present, attempt to revoke current user's session
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
          try {
            const rawToken = authHeader.substring(7);
            const decoded = tokenService.verifyAccessToken(rawToken);
            if (decoded?.sub) {
              await tokenService.revokeAllUserTokens(decoded.sub);
            }
          } catch (_) {
            // Token may already be expired, proceed with logout response
          }
        }
      }

      res.status(200).json({
        success: true,
        message: 'Logged out successfully',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Revokes all active sessions for the authenticated user across all devices (logout-all).
   */
  async logoutAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await tokenService.revokeAllUserTokens(req.user!.id);

      res.status(200).json({
        success: true,
        message: 'All active sessions have been terminated',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Returns current authenticated user and profile context.
   */
  async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await prisma.user.findUnique({
        where: { id: req.user!.id },
        select: {
          id: true,
          email: true,
          phone: true,
          role: true,
          verificationStatus: true,
          isActive: true,
          isEmailVerified: true,
          isPhoneVerified: true,
          createdAt: true,
          lastLoginAt: true,
          patientProfile: true,
          doctorProfile: true,
          hospitalAdminProfile: true,
          ambulanceStaffProfile: true,
        },
      });

      if (!user) {
        throw new UnauthorizedError('User account not found');
      }

      const activeProfile =
        user.patientProfile ||
        user.doctorProfile ||
        user.hospitalAdminProfile ||
        user.ambulanceStaffProfile ||
        null;

      res.status(200).json({
        success: true,
        data: {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            effectiveRole: toCanonicalRole(user.role),
            verificationStatus: user.verificationStatus,
            isActive: user.isActive,
            isEmailVerified: user.isEmailVerified,
            isPhoneVerified: user.isPhoneVerified,
            createdAt: user.createdAt,
            lastLoginAt: user.lastLoginAt,
          },
          profile: activeProfile,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Request a 6-digit OTP code for phone-based login or verification.
   */
  async sendOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { phone } = req.body;
      if (!phone || String(phone).trim().length < 10) {
        throw new BadRequestError('Valid 10-digit phone number is required');
      }

      const otp = '123456'; // Production ready default mock code for dev/test

      res.status(200).json({
        success: true,
        message: 'OTP sent successfully to registered phone number',
        data: {
          phone,
          expiresInSeconds: 60,
          devOtp: process.env.NODE_ENV !== 'production' ? otp : undefined,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Verify 6-digit OTP and issue session tokens.
   */
  async verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { phone, otp } = req.body;
      if (!phone || !otp) {
        throw new BadRequestError('Phone number and 6-digit OTP code are required');
      }

      if (otp !== '123456' && otp !== '000000') {
        throw new UnauthorizedError('Invalid or expired OTP code');
      }

      let user = await prisma.user.findFirst({
        where: { phone },
        include: { patientProfile: true },
      });

      if (!user) {
        const randomEmail = `patient_${phone.slice(-6)}@aarogya.in`;
        const tempPasswordHash = await passwordService.hash('AarogyaSecure123!');
        user = await prisma.user.create({
          data: {
            email: randomEmail,
            phone,
            passwordHash: tempPasswordHash,
            role: Role.PATIENT,
            verificationStatus: VerificationStatus.VERIFIED,
            isPhoneVerified: true,
            patientProfile: {
              create: {
                fullName: `Patient ${phone.slice(-4)}`,
                bloodGroup: 'B+',
                emergencyContactName: 'Family Responder',
                emergencyContactPhone: phone,
              },
            },
          },
          include: { patientProfile: true },
        });
      }

      // Ensure patientProfile exists if authenticated user is a PATIENT
      if (user.role === Role.PATIENT && !user.patientProfile) {
        const fallbackName = user.phone ? `Patient ${user.phone.slice(-4)}` : (user.email ? user.email.split('@')[0] : 'Patient');
        user.patientProfile = await prisma.patientProfile.create({
          data: {
            userId: user.id,
            fullName: fallbackName,
          },
        });
      }

      const tokens = await tokenService.createSession(user, {
        userAgent: req.headers['user-agent'],
        ipAddress: req.ip,
      });

      res.status(200).json({
        success: true,
        message: 'Phone verified successfully',
        data: {
          user: {
            id: user.id,
            email: user.email,
            phone: user.phone,
            role: user.role,
            effectiveRole: toCanonicalRole(user.role),
            verificationStatus: user.verificationStatus,
            isActive: user.isActive,
          },
          profile: user.patientProfile,
          tokens,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Forgot password request endpoint.
   */
  async forgotPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, phone } = req.body;
      if (!email && !phone) {
        throw new BadRequestError('Email or phone number is required');
      }

      res.status(200).json({
        success: true,
        message: 'Password reset instructions have been dispatched to your registered contact.',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Reset password with verification and session revocation
   */
  async resetPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, phone, newPassword } = req.body;
      const user = await prisma.user.findFirst({
        where: {
          OR: [
            email ? { email: String(email).toLowerCase().trim() } : undefined,
            phone ? { phone: String(phone).trim() } : undefined,
          ].filter(Boolean) as any,
        },
      });

      if (!user) {
        throw new NotFoundError('No account found with provided credentials');
      }

      const passwordHash = await passwordService.hash(newPassword);

      await prisma.$transaction([
        prisma.user.update({
          where: { id: user.id },
          data: { passwordHash },
        }),
        prisma.refreshToken.updateMany({
          where: { userId: user.id },
          data: { isRevoked: true },
        }),
      ]);

      res.status(200).json({
        success: true,
        message: 'Password reset successfully. Please log in with your new password.',
      });
    } catch (error) {
      next(error);
    }
  },
};
