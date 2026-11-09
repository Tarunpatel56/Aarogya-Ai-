import { Request, Response, NextFunction } from 'express';
import { vitalsService, VitalInput, DeviceConnectInput } from '../services/vitals.service';
import { prisma } from '../config/prisma';
import { Role, VitalMetricType } from '@prisma/client';
import { AppResponse } from '../utils/AppResponse';
import { BadRequestError, ForbiddenError, NotFoundError } from '../utils/AppError';

class VitalsController {
  /**
   * Helper to resolve target patientProfileId
   */
  private async resolvePatientProfileId(req: Request): Promise<string> {
    const user = req.user;
    if (!user) {
      throw new ForbiddenError('Authentication required');
    }

    if (user.role === Role.PATIENT) {
      const patient = await prisma.patientProfile.findUnique({
        where: { userId: user.id },
      });
      if (patient) return patient.id;

      // Auto-heal if missing
      const newProfile = await prisma.patientProfile.create({
        data: {
          userId: user.id,
          fullName: 'Patient ' + (user.email ? user.email.split('@')[0] : 'User'),
        },
      });
      return newProfile.id;
    }

    // Doctors or Admins can pass target patientProfileId via query or params
    if (user.role === Role.DOCTOR || user.role === Role.HOSPITAL_ADMIN || user.role === Role.PLATFORM_ADMIN) {
      const targetId = (req.query.patientProfileId as string) || (req.params.patientProfileId as string);
      if (!targetId) {
        throw new BadRequestError('patientProfileId query parameter is required for clinical personnel');
      }
      return targetId;
    }

    throw new ForbiddenError('Unauthorized to access patient vitals');
  }

  /**
   * POST /api/vitals/sync
   */
  public sync = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const payload = req.body;

      let readings: VitalInput[] = [];
      if (Array.isArray(payload.readings)) {
        readings = payload.readings;
      } else if (Array.isArray(payload)) {
        readings = payload;
      } else if (payload.metricType) {
        readings = [payload];
      } else {
        throw new BadRequestError('Request body must contain reading(s) or readings array');
      }

      const result = await vitalsService.syncVitals(patientProfileId, readings);
      return AppResponse.success(res, result, 'Vitals synchronized successfully', 201);
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /api/vitals/latest
   */
  public getLatest = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const result = await vitalsService.getLatestVitals(patientProfileId);
      return AppResponse.success(res, result, 'Latest vitals retrieved successfully');
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /api/vitals/history
   */
  public getHistory = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const metricType = req.query.metricType as VitalMetricType | undefined;
      const from = req.query.from ? new Date(req.query.from as string) : undefined;
      const to = req.query.to ? new Date(req.query.to as string) : undefined;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 100;

      const result = await vitalsService.getVitalsHistory(patientProfileId, metricType, from, to, limit);
      return AppResponse.success(res, result, 'Vitals history retrieved successfully');
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /api/vitals/summary
   */
  public getSummary = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const date = req.query.date ? new Date(req.query.date as string) : undefined;

      const result = await vitalsService.getVitalsSummary(patientProfileId, date);
      return AppResponse.success(res, result, 'Vitals summary calculated successfully');
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /api/devices
   */
  public getDevices = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const result = await vitalsService.getDevices(patientProfileId);
      return AppResponse.success(res, result, 'Paired devices retrieved successfully');
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /api/devices/connect
   */
  public connectDevice = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const input: DeviceConnectInput = req.body;
      const device = await vitalsService.connectDevice(patientProfileId, input);
      return AppResponse.success(res, { device }, 'Device connected and registered successfully', 201);
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /api/devices/disconnect
   */
  public disconnectDevice = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const macAddress = req.body.macAddress as string;
      if (!macAddress) {
        throw new BadRequestError('macAddress is required');
      }
      const result = await vitalsService.disconnectDevice(patientProfileId, macAddress);
      return AppResponse.success(res, result, 'Device disconnected successfully');
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /api/devices/status
   */
  public getDeviceStatus = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const patientProfileId = await this.resolvePatientProfileId(req);
      const macAddress = req.query.macAddress as string | undefined;
      const result = await vitalsService.getDeviceStatus(patientProfileId, macAddress);
      return AppResponse.success(res, result, 'Device status retrieved successfully');
    } catch (err) {
      next(err);
    }
  };
}

export const vitalsController = new VitalsController();

