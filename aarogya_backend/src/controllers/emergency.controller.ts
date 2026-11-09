import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import { NotFoundError, BadRequestError } from '../utils/AppError';
import { EmergencyStatus } from '@prisma/client';
import { socketService } from '../services/socket.service';

export const emergencyController = {
  /**
   * Activates Emergency SOS dispatch from patient GPS coordinates.
   */
  async createEmergencySos(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const { latitude, longitude, pickupAddress, vitalsSnapshot } = req.body;

      if (typeof latitude !== 'number' || typeof longitude !== 'number') {
        throw new BadRequestError('Valid GPS coordinates (latitude, longitude) are required for emergency dispatch');
      }

      const patient = await prisma.patientProfile.findUnique({
        where: { userId },
        include: { user: true },
      });

      if (!patient) {
        throw new NotFoundError('Patient profile not found');
      }

      // Check if patient already has an active emergency dispatch
      const existing = await prisma.emergencyRequest.findFirst({
        where: {
          patientProfileId: patient.id,
          status: {
            in: [
              EmergencyStatus.REQUESTED,
              EmergencyStatus.SEARCHING,
              EmergencyStatus.ASSIGNED,
              EmergencyStatus.EN_ROUTE,
              EmergencyStatus.PATIENT_ON_BOARD,
            ],
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      if (existing) {
        res.status(200).json({
          success: true,
          message: 'Active emergency dispatch already in progress',
          data: {
            emergency: existing,
          },
        });
        return;
      }

      // Find nearest hospital with emergency bay
      const hospitals = await prisma.hospital.findMany({
        where: { hasEmergencyBay: true },
      });

      let nearestHospital: any = null;
      let minDistance = Infinity;

      for (const h of hospitals) {
        const dLat = ((h.latitude - latitude) * Math.PI) / 180;
        const dLon = ((h.longitude - longitude) * Math.PI) / 180;
        const a =
          Math.sin(dLat / 2) * Math.sin(dLat / 2) +
          Math.cos((latitude * Math.PI) / 180) *
            Math.cos((h.latitude * Math.PI) / 180) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);
        const dist = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        if (dist < minDistance) {
          minDistance = dist;
          nearestHospital = h;
        }
      }

      // Estimated arrival time based on distance (minimum 4 mins, ~2 mins per km)
      const estimatedMinutes = Math.max(4, Math.min(18, Math.round(minDistance * 2.2)));

      const emergency = await prisma.emergencyRequest.create({
        data: {
          patientProfileId: patient.id,
          latitude,
          longitude,
          pickupAddress: pickupAddress || 'Current GPS Patient Location',
          assignedHospitalId: nearestHospital?.id,
          hospitalName: nearestHospital?.name || 'AIIMS Emergency Trauma Bay',
          assignedVehicleNo: null,
          assignedDriverId: null,
          status: EmergencyStatus.REQUESTED,
          estimatedMinutes: null,
          driverLatitude: null,
          driverLongitude: null,
          vitalsSnapshot: vitalsSnapshot || null,
        },
        include: {
          patientProfile: {
            include: {
              user: {
                select: {
                  phone: true,
                  email: true,
                },
              },
            },
          },
        },
      });

      // Broadcast emergency across Socket.IO to nearby ambulances & hospitals
      socketService.emitEmergencyBroadcast(emergency);

      res.status(201).json({
        success: true,
        message: 'Emergency SOS broadcasted. Searching for available ambulance...',
        data: {
          emergency: {
            ...emergency,
            patientName: patient.fullName,
            patientPhone: patient.user.phone,
            emergencyHotline: nearestHospital?.emergencyPhone || '102',
            driverName: null,
            driverPhone: null,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves current active emergency dispatch for authenticated patient.
   */
  async getActiveEmergency(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const patient = await prisma.patientProfile.findUnique({ where: { userId } });

      if (!patient) {
        throw new NotFoundError('Patient profile not found');
      }

      const active = await prisma.emergencyRequest.findFirst({
        where: {
          patientProfileId: patient.id,
          status: {
            in: [
              EmergencyStatus.REQUESTED,
              EmergencyStatus.SEARCHING,
              EmergencyStatus.ASSIGNED,
              EmergencyStatus.EN_ROUTE,
              EmergencyStatus.PATIENT_ON_BOARD,
            ],
          },
        },
        include: {
          patientProfile: {
            include: {
              user: {
                select: {
                  phone: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      let driverInfo: any = null;
      if (active?.assignedDriverId) {
        const staff = await prisma.ambulanceStaffProfile.findUnique({
          where: { userId: active.assignedDriverId },
          include: { user: true },
        });
        if (staff) {
          driverInfo = {
            driverName: staff.fullName,
            driverPhone: staff.user?.phone || '+91 98765 43210',
            assignedVehicleNo: staff.assignedVehicleNumber || active.assignedVehicleNo,
          };
        }
      }

      res.status(200).json({
        success: true,
        data: {
          hasActiveEmergency: !!active,
          emergency: active
            ? {
                ...active,
                ...(driverInfo || {}),
                patientName: active.patientProfile?.fullName,
                patientPhone: active.patientProfile?.user?.phone,
              }
            : null,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves single emergency request by ID.
   */
  async getEmergencyById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const emergency = await prisma.emergencyRequest.findUnique({
        where: { id },
        include: {
          patientProfile: {
            include: {
              user: {
                select: {
                  phone: true,
                },
              },
            },
          },
        },
      });

      if (!emergency) {
        throw new NotFoundError('Emergency dispatch request not found');
      }

      let driverInfo: any = null;
      if (emergency.assignedDriverId) {
        const staff = await prisma.ambulanceStaffProfile.findUnique({
          where: { userId: emergency.assignedDriverId },
          include: { user: true },
        });
        if (staff) {
          driverInfo = {
            driverName: staff.fullName,
            driverPhone: staff.user?.phone || '+91 98765 43210',
            assignedVehicleNo: staff.assignedVehicleNumber || emergency.assignedVehicleNo,
          };
        }
      }

      res.status(200).json({
        success: true,
        data: {
          emergency: {
            ...emergency,
            ...(driverInfo || {}),
            patientName: emergency.patientProfile?.fullName,
            patientPhone: emergency.patientProfile?.user?.phone,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Cancels active emergency request.
   */
  async cancelEmergency(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const existing = await prisma.emergencyRequest.findUnique({ where: { id } });

      if (!existing) {
        throw new NotFoundError('Emergency request not found');
      }

      const updated = await prisma.emergencyRequest.update({
        where: { id },
        data: {
          status: EmergencyStatus.CANCELLED,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Emergency request has been cancelled.',
        data: {
          emergency: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Step simulation: Moves ambulance 25% closer to patient and updates status.
   */
  async simulateProgress(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const emergency = await prisma.emergencyRequest.findUnique({ where: { id } });

      if (!emergency) {
        throw new NotFoundError('Emergency request not found');
      }

      if (emergency.status === EmergencyStatus.CANCELLED || emergency.status === EmergencyStatus.COMPLETED) {
        res.status(200).json({ success: true, data: { emergency } });
        return;
      }

      // Interpolate driver position 25% closer to patient coordinates
      const currentDriverLat = emergency.driverLatitude ?? emergency.latitude + 0.01;
      const currentDriverLng = emergency.driverLongitude ?? emergency.longitude + 0.01;
      const newDriverLat = currentDriverLat + (emergency.latitude - currentDriverLat) * 0.28;
      const newDriverLng = currentDriverLng + (emergency.longitude - currentDriverLng) * 0.28;

      let newStatus: EmergencyStatus = emergency.status;
      let newEta = Math.max(1, (emergency.estimatedMinutes ?? 8) - 2);

      if (newEta <= 2) {
        newStatus = EmergencyStatus.EN_ROUTE;
      }

      const updated = await prisma.emergencyRequest.update({
        where: { id },
        data: {
          driverLatitude: newDriverLat,
          driverLongitude: newDriverLng,
          estimatedMinutes: newEta,
          status: newStatus,
        },
      });

      res.status(200).json({
        success: true,
        data: {
          emergency: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },
};
