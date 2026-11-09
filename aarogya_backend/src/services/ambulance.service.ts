import { prisma } from '../config/prisma';
import {
  AmbulanceStatus,
  AmbulanceType,
  VerificationStatus,
  EmergencyStatus,
} from '@prisma/client';
import { BadRequestError, NotFoundError, ConflictError, ForbiddenError } from '../utils/AppError';
import { socketService } from './socket.service';
import { logger } from '../utils/logger';

export interface RegisterAmbulanceInput {
  driverUserId?: string;
  driverName: string;
  driverPhone: string;
  drivingLicenseNumber: string;
  vehicleNumber: string;
  ambulanceType?: AmbulanceType;
  organizationName?: string;
  hospitalId?: string;
  equipmentDetails?: string;
  photos?: string[];
  initialLatitude?: number;
  initialLongitude?: number;
}

export interface NearbyAmbulanceQuery {
  latitude: number;
  longitude: number;
  radiusKm?: number;
  ambulanceType?: AmbulanceType;
  limit?: number;
}

export class AmbulanceService {
  /**
   * Haversine spherical distance calculation in km
   */
  public calculateDistanceKm(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number {
    const R = 6371;
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
   * Realistic road ETA calculation based on geographic distance and urban traffic factor
   */
  public calculateRoadEtaMinutes(distanceKm: number): number {
    // Urban speed ~ 30 km/h with siren/emergency lane -> ~2.0 mins per km + 2 min prep/dispatch buffer
    return Math.max(3, Math.round(distanceKm * 2.0 + 2));
  }

  /**
   * Centralized registration for an ambulance and its primary driver
   */
  public async registerAmbulance(input: RegisterAmbulanceInput) {
    const normalizedVehicleNumber = input.vehicleNumber.trim().toUpperCase();

    // Check vehicle collision
    const existingVehicle = await prisma.ambulance.findUnique({
      where: { vehicleNumber: normalizedVehicleNumber },
    });

    if (existingVehicle) {
      throw new ConflictError(`Ambulance with vehicle number ${normalizedVehicleNumber} is already registered`);
    }

    const ambulance = await prisma.ambulance.create({
      data: {
        driverUserId: input.driverUserId,
        driverName: input.driverName.trim(),
        driverPhone: input.driverPhone.trim(),
        drivingLicenseNumber: input.drivingLicenseNumber.trim().toUpperCase(),
        vehicleNumber: normalizedVehicleNumber,
        ambulanceType: input.ambulanceType || AmbulanceType.ADVANCED_LIFE_SUPPORT,
        organizationName: input.organizationName?.trim() || 'Aarogya Rapid Fleet',
        hospitalId: input.hospitalId,
        equipmentDetails: input.equipmentDetails?.trim() || 'Oxygen cylinder, Defibrillator, Basic ALS kit',
        photos: input.photos || [],
        verificationStatus: VerificationStatus.PENDING,
        currentStatus: AmbulanceStatus.OFFLINE,
        latitude: input.initialLatitude ?? null,
        longitude: input.initialLongitude ?? null,
        lastLocationUpdate: input.initialLatitude ? new Date() : null,
      },
    });

    logger.info('Ambulance registered with PENDING verification', {
      ambulanceId: ambulance.id,
      vehicleNumber: ambulance.vehicleNumber,
    });

    return ambulance;
  }

  /**
   * Authoritative admin verification of an ambulance
   */
  public async verifyAmbulance(
    ambulanceId: string,
    status: VerificationStatus,
    adminUserId: string,
    rejectionReason?: string
  ) {
    const ambulance = await prisma.ambulance.findUnique({
      where: { id: ambulanceId },
    });

    if (!ambulance) {
      throw new NotFoundError('Ambulance not found');
    }

    const updated = await prisma.ambulance.update({
      where: { id: ambulanceId },
      data: {
        verificationStatus: status,
        verifiedAt: status === VerificationStatus.VERIFIED ? new Date() : null,
        verifiedBy: status === VerificationStatus.VERIFIED ? adminUserId : null,
        rejectionReason: status === VerificationStatus.REJECTED ? rejectionReason : null,
        currentStatus: status === VerificationStatus.VERIFIED ? AmbulanceStatus.AVAILABLE : AmbulanceStatus.OFFLINE,
      },
    });

    logger.info('Ambulance verification updated', {
      ambulanceId,
      status,
      adminUserId,
    });

    return updated;
  }

  /**
   * Driver operational status update (AVAILABLE, BUSY, OFFLINE, ON_TRIP)
   */
  public async updateOperationalStatus(
    ambulanceId: string,
    status: AmbulanceStatus,
    driverUserId?: string
  ) {
    const ambulance = await prisma.ambulance.findUnique({
      where: { id: ambulanceId },
    });

    if (!ambulance) {
      throw new NotFoundError('Ambulance not found');
    }

    if (driverUserId && ambulance.driverUserId && ambulance.driverUserId !== driverUserId) {
      throw new ForbiddenError('Unauthorized: You can only update your own assigned ambulance');
    }

    if (ambulance.verificationStatus !== VerificationStatus.VERIFIED) {
      throw new ForbiddenError('Unverified ambulances cannot be marked AVAILABLE');
    }

    const updated = await prisma.ambulance.update({
      where: { id: ambulanceId },
      data: {
        currentStatus: status,
      },
    });

    // Notify rooms
    socketService.emitToRoom(`ambulance:${ambulanceId}`, 'ambulance:status_updated', {
      ambulanceId,
      status,
      timestamp: new Date().toISOString(),
    });

    return updated;
  }

  /**
   * Stream live GPS location from moving ambulance
   */
  public async updateLocation(
    ambulanceId: string,
    latitude: number,
    longitude: number,
    speed?: number,
    heading?: number,
    driverUserId?: string
  ) {
    const ambulance = await prisma.ambulance.findUnique({
      where: { id: ambulanceId },
    });

    if (!ambulance) {
      throw new NotFoundError('Ambulance not found');
    }

    if (driverUserId && ambulance.driverUserId && ambulance.driverUserId !== driverUserId) {
      throw new ForbiddenError('Unauthorized to update location for this ambulance');
    }

    const now = new Date();

    const [updated] = await prisma.$transaction([
      prisma.ambulance.update({
        where: { id: ambulanceId },
        data: {
          latitude,
          longitude,
          speed: speed ?? null,
          heading: heading ?? null,
          lastLocationUpdate: now,
        },
      }),
      prisma.ambulanceLocationHistory.create({
        data: {
          ambulanceId,
          latitude,
          longitude,
          speed,
          heading,
          timestamp: now,
        },
      }),
    ]);

    // Broadcast sub-second telemetry to active tracking rooms
    socketService.emitToRoom(`ambulance:${ambulanceId}`, 'ambulance:location_update', {
      ambulanceId,
      latitude,
      longitude,
      speed,
      heading,
      timestamp: now.toISOString(),
    });

    // If on active emergency trip, broadcast to emergency room
    const activeEmergency = await prisma.emergencyRequest.findFirst({
      where: {
        selectedAmbulanceId: ambulanceId,
        status: { in: [EmergencyStatus.ASSIGNED, EmergencyStatus.EN_ROUTE, EmergencyStatus.PATIENT_ON_BOARD] },
      },
    });

    if (activeEmergency) {
      socketService.emitAmbulanceLocation(activeEmergency.id, {
        emergencyId: activeEmergency.id,
        ambulanceId,
        latitude,
        longitude,
        speed,
        heading,
        timestamp: now.toISOString(),
      });
    }

    return updated;
  }

  /**
   * Real nearest verified & available ambulances discovery
   */
  public async findNearbyAmbulances(query: NearbyAmbulanceQuery) {
    const { latitude, longitude, ambulanceType } = query;
    const searchRadius = query.radiusKm || 15;
    const limit = query.limit || 10;

    const baseWhere: any = {
      verificationStatus: VerificationStatus.VERIFIED,
      currentStatus: AmbulanceStatus.AVAILABLE,
      latitude: { not: null },
      longitude: { not: null },
    };

    if (ambulanceType) {
      baseWhere.ambulanceType = ambulanceType;
    }

    // Bounding box filter for index scan
    const latDelta = searchRadius / 111.045;
    const lngDelta = searchRadius / (111.045 * Math.cos((latitude * Math.PI) / 180));

    const candidates = await prisma.ambulance.findMany({
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
        hospital: {
          select: { id: true, name: true, contactPhone: true },
        },
      },
    });

    // Haversine exact sorting & realistic ETA computation
    const nearby = candidates
      .map((amb) => {
        const distanceKm = this.calculateDistanceKm(
          latitude,
          longitude,
          amb.latitude!,
          amb.longitude!
        );
        const estimatedMinutes = this.calculateRoadEtaMinutes(distanceKm);
        return {
          id: amb.id,
          vehicleNumber: amb.vehicleNumber,
          ambulanceType: amb.ambulanceType,
          driverName: amb.driverName,
          driverPhone: amb.driverPhone,
          organizationName: amb.organizationName || amb.hospital?.name || 'Aarogya Fleet',
          equipmentDetails: amb.equipmentDetails,
          currentStatus: amb.currentStatus,
          latitude: amb.latitude!,
          longitude: amb.longitude!,
          distanceKm,
          estimatedMinutes,
          photos: amb.photos,
        };
      })
      .filter((amb) => amb.distanceKm <= searchRadius)
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, limit);

    return {
      count: nearby.length,
      searchedRadiusKm: searchRadius,
      ambulances: nearby,
    };
  }

  /**
   * Dispatches emergency request strictly to ONE selected ambulance
   */
  public async dispatchToSelectedAmbulance(
    patientProfileId: string,
    selectedAmbulanceId: string,
    latitude: number,
    longitude: number,
    pickupAddress?: string,
    vitalsSnapshot?: any
  ) {
    const patient = await prisma.patientProfile.findUnique({
      where: { id: patientProfileId },
      include: { user: true },
    });

    if (!patient) {
      throw new NotFoundError('Patient profile not found');
    }

    // Atomic claim check on ambulance
    return prisma.$transaction(async (tx) => {
      const ambulance = await tx.ambulance.findUnique({
        where: { id: selectedAmbulanceId },
      });

      if (!ambulance) {
        throw new NotFoundError('Selected ambulance not found');
      }

      if (ambulance.verificationStatus !== VerificationStatus.VERIFIED) {
        throw new BadRequestError('Selected ambulance is not verified');
      }

      if (ambulance.currentStatus !== AmbulanceStatus.AVAILABLE) {
        throw new ConflictError(`Selected ambulance is currently ${ambulance.currentStatus}. Please select another available vehicle.`);
      }

      // Calculate initial distance & ETA
      const distanceKm = ambulance.latitude && ambulance.longitude
        ? this.calculateDistanceKm(latitude, longitude, ambulance.latitude, ambulance.longitude)
        : 2.0;
      const estimatedMinutes = this.calculateRoadEtaMinutes(distanceKm);

      // Create emergency request explicitly bound to selected ambulance
      const emergency = await tx.emergencyRequest.create({
        data: {
          patientProfileId,
          selectedAmbulanceId,
          latitude,
          longitude,
          pickupAddress: pickupAddress || 'Current GPS Patient Coordinates',
          assignedDriverId: ambulance.driverUserId,
          assignedVehicleNo: ambulance.vehicleNumber,
          status: EmergencyStatus.REQUESTED,
          vitalsSnapshot: vitalsSnapshot ?? undefined,
          estimatedMinutes,
          driverLatitude: ambulance.latitude,
          driverLongitude: ambulance.longitude,
        },
      });

      // Mark ambulance BUSY during incoming ringing phase to prevent duplicate race conditions
      await tx.ambulance.update({
        where: { id: selectedAmbulanceId },
        data: { currentStatus: AmbulanceStatus.BUSY },
      });

      // Targeted point-to-point dispatch notification: ONLY to this ambulance
      const dispatchPayload = {
        emergencyId: emergency.id,
        patientName: patient.fullName,
        patientPhone: patient.user.phone || 'Emergency Contact',
        pickupAddress: emergency.pickupAddress,
        latitude: emergency.latitude,
        longitude: emergency.longitude,
        distanceKm,
        estimatedMinutes,
        vitalsSnapshot,
        timestamp: new Date().toISOString(),
      };

      // Emit strictly to this ambulance room and driver room
      socketService.emitToRoom(`ambulance:${selectedAmbulanceId}`, 'ambulance:dispatch_request', dispatchPayload);
      if (ambulance.driverUserId) {
        socketService.emitToUser(ambulance.driverUserId, 'ambulance:dispatch_request', dispatchPayload);
      }

      logger.info('Targeted emergency dispatch routed strictly to ambulance', {
        emergencyId: emergency.id,
        selectedAmbulanceId,
        vehicleNumber: ambulance.vehicleNumber,
      });

      return emergency;
    });
  }

  /**
   * Selected ambulance accepts emergency request
   */
  public async acceptDispatch(emergencyId: string, ambulanceId: string) {
    const emergency = await prisma.emergencyRequest.findUnique({
      where: { id: emergencyId },
    });

    if (!emergency) {
      throw new NotFoundError('Emergency request not found');
    }

    if (emergency.selectedAmbulanceId !== ambulanceId) {
      throw new ForbiddenError('Unauthorized: This dispatch was routed to a different ambulance');
    }

    return prisma.$transaction(async (tx) => {
      const updatedEmergency = await tx.emergencyRequest.update({
        where: { id: emergencyId },
        data: {
          status: EmergencyStatus.ASSIGNED,
        },
        include: {
          patientProfile: {
            include: { user: true },
          },
          selectedAmbulance: true,
        },
      });

      await tx.ambulance.update({
        where: { id: ambulanceId },
        data: {
          currentStatus: AmbulanceStatus.ON_TRIP,
        },
      });

      // Notify emergency tracking room and patient
      socketService.emitEmergencyAccepted(emergencyId, {
        ambulance: updatedEmergency.selectedAmbulance,
        status: EmergencyStatus.ASSIGNED,
      });

      return updatedEmergency;
    });
  }

  /**
   * Selected ambulance rejects request: Enables patient to select next available vehicle
   */
  public async rejectDispatch(emergencyId: string, ambulanceId: string, reason: string) {
    const emergency = await prisma.emergencyRequest.findUnique({
      where: { id: emergencyId },
    });

    if (!emergency) {
      throw new NotFoundError('Emergency request not found');
    }

    if (emergency.selectedAmbulanceId !== ambulanceId) {
      throw new ForbiddenError('Unauthorized: This dispatch was routed to a different ambulance');
    }

    return prisma.$transaction(async (tx) => {
      // Revert ambulance back to AVAILABLE
      await tx.ambulance.update({
        where: { id: ambulanceId },
        data: { currentStatus: AmbulanceStatus.AVAILABLE },
      });

      // Update emergency request with rejection log and prompt patient fallback
      const updatedEmergency = await tx.emergencyRequest.update({
        where: { id: emergencyId },
        data: {
          status: EmergencyStatus.SEARCHING,
          selectedAmbulanceId: null,
          rejectionReason: reason || 'Driver unavailable or unable to accept dispatch',
          rejectedByAmbulanceIds: {
            push: ambulanceId,
          },
        },
      });

      // Notify patient so Flutter UI immediately prompts selection of another ambulance
      socketService.emitToRoom(`emergency:${emergencyId}`, 'emergency:dispatch_rejected', {
        emergencyId,
        rejectedAmbulanceId: ambulanceId,
        reason,
        canSelectAnother: true,
        timestamp: new Date().toISOString(),
      });

      logger.info('Dispatch rejected by selected ambulance; searching fallback enabled', {
        emergencyId,
        rejectedAmbulanceId: ambulanceId,
        reason,
      });

      return updatedEmergency;
    });
  }
}

export const ambulanceService = new AmbulanceService();

