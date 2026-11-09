import { Request, Response, NextFunction } from 'express';
import { EmergencyStatus } from '@prisma/client';
import { prisma } from '../config/prisma';
import { NotFoundError, BadRequestError } from '../utils/AppError';
import { socketService } from '../services/socket.service';

export const driverController = {
  /**
   * Retrieves the authenticated driver's profile and vehicle assignment.
   */
  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.ambulanceStaffProfile.findUnique({
        where: { userId },
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
            },
          },
        },
      });

      if (!profile) {
        throw new NotFoundError('Driver profile not found');
      }

      res.status(200).json({
        success: true,
        data: {
          profile,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Updates driver operational details (e.g., vehicle assignment or license updates).
   */
  async updateProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.ambulanceStaffProfile.findUnique({
        where: { userId },
      });

      if (!profile) {
        throw new NotFoundError('Driver profile not found');
      }

      const { fullName, assignedVehicleNumber, certificationLevel } = req.body;

      const updated = await prisma.ambulanceStaffProfile.update({
        where: { userId },
        data: {
          fullName: fullName !== undefined ? String(fullName).trim() : undefined,
          assignedVehicleNumber:
            assignedVehicleNumber !== undefined ? String(assignedVehicleNumber).trim() : undefined,
          certificationLevel:
            certificationLevel !== undefined ? String(certificationLevel).trim() : undefined,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Driver operational profile updated successfully',
        data: {
          profile: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves available emergency dispatches awaiting ambulance assignment
   */
  async getAvailableDispatches(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pendingDispatches = await prisma.emergencyRequest.findMany({
        where: {
          status: {
            in: [EmergencyStatus.REQUESTED, EmergencyStatus.SEARCHING, EmergencyStatus.ASSIGNED],
          },
          assignedDriverId: null,
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
        orderBy: {
          createdAt: 'desc',
        },
      });

      res.status(200).json({
        success: true,
        data: {
          dispatches: pendingDispatches,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Accepts an emergency dispatch request and assigns it to this driver
   */
  async acceptEmergencyDispatch(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const emergencyId = String(req.params.id);

      const profile = await prisma.ambulanceStaffProfile.findUnique({
        where: { userId },
        include: { user: true },
      });

      if (!profile) {
        throw new NotFoundError('Driver profile not found');
      }

      const emergency = await prisma.emergencyRequest.findUnique({
        where: { id: emergencyId },
      });

      if (!emergency) {
        throw new NotFoundError('Emergency dispatch request not found');
      }

      if (emergency.status === EmergencyStatus.COMPLETED || emergency.status === EmergencyStatus.CANCELLED) {
        throw new BadRequestError('Emergency request has already been completed or cancelled');
      }

      if (emergency.assignedDriverId && emergency.assignedDriverId !== userId) {
        throw new BadRequestError('Emergency request has already been claimed by another driver');
      }

      const updated = await prisma.emergencyRequest.update({
        where: { id: emergencyId },
        data: {
          assignedDriverId: userId,
          assignedVehicleNo: profile.assignedVehicleNumber || 'DL-01-AMB-8899',
          status: EmergencyStatus.ASSIGNED,
          estimatedMinutes: 6,
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
      });

      const driverPhone = profile.user?.phone || '+91 98765 43210';

      // Broadcast real-time Socket.IO notification to patient
      socketService.emitEmergencyAccepted(emergencyId, {
        emergency: {
          ...updated,
          driverName: profile.fullName,
          driverPhone,
          assignedVehicleNo: updated.assignedVehicleNo,
        },
        driverName: profile.fullName,
        driverPhone,
        vehicleNumber: updated.assignedVehicleNo,
        estimatedMinutes: 6,
      });

      res.status(200).json({
        success: true,
        message: 'Emergency dispatch accepted successfully',
        data: {
          emergency: {
            ...updated,
            driverName: profile.fullName,
            driverPhone,
            vehicleNumber: updated.assignedVehicleNo,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves ambulance trips or emergency requests assigned to this driver.
   */
  async getAssignedTrips(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      const profile = await prisma.ambulanceStaffProfile.findUnique({
        where: { userId },
      });

      if (!profile) {
        throw new NotFoundError('Driver profile not found');
      }

      // Query real PostgreSQL database for trips assigned to this driver
      const assigned = await prisma.emergencyRequest.findMany({
        where: {
          OR: [
            { assignedDriverId: userId },
            {
              assignedVehicleNo: profile.assignedVehicleNumber || '__none__',
            },
            {
              status: {
                in: [EmergencyStatus.REQUESTED, EmergencyStatus.SEARCHING],
              },
            },
          ],
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
        orderBy: {
          createdAt: 'desc',
        },
      });

      res.status(200).json({
        success: true,
        data: {
          driverId: userId,
          assignedVehicle: profile.assignedVehicleNumber,
          trips: assigned,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Updates status of an assigned ambulance trip.
   */
  async updateTripStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const tripId = String(req.params.id);
      const { status, vitalNotes, latitude, longitude, destinationHospitalId, destinationHospitalName } = req.body;

      const validStatuses: Record<string, EmergencyStatus> = {
        DISPATCHED: EmergencyStatus.ASSIGNED,
        ASSIGNED: EmergencyStatus.ASSIGNED,
        EN_ROUTE: EmergencyStatus.EN_ROUTE,
        PATIENT_ON_BOARD: EmergencyStatus.PATIENT_ON_BOARD,
        REACHED_HOSPITAL: EmergencyStatus.REACHED_HOSPITAL,
        COMPLETED: EmergencyStatus.COMPLETED,
        CANCELLED: EmergencyStatus.CANCELLED,
      };

      if (!status || !validStatuses[status]) {
        throw new BadRequestError(`Invalid status. Allowed values: ${Object.keys(validStatuses).join(', ')}`);
      }

      const targetStatus = validStatuses[status];

      const existing = await prisma.emergencyRequest.findUnique({
        where: { id: tripId },
      });

      if (!existing) {
        throw new NotFoundError('Assigned trip not found');
      }

      const updated = await prisma.emergencyRequest.update({
        where: { id: tripId },
        data: {
          status: targetStatus,
          assignedDriverId: req.user!.id,
          driverLatitude: latitude !== undefined ? Number(latitude) : undefined,
          driverLongitude: longitude !== undefined ? Number(longitude) : undefined,
          assignedHospitalId: destinationHospitalId !== undefined ? String(destinationHospitalId) : undefined,
          hospitalName: destinationHospitalName !== undefined ? String(destinationHospitalName) : undefined,
          vitalsSnapshot: vitalNotes ? { notes: vitalNotes, updatedAt: new Date().toISOString() } : undefined,
        },
        include: {
          patientProfile: true,
        },
      });

      // Real-time Socket.IO notification to Patient
      socketService.emitEmergencyStatusUpdate(tripId, targetStatus, {
        emergency: updated,
        status: targetStatus,
      });

      // If arriving or choosing hospital, alert the hospital trauma bay
      if (
        (targetStatus === EmergencyStatus.REACHED_HOSPITAL || targetStatus === EmergencyStatus.PATIENT_ON_BOARD) &&
        updated.assignedHospitalId
      ) {
        socketService.emitHospitalTraumaAlert(updated.assignedHospitalId, {
          emergencyId: tripId,
          patientName: updated.patientProfile?.fullName || 'Emergency Patient',
          status: targetStatus,
          etaMinutes: targetStatus === EmergencyStatus.REACHED_HOSPITAL ? 0 : 5,
        });
      }

      res.status(200).json({
        success: true,
        message: `Trip status updated to ${targetStatus}`,
        data: {
          trip: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  },
};
