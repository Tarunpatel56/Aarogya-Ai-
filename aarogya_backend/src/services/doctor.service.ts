import { prisma } from '../config/prisma';
import { VerificationStatus, Role, AssignmentStatus } from '@prisma/client';
import { BadRequestError, NotFoundError, ConflictError, ForbiddenError } from '../utils/AppError';
import { logger } from '../utils/logger';

export interface NearbyDoctorQuery {
  latitude: number;
  longitude: number;
  radiusKm?: number;
  specialization?: string;
  minExperience?: number;
  maxFee?: number;
  onlineOnly?: boolean;
  limit?: number;
  offset?: number;
}

export interface NearbyDoctorResult {
  id: string;
  userId: string;
  fullName: string;
  specialization: string;
  qualifications: string;
  experienceYears: number;
  consultationFee: number;
  hospitalAffiliation: string | null;
  clinicName: string | null;
  clinicAddress: string | null;
  latitude: number;
  longitude: number;
  distanceKm: number;
  isOnline: boolean;
  verificationStatus: VerificationStatus;
  availableTimings: string[];
}

export class DoctorService {
  /**
   * Calculate Haversine spherical distance between two GPS coordinates in kilometers
   */
  public calculateHaversineDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number {
    const R = 6371; // Earth's mean radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return +(R * c).toFixed(2);
  }

  /**
   * Find verified doctors sorted by actual geographical distance with progressive radius expansion
   */
  public async findNearbyDoctors(query: NearbyDoctorQuery): Promise<{
    count: number;
    searchedRadiusKm: number;
    doctors: NearbyDoctorResult[];
    expandedSearch: boolean;
  }> {
    const { latitude, longitude, specialization, minExperience, maxFee, onlineOnly } = query;
    const limit = query.limit || 20;
    const offset = query.offset || 0;

    let searchRadius = query.radiusKm || 10;
    let expandedSearch = false;

    // Define progressive radii: e.g. 5km -> 10km -> 20km -> 50km -> 100km
    const radiusProgression = [5, 10, 20, 50, 100];

    // Find doctors with location coordinates
    const baseWhere: any = {
      user: {
        verificationStatus: { in: [VerificationStatus.VERIFIED, VerificationStatus.PENDING] },
        isActive: true,
      },
      status: 'ACTIVE',
    };

    if (specialization && specialization.toLowerCase() !== 'all') {
      baseWhere.specialization = { contains: specialization, mode: 'insensitive' };
    }
    if (minExperience !== undefined) {
      baseWhere.experienceYears = { gte: minExperience };
    }
    if (maxFee !== undefined) {
      baseWhere.consultationFee = { lte: maxFee };
    }
    if (onlineOnly) {
      baseWhere.isOnline = true;
    }

    // Attempt retrieval with current radius, expanding progressively if 0 results
    let matchedDoctors: any[] = [];
    let effectiveRadius = searchRadius;

    for (const radius of radiusProgression) {
      if (radius < searchRadius) continue;
      effectiveRadius = radius;

      // 1 deg latitude ~ 111.045 km
      const latDelta = radius / 111.045;
      const lngDelta = radius / (111.045 * Math.cos((latitude * Math.PI) / 180));

      const candidates = await prisma.doctorProfile.findMany({
        where: {
          ...baseWhere,
          latitude: {
            gte: latitude - latDelta,
            lte: latitude + latDelta,
          },
          longitude: {
            gte: longitude - lngDelta,
            lte: longitude + lngDelta,
          },
        },
        include: {
          user: {
            select: {
              id: true,
              email: true,
              phone: true,
              verificationStatus: true,
            },
          },
          availabilities: {
            where: {
              status: 'AVAILABLE',
              endTime: { gte: new Date() },
            },
            take: 5,
          },
        },
      });

      // Filter by exact spherical distance
      const filtered = candidates
        .map((doc) => {
          const dist = this.calculateHaversineDistance(
            latitude,
            longitude,
            doc.latitude!,
            doc.longitude!
          );
          return { ...doc, distanceKm: dist };
        })
        .filter((doc) => doc.distanceKm <= radius)
        .sort((a, b) => a.distanceKm - b.distanceKm);

      if (filtered.length > 0 || radius === radiusProgression[radiusProgression.length - 1]) {
        matchedDoctors = filtered;
        if (radius > searchRadius) {
          expandedSearch = true;
        }
        break;
      }
    }

    const paginated = matchedDoctors.slice(offset, offset + limit).map((doc) => ({
      id: doc.id,
      userId: doc.userId,
      fullName: doc.fullName,
      specialization: doc.specialization,
      qualifications: doc.qualifications,
      experienceYears: doc.experienceYears,
      consultationFee: doc.consultationFee || 0,
      hospitalAffiliation: doc.hospitalAffiliation,
      clinicName: doc.clinicName,
      clinicAddress: doc.clinicAddress,
      latitude: doc.latitude!,
      longitude: doc.longitude!,
      distanceKm: doc.distanceKm,
      isOnline: doc.isOnline,
      verificationStatus: doc.user.verificationStatus,
      availableTimings: doc.availabilities.map(
        (a: any) =>
          `${new Date(a.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} - ${new Date(a.endTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`
      ),
    }));

    return {
      count: matchedDoctors.length,
      searchedRadiusKm: effectiveRadius,
      doctors: paginated,
      expandedSearch,
    };
  }

  /**
   * Assign or update a patient's primary doctor
   */
  public async assignPrimaryDoctor(
    patientProfileId: string,
    doctorProfileId: string,
    changeReason?: string,
    assignedByRole: Role = Role.PATIENT
  ) {
    const doctor = await prisma.doctorProfile.findUnique({
      where: { id: doctorProfileId },
      include: { user: true },
    });

    if (!doctor) {
      throw new NotFoundError('Doctor not found');
    }

    if (doctor.user.verificationStatus !== VerificationStatus.VERIFIED || !doctor.user.isActive) {
      throw new BadRequestError('Only verified and active doctors can be assigned as a primary doctor');
    }

    return prisma.$transaction(async (tx) => {
      // Find current active assignment if any
      const currentActive = await tx.patientDoctorAssignment.findFirst({
        where: {
          patientProfileId,
          status: AssignmentStatus.ACTIVE,
        },
      });

      if (currentActive && currentActive.doctorProfileId === doctorProfileId) {
        return currentActive; // Already assigned to this doctor
      }

      // Mark current assignment as CHANGED
      if (currentActive) {
        await tx.patientDoctorAssignment.update({
          where: { id: currentActive.id },
          data: {
            status: AssignmentStatus.CHANGED,
            endedAt: new Date(),
            changeReason: changeReason || 'Patient changed primary doctor selection',
          },
        });

        // Record into history
        await tx.assignmentHistory.create({
          data: {
            patientProfileId,
            doctorProfileId,
            previousDoctorId: currentActive.doctorProfileId,
            reason: changeReason || 'Primary doctor transition',
            changedByRole: assignedByRole,
          },
        });
      } else {
        // Initial assignment
        await tx.assignmentHistory.create({
          data: {
            patientProfileId,
            doctorProfileId,
            previousDoctorId: null,
            reason: 'Initial primary doctor selection',
            changedByRole: assignedByRole,
          },
        });
      }

      // Create new ACTIVE assignment
      const newAssignment = await tx.patientDoctorAssignment.create({
        data: {
          patientProfileId,
          doctorProfileId,
          status: AssignmentStatus.ACTIVE,
          assignedByRole,
          changeReason,
        },
        include: {
          doctorProfile: {
            include: {
              user: {
                select: {
                  id: true,
                  email: true,
                  phone: true,
                  verificationStatus: true,
                },
              },
            },
          },
        },
      });

      logger.info('Primary doctor assigned successfully', {
        patientProfileId,
        doctorProfileId,
        previousDoctorId: currentActive?.doctorProfileId || null,
      });

      return newAssignment;
    });
  }

  /**
   * Retrieve patient's current primary doctor
   */
  public async getPrimaryDoctor(patientProfileId: string) {
    const assignment = await prisma.patientDoctorAssignment.findFirst({
      where: {
        patientProfileId,
        status: AssignmentStatus.ACTIVE,
      },
      include: {
        doctorProfile: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                phone: true,
                verificationStatus: true,
              },
            },
            availabilities: {
              where: {
                status: 'AVAILABLE',
                endTime: { gte: new Date() },
              },
              take: 5,
            },
          },
        },
      },
    });

    if (!assignment) {
      return null;
    }

    return {
      assignmentId: assignment.id,
      assignedAt: assignment.assignedAt,
      doctor: assignment.doctorProfile,
    };
  }

  /**
   * Strict request routing verification: Ensures patient consultation/appointment
   * requests are routed ONLY to their assigned primary doctor.
   */
  public async validateRequestRouting(patientProfileId: string, targetDoctorProfileId: string): Promise<void> {
    const activeAssignment = await prisma.patientDoctorAssignment.findFirst({
      where: {
        patientProfileId,
        status: AssignmentStatus.ACTIVE,
      },
    });

    if (!activeAssignment) {
      throw new BadRequestError(
        'You do not have an assigned primary doctor. Please select and assign a verified primary doctor before requesting a consultation.'
      );
    }

    if (activeAssignment.doctorProfileId !== targetDoctorProfileId) {
      throw new ForbiddenError(
        'Request routing violation: You can only route consultations and appointment requests to your assigned primary doctor. Use the Change Doctor flow if you wish to consult another physician.'
      );
    }
  }

  /**
   * Retrieves all active assigned patients for a doctor
   */
  public async getAssignedPatients(doctorProfileId: string) {
    const assignments = await prisma.patientDoctorAssignment.findMany({
      where: {
        doctorProfileId,
        status: AssignmentStatus.ACTIVE,
      },
      include: {
        patientProfile: {
          include: {
            user: {
              select: {
                id: true,
                email: true,
                phone: true,
              },
            },
            vitalReadings: {
              orderBy: { measuredAt: 'desc' },
              take: 5,
            },
          },
        },
      },
      orderBy: { assignedAt: 'desc' },
    });

    return {
      count: assignments.length,
      patients: assignments.map((a) => ({
        assignmentId: a.id,
        assignedAt: a.assignedAt,
        patient: a.patientProfile,
      })),
    };
  }

  /**
   * Automatically ensure standard 30-minute duty consultation slots exist for an active/on-duty doctor.
   * Generates slots for today (starting next upcoming 30m block up to 18:30 IST) and tomorrow (09:00 - 18:30 IST).
   */
  public async ensureDutySlotsForDoctor(doctorProfileId: string): Promise<number> {
    const now = new Date();

    // Check existing upcoming available slots
    const existingSlots = await prisma.doctorAvailability.findMany({
      where: {
        doctorProfileId,
        status: 'AVAILABLE',
        endTime: { gte: now },
      },
      select: {
        startTime: true,
        endTime: true,
      },
    });

    // If doctor already has 6 or more upcoming slots published, no need to auto-generate
    if (existingSlots.length >= 6) {
      return existingSlots.length;
    }

    const slotsToCreate: {
      doctorProfileId: string;
      startTime: Date;
      endTime: Date;
      timeZone: string;
      status: 'AVAILABLE';
      isRecurring: boolean;
      dayOfWeek: number;
    }[] = [];

    // IST is UTC+5:30. Let's compute slots in IST
    const istOffsetMs = 5.5 * 60 * 60 * 1000;

    // Days to generate: today (day 0) and tomorrow (day 1)
    for (let dayOffset = 0; dayOffset <= 1; dayOffset++) {
      const targetDate = new Date(now.getTime() + dayOffset * 24 * 60 * 60 * 1000);
      const istDate = new Date(targetDate.getTime() + istOffsetMs);

      const year = istDate.getUTCFullYear();
      const month = istDate.getUTCMonth();
      const date = istDate.getUTCDate();

      // Clinic duty hours: 09:00 to 18:30 (with lunch 13:00 - 14:00)
      const startHour = 9;
      const endHour = 18;

      for (let h = startHour; h < endHour; h++) {
        // Skip lunch hour 13:00-14:00
        if (h === 13) continue;

        for (const m of [0, 30]) {
          // Construct UTC equivalent of IST time
          // (h:m IST) = (h - 5 hours, m - 30 mins) UTC
          const slotStartUtc = new Date(Date.UTC(year, month, date, h, m) - istOffsetMs);
          const slotEndUtc = new Date(slotStartUtc.getTime() + 30 * 60 * 1000);

          // If slot is in the past (e.g. today earlier than now + 10 min), skip
          if (slotStartUtc.getTime() <= now.getTime() + 10 * 60 * 1000) {
            continue;
          }

          // Check if overlaps with an existing slot in existingSlots
          const overlaps = existingSlots.some(
            (s) => s.startTime < slotEndUtc && s.endTime > slotStartUtc
          );

          if (!overlaps) {
            slotsToCreate.push({
              doctorProfileId,
              startTime: slotStartUtc,
              endTime: slotEndUtc,
              timeZone: 'Asia/Kolkata',
              status: 'AVAILABLE',
              isRecurring: false,
              dayOfWeek: slotStartUtc.getUTCDay(),
            });
          }
        }
      }
    }

    if (slotsToCreate.length > 0) {
      await prisma.doctorAvailability.createMany({
        data: slotsToCreate,
        skipDuplicates: true,
      });
      logger.info(`Generated ${slotsToCreate.length} duty consultation slots for doctor ${doctorProfileId}`);
    }

    return existingSlots.length + slotsToCreate.length;
  }
}

export const doctorService = new DoctorService();

