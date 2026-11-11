import { Request, Response, NextFunction } from 'express';
import { Role, Prisma } from '@prisma/client';
import { prisma } from '../config/prisma';
import { passwordService } from '../services/password.service';
import { tokenService } from '../services/token.service';
import { NotFoundError, BadRequestError, ConflictError } from '../utils/AppError';
import { toPrismaRole, toCanonicalRole, isSuperAdmin } from '../types/roles';
import { logger } from '../utils/logger';
import { socketService } from '../services/socket.service';
import { communityService } from '../services/community.service';

// In-memory audit trail for privileged Super Admin operations
export interface AdminAuditEntry {
  id: string;
  timestamp: string;
  adminId: string;
  adminEmail: string;
  action: string;
  targetUserId?: string;
  targetUserEmail?: string;
  details: Record<string, any>;
}

const auditTrail: AdminAuditEntry[] = [];

export function recordAudit(
  req: Request,
  action: string,
  targetUser?: { id: string; email: string },
  details: Record<string, any> = {}
) {
  const entry: AdminAuditEntry = {
    id: `audit-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    timestamp: new Date().toISOString(),
    adminId: req.user?.id || 'system',
    adminEmail: req.user?.email || 'system',
    action,
    targetUserId: targetUser?.id,
    targetUserEmail: targetUser?.email,
    details,
  };

  auditTrail.unshift(entry);
  if (auditTrail.length > 500) {
    auditTrail.pop();
  }

  logger.info(`[AUDIT] ${action}`, {
    adminEmail: entry.adminEmail,
    targetUserEmail: entry.targetUserEmail,
    ...details,
  });
}

let platformSettings = {
  maintenanceMode: false,
  emergencyAutoDispatch: true,
  aiDiagnosticAssistance: true,
  maxTeleconsultationQueue: 50,
  lastBackupTimestamp: new Date(Date.now() - 3600000).toISOString(),
  backupStatus: 'HEALTHY',
};

export const adminController = {
  /**
   * List platform users with pagination, role filtering, verification filtering and search.
   */
  async getUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { limit = 20, offset = 0, role, isActive, verificationStatus, search } = req.query as any;

      const where: Prisma.UserWhereInput = {};

      if (role) {
        where.role = toPrismaRole(role);
      }

      if (isActive !== undefined) {
        where.isActive = isActive;
      }

      if (verificationStatus) {
        where.verificationStatus = verificationStatus;
      }

      if (search && search.trim().length > 0) {
        const query = search.trim();
        where.OR = [
          { email: { contains: query, mode: 'insensitive' } },
          { phone: { contains: query, mode: 'insensitive' } },
          { patientProfile: { fullName: { contains: query, mode: 'insensitive' } } },
          { doctorProfile: { fullName: { contains: query, mode: 'insensitive' } } },
          { hospitalAdminProfile: { fullName: { contains: query, mode: 'insensitive' } } },
          { ambulanceStaffProfile: { fullName: { contains: query, mode: 'insensitive' } } },
        ];
      }

      const [users, total] = await Promise.all([
        prisma.user.findMany({
          where,
          take: Number(limit),
          skip: Number(offset),
          orderBy: { createdAt: 'desc' },
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
            patientProfile: { select: { fullName: true, abhaId: true } },
            doctorProfile: { select: { fullName: true, specialization: true, nmcRegistrationNumber: true } },
            hospitalAdminProfile: { select: { fullName: true, hospitalName: true, designation: true } },
            ambulanceStaffProfile: { select: { fullName: true, licenseNumber: true, assignedVehicleNumber: true } },
          },
        }),
        prisma.user.count({ where }),
      ]);

      const formattedUsers = users.map((u) => {
        const profile =
          u.patientProfile ||
          u.doctorProfile ||
          u.hospitalAdminProfile ||
          u.ambulanceStaffProfile ||
          null;

        return {
          id: u.id,
          email: u.email,
          phone: u.phone,
          role: u.role,
          effectiveRole: toCanonicalRole(u.role),
          verificationStatus: u.verificationStatus,
          isActive: u.isActive,
          isEmailVerified: u.isEmailVerified,
          isPhoneVerified: u.isPhoneVerified,
          createdAt: u.createdAt,
          lastLoginAt: u.lastLoginAt,
          profileName: (profile as any)?.fullName || null,
          profile,
        };
      });

      res.status(200).json({
        success: true,
        data: {
          users: formattedUsers,
          pagination: {
            total,
            limit: Number(limit),
            offset: Number(offset),
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieve full details of a specific user.
   */
  async getUserById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);

      const user = await prisma.user.findUnique({
        where: { id },
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
          updatedAt: true,
          lastLoginAt: true,
          patientProfile: true,
          doctorProfile: true,
          hospitalAdminProfile: true,
          ambulanceStaffProfile: true,
        },
      });

      if (!user) {
        throw new NotFoundError('User not found');
      }

      res.status(200).json({
        success: true,
        data: {
          user: {
            ...user,
            effectiveRole: toCanonicalRole(user.role),
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin creates an authorized user account with specified role.
   */
  async createUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password, role, fullName, phone } = req.body;
      const cleanEmail = email.trim().toLowerCase();
      const prismaRole = toPrismaRole(role);

      const existing = await prisma.user.findFirst({
        where: { email: cleanEmail },
      });

      if (existing) {
        throw new ConflictError('A user with this email address already exists');
      }

      const passwordHash = await passwordService.hash(password);

      const user = await prisma.$transaction(async (tx) => {
        const createdUser = await tx.user.create({
          data: {
            email: cleanEmail,
            passwordHash,
            role: prismaRole,
            phone: phone ? phone.trim() : null,
            verificationStatus: 'VERIFIED',
            isActive: true,
            isEmailVerified: true,
          },
        });

        // Create initial role profile
        if (prismaRole === Role.PATIENT) {
          await tx.patientProfile.create({
            data: {
              userId: createdUser.id,
              fullName: fullName.trim(),
            },
          });
        } else if (prismaRole === Role.HOSPITAL_ADMIN) {
          await tx.hospitalAdminProfile.create({
            data: {
              userId: createdUser.id,
              fullName: fullName.trim(),
              hospitalName: 'General Hospital',
              hospitalLicenseNumber: `HOSP-${Date.now().toString().slice(-6)}`,
              designation: 'Hospital Administrator',
              verifiedAt: new Date(),
              verifiedBy: req.user!.email,
            },
          });
        } else if (prismaRole === Role.AMBULANCE_DRIVER) {
          await tx.ambulanceStaffProfile.create({
            data: {
              userId: createdUser.id,
              fullName: fullName.trim(),
              staffRole: Role.AMBULANCE_DRIVER,
              licenseNumber: `DL-${Date.now().toString().slice(-6)}`,
              assignedVehicleNumber: 'AMB-01',
              verifiedAt: new Date(),
              verifiedBy: req.user!.email,
            },
          });
        }

        return createdUser;
      });

      recordAudit(req, 'CREATE_USER', { id: user.id, email: user.email }, { role: user.role });

      res.status(201).json({
        success: true,
        message: 'User account created successfully by Super Admin',
        data: {
          user: {
            id: user.id,
            email: user.email,
            role: user.role,
            effectiveRole: toCanonicalRole(user.role),
            verificationStatus: user.verificationStatus,
            isActive: user.isActive,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Activate or deactivate a user account.
   */
  async updateUserStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const { isActive, reason } = req.body;

      if (id === req.user!.id && !isActive) {
        throw new BadRequestError('Super Admins cannot deactivate their own active account');
      }

      const targetUser = await prisma.user.findUnique({
        where: { id },
      });

      if (!targetUser) {
        throw new NotFoundError('User not found');
      }

      const updated = await prisma.user.update({
        where: { id },
        data: { isActive },
      });

      if (!isActive) {
        // Immediately revoke all sessions for deactivated account
        await tokenService.revokeAllUserTokens(id);
      }

      recordAudit(
        req,
        isActive ? 'ACTIVATE_USER' : 'DEACTIVATE_USER',
        { id: targetUser.id, email: targetUser.email },
        { reason: reason || 'Administrative action', previousStatus: targetUser.isActive }
      );

      res.status(200).json({
        success: true,
        message: `User account ${isActive ? 'activated' : 'deactivated'} successfully`,
        data: {
          user: {
            id: updated.id,
            email: updated.email,
            role: updated.role,
            effectiveRole: toCanonicalRole(updated.role),
            isActive: updated.isActive,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Assign or promote a user's role.
   */
  async assignUserRole(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const { role } = req.body;
      const targetPrismaRole = toPrismaRole(role);

      const targetUser = await prisma.user.findUnique({
        where: { id },
      });

      if (!targetUser) {
        throw new NotFoundError('User not found');
      }

      // Safeguard: Do not allow demoting the last active Super Admin
      if (isSuperAdmin(targetUser.role) && !isSuperAdmin(targetPrismaRole)) {
        const superAdminCount = await prisma.user.count({
          where: {
            role: Role.PLATFORM_ADMIN,
            isActive: true,
          },
        });

        if (superAdminCount <= 1) {
          throw new BadRequestError('Cannot demote the only active Super Admin on the platform');
        }
      }

      const updated = await prisma.user.update({
        where: { id },
        data: {
          role: targetPrismaRole,
          verificationStatus: 'VERIFIED',
        },
      });

      recordAudit(
        req,
        'ASSIGN_ROLE',
        { id: targetUser.id, email: targetUser.email },
        { previousRole: targetUser.role, newRole: targetPrismaRole }
      );

      res.status(200).json({
        success: true,
        message: `Role updated to ${toCanonicalRole(updated.role)} successfully`,
        data: {
          user: {
            id: updated.id,
            email: updated.email,
            role: updated.role,
            effectiveRole: toCanonicalRole(updated.role),
            verificationStatus: updated.verificationStatus,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieve platform-level operational statistics.
   */
  async getStats(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const [
        totalUsers,
        activeUsers,
        patientCount,
        doctorCount,
        hospitalAdminCount,
        driverCount,
        superAdminCount,
        pendingVerificationCount,
        totalAppointments,
        totalMedicalRecords,
      ] = await Promise.all([
        prisma.user.count(),
        prisma.user.count({ where: { isActive: true } }),
        prisma.user.count({ where: { role: Role.PATIENT } }),
        prisma.user.count({ where: { role: Role.DOCTOR } }),
        prisma.user.count({ where: { role: Role.HOSPITAL_ADMIN } }),
        prisma.user.count({ where: { role: Role.AMBULANCE_DRIVER } }),
        prisma.user.count({ where: { role: Role.PLATFORM_ADMIN } }),
        prisma.user.count({ where: { verificationStatus: 'PENDING' } }),
        prisma.appointment.count(),
        prisma.medicalRecord.count(),
      ]);

      res.status(200).json({
        success: true,
        data: {
          stats: {
            users: {
              total: totalUsers,
              active: activeUsers,
              byRole: {
                PATIENT: patientCount,
                DOCTOR: doctorCount,
                HOSPITAL_ADMIN: hospitalAdminCount,
                DRIVER: driverCount,
                SUPER_ADMIN: superAdminCount,
              },
              pendingVerification: pendingVerificationCount,
            },
            operations: {
              totalAppointments,
              totalMedicalRecords,
              systemHealth: 'OPERATIONAL',
              timestamp: new Date().toISOString(),
            },
          },
          users: {
            total: totalUsers,
            active: activeUsers,
            byRole: {
              PATIENT: patientCount,
              DOCTOR: doctorCount,
              HOSPITAL_ADMIN: hospitalAdminCount,
              DRIVER: driverCount,
              SUPER_ADMIN: superAdminCount,
            },
            pendingVerification: pendingVerificationCount,
          },
          operations: {
            totalAppointments,
            totalMedicalRecords,
            systemHealth: 'OPERATIONAL',
            timestamp: new Date().toISOString(),
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieve audit logs of privileged administrative actions.
   */
  async getAuditLogs(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      res.status(200).json({
        success: true,
        data: {
          auditLogs: auditTrail,
          count: auditTrail.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Permanently delete a user account and cascade delete their profiles.
   */
  async deleteUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);

      const targetUser = await prisma.user.findUnique({
        where: { id },
      });

      if (!targetUser) {
        throw new NotFoundError('User not found');
      }

      if (isSuperAdmin(targetUser.role) && targetUser.id === req.user?.id) {
        throw new BadRequestError('Cannot delete your own Super Admin account');
      }

      await prisma.user.delete({
        where: { id },
      });

      recordAudit(
        req,
        'DELETE_USER',
        { id: targetUser.id, email: targetUser.email },
        { previousRole: targetUser.role }
      );

      res.status(200).json({
        success: true,
        message: `User account ${targetUser.email} permanently removed from ecosystem`,
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin retrieves all registered ambulance drivers & paramedics with verification status.
   */
  async getAmbulanceStaffList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { status, search } = req.query as any;

      const where: Prisma.AmbulanceStaffProfileWhereInput = {};

      if (status) {
        where.user = { verificationStatus: status as any };
      }

      if (search && search.trim().length > 0) {
        const query = search.trim();
        where.OR = [
          { fullName: { contains: query, mode: 'insensitive' } },
          { licenseNumber: { contains: query, mode: 'insensitive' } },
          { assignedVehicleNumber: { contains: query, mode: 'insensitive' } },
          { user: { email: { contains: query, mode: 'insensitive' } } },
          { user: { phone: { contains: query, mode: 'insensitive' } } },
        ];
      }

      const staff = await prisma.ambulanceStaffProfile.findMany({
        where,
        include: {
          user: {
            select: {
              id: true,
              email: true,
              phone: true,
              role: true,
              verificationStatus: true,
              isActive: true,
              createdAt: true,
              lastLoginAt: true,
            },
          },
        },
        orderBy: { user: { createdAt: 'desc' } },
      });

      res.status(200).json({
        success: true,
        data: {
          staff,
          ambulanceStaff: staff,
          count: staff.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin approves, rejects, or transitions verification status of an ambulance driver or paramedic.
   */
  async verifyAmbulanceStaff(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const { status, rejectionReason, notes } = req.body;
      const adminEmail = req.user?.email || 'superadmin@aarogya.ai';

      // Lookup ambulance staff by profile id or user id
      const staffProfile = await prisma.ambulanceStaffProfile.findFirst({
        where: {
          OR: [{ id }, { userId: id }],
        },
        include: { user: true },
      });

      if (!staffProfile) {
        throw new NotFoundError('Ambulance staff profile not found');
      }

      const isVerified = status === 'VERIFIED';
      const now = new Date();

      // Transactionally update User verification status and Staff Profile
      const [updatedUser, updatedProfile] = await prisma.$transaction([
        prisma.user.update({
          where: { id: staffProfile.userId },
          data: {
            verificationStatus: status,
          },
        }),
        prisma.ambulanceStaffProfile.update({
          where: { id: staffProfile.id },
          data: {
            verifiedAt: isVerified ? now : null,
            verifiedBy: isVerified ? adminEmail : null,
          },
        }),
      ]);

      // If an ambulance record is tied to this vehicle number, update its verification status
      if (staffProfile.assignedVehicleNumber) {
        await prisma.ambulance.updateMany({
          where: { vehicleNumber: staffProfile.assignedVehicleNumber },
          data: {
            verificationStatus: status,
            verifiedAt: isVerified ? now : null,
            verifiedBy: isVerified ? adminEmail : null,
            rejectionReason: rejectionReason || notes || null,
          },
        });
      }

      recordAudit(
        req,
        isVerified ? 'VERIFY_AMBULANCE_DRIVER' : 'UPDATE_DRIVER_VERIFICATION',
        { id: updatedUser.id, email: updatedUser.email },
        {
          previousStatus: staffProfile.user.verificationStatus,
          newStatus: status,
          driverName: staffProfile.fullName,
          vehiclePlate: staffProfile.assignedVehicleNumber,
          licenseNumber: staffProfile.licenseNumber,
          rejectionReason: rejectionReason || notes,
        }
      );

      // Real-time Socket.IO notification to driver app
      socketService.emitDriverVerificationUpdate(updatedUser.id, {
        status,
        verifiedAt: isVerified ? now.toISOString() : undefined,
        verifiedBy: isVerified ? adminEmail : undefined,
        driverName: staffProfile.fullName,
      });

      res.status(200).json({
        success: true,
        message: `Driver ${staffProfile.fullName} verification status updated to ${status}`,
        data: {
          driver: {
            id: updatedProfile.id,
            userId: updatedUser.id,
            fullName: updatedProfile.fullName,
            licenseNumber: updatedProfile.licenseNumber,
            assignedVehicleNumber: updatedProfile.assignedVehicleNumber,
            verificationStatus: updatedUser.verificationStatus,
            verifiedAt: updatedProfile.verifiedAt,
            verifiedBy: updatedProfile.verifiedBy,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin real-time emergency overview (all SOS incidents, active radar, assigned units)
   */
  async getEmergencies(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { status, limit = 50 } = req.query as any;
      const where: Prisma.EmergencyRequestWhereInput = {};
      if (status && status !== 'ALL') {
        where.status = status;
      }

      const emergencies = await prisma.emergencyRequest.findMany({
        where,
        take: Number(limit),
        orderBy: { createdAt: 'desc' },
        include: {
          patientProfile: {
            include: {
              user: {
                select: {
                  email: true,
                  phone: true,
                },
              },
            },
          },
          selectedAmbulance: true,
        },
      });

      res.status(200).json({
        success: true,
        data: {
          emergencies,
          count: emergencies.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin platform-wide appointments monitoring desk
   */
  async getAppointments(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { status, limit = 50 } = req.query as any;
      const where: Prisma.AppointmentWhereInput = {};
      if (status && status !== 'ALL') {
        where.status = status;
      }

      const appointments = await prisma.appointment.findMany({
        where,
        take: Number(limit),
        orderBy: { startTime: 'desc' },
        include: {
          patientProfile: {
            include: {
              user: {
                select: {
                  email: true,
                  phone: true,
                },
              },
            },
          },
          doctorProfile: {
            include: {
              user: {
                select: {
                  email: true,
                  phone: true,
                },
              },
            },
          },
        },
      });

      res.status(200).json({
        success: true,
        data: {
          appointments,
          count: appointments.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin real-time system health and service telemetry
   */
  async getSystemHealth(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const dbStart = Date.now();
      await prisma.$queryRaw`SELECT 1`;
      const dbLatencyMs = Date.now() - dbStart;

      const memUsage = process.memoryUsage();
      const uptimeSec = Math.floor(process.uptime());

      res.status(200).json({
        success: true,
        data: {
          status: 'HEALTHY',
          uptime: `${Math.floor(uptimeSec / 3600)}h ${Math.floor((uptimeSec % 3600) / 60)}m ${uptimeSec % 60}s`,
          uptimeSeconds: uptimeSec,
          services: {
            database: {
              status: 'OPERATIONAL',
              latency: `${dbLatencyMs}ms`,
              engine: 'PostgreSQL Prisma ORM',
            },
            apiServer: {
              status: 'OPERATIONAL',
              port: process.env.PORT || 5000,
              nodeVersion: process.version,
            },
            socketService: {
              status: 'OPERATIONAL',
              mode: 'Real-time WebSocket & Polling Fallback',
            },
            memory: {
              rss: `${Math.round(memUsage.rss / 1024 / 1024)} MB`,
              heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`,
              heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)} MB`,
            },
          },
          settings: platformSettings,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin reviews incoming user feedback and issue reports
   */
  async getFeedback(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { status } = req.query as { status?: string };
      const feedback = communityService.getFeedbackList(status);
      res.status(200).json({
        success: true,
        data: {
          feedback,
          count: feedback.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin publishes platform announcements
   */
  async createAnnouncement(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { title, message, priority = 'INFO', targetRoles = ['ALL'], expiresAt } = req.body;
      if (!title || !message) {
        throw new BadRequestError('title and message are required');
      }

      const announcement = communityService.createAnnouncement({
        title: title.trim(),
        message: message.trim(),
        priority,
        targetRoles: Array.isArray(targetRoles) ? targetRoles : [targetRoles],
        publishedBy: (req as any).user?.email || 'Super Admin Desk',
        expiresAt,
      });

      recordAudit(req, 'CREATE_ANNOUNCEMENT', undefined, { title, priority });

      res.status(201).json({
        success: true,
        message: 'Platform announcement broadcast successfully',
        data: { announcement },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin publishes community health camp
   */
  async createHealthCamp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { title, organizer, category = 'GENERAL_CHECKUP', venue, city, startDate, endDate, timings, servicesOffered, contactPhone, isFree = true } = req.body;
      if (!title || !organizer || !venue || !city || !startDate || !contactPhone) {
        throw new BadRequestError('title, organizer, venue, city, startDate, and contactPhone are required');
      }

      const camp = communityService.createHealthCamp({
        title: title.trim(),
        organizer: organizer.trim(),
        category,
        venue: venue.trim(),
        city: city.trim(),
        startDate,
        endDate,
        timings: timings || '09:00 AM - 04:00 PM',
        servicesOffered: Array.isArray(servicesOffered) ? servicesOffered : [servicesOffered],
        contactPhone: contactPhone.trim(),
        isFree,
      });

      recordAudit(req, 'CREATE_HEALTH_CAMP', undefined, { title, city });

      res.status(201).json({
        success: true,
        message: 'Community health camp published successfully',
        data: { camp },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin creates a daily health tip
   */
  async createHealthTip(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { category = 'HEART', title, tip, actionableStep, author } = req.body;
      if (!title || !tip || !actionableStep) {
        throw new BadRequestError('title, tip, and actionableStep are required');
      }

      const healthTip = communityService.createHealthTip({
        category,
        title: title.trim(),
        tip: tip.trim(),
        actionableStep: actionableStep.trim(),
        author: author?.trim() || (req as any).user?.email || 'Aarogya Medical Desk',
      });

      recordAudit(req, 'CREATE_HEALTH_TIP', undefined, { title, category });

      res.status(201).json({
        success: true,
        message: 'Daily health tip published',
        data: { healthTip },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Super Admin views and updates global system configuration
   */
  async getSystemSettings(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      res.status(200).json({
        success: true,
        data: { settings: platformSettings },
      });
    } catch (error) {
      next(error);
    }
  },

  async updateSystemSettings(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { maintenanceMode, emergencyAutoDispatch, aiDiagnosticAssistance, maxTeleconsultationQueue } = req.body;

      if (maintenanceMode !== undefined) platformSettings.maintenanceMode = Boolean(maintenanceMode);
      if (emergencyAutoDispatch !== undefined) platformSettings.emergencyAutoDispatch = Boolean(emergencyAutoDispatch);
      if (aiDiagnosticAssistance !== undefined) platformSettings.aiDiagnosticAssistance = Boolean(aiDiagnosticAssistance);
      if (maxTeleconsultationQueue !== undefined) platformSettings.maxTeleconsultationQueue = Number(maxTeleconsultationQueue);

      recordAudit(req, 'UPDATE_PLATFORM_SETTINGS', undefined, platformSettings);

      res.status(200).json({
        success: true,
        message: 'Platform configuration updated',
        data: { settings: platformSettings },
      });
    } catch (error) {
      next(error);
    }
  },
};

