import { Request, Response, NextFunction } from 'express';
import { governmentService } from '../services/government.service';
import { BadRequestError } from '../utils/AppError';

export const governmentController = {
  // GET /government/blood-banks
  async getBloodBanks(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const city = req.query.city ? String(req.query.city) : undefined;
      const state = req.query.state ? String(req.query.state) : undefined;
      const district = req.query.district ? String(req.query.district) : undefined;
      const bloodGroup = req.query.bloodGroup ? String(req.query.bloodGroup) : undefined;
      const component = req.query.component ? String(req.query.component) : undefined;

      const result = await governmentService.getBloodBanks({ city, state, district, bloodGroup, component });
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /government/jan-aushadhi/medicines
  async getJanAushadhiMedicines(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const query = req.query.query ? String(req.query.query) : undefined;
      const category = req.query.category ? String(req.query.category) : undefined;

      const result = await governmentService.getJanAushadhiMedicines(query, category);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /government/jan-aushadhi/kendras
  async getJanAushadhiKendras(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const district = req.query.district ? String(req.query.district) : undefined;
      const state = req.query.state ? String(req.query.state) : undefined;
      const pincode = req.query.pincode ? String(req.query.pincode) : undefined;

      const kendras = await governmentService.getJanAushadhiKendras({ district, state, pincode });
      res.status(200).json({
        success: true,
        data: { kendras },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /government/pmjay/check-eligibility
  async checkAyushmanEligibility(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const identifier = String(req.query.identifier || '');
      if (!identifier) {
        throw new BadRequestError('Identifier (Aadhaar / Ration Card / Family ID) is required');
      }
      const result = await governmentService.checkAyushmanEligibility(identifier);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /government/pmjay/packages
  async getPmjayPackages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const specialty = req.query.specialty ? String(req.query.specialty) : undefined;
      const query = req.query.query ? String(req.query.query) : undefined;

      const packages = await governmentService.getPmjayPackages(specialty, query);
      res.status(200).json({
        success: true,
        data: { packages },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /government/hfr/facilities
  async getHfrFacilities(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const facilityType = req.query.facilityType ? String(req.query.facilityType) : undefined;
      const city = req.query.city ? String(req.query.city) : undefined;
      const state = req.query.state ? String(req.query.state) : undefined;

      const facilities = await governmentService.getHfrFacilities({ facilityType, city, state });
      res.status(200).json({
        success: true,
        data: { facilities },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /government/hpr/doctors
  async getHprPractitioners(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const specialization = req.query.specialization ? String(req.query.specialization) : undefined;
      const query = req.query.query ? String(req.query.query) : undefined;

      const doctors = await governmentService.getHprPractitioners(specialization, query);
      res.status(200).json({
        success: true,
        data: { doctors },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /government/uhi/slots
  async searchUhiSlots(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const specialty = req.query.specialty ? String(req.query.specialty) : undefined;
      const city = req.query.city ? String(req.query.city) : undefined;

      const slots = await governmentService.searchUhiSlots(specialty, city);
      res.status(200).json({
        success: true,
        data: { slots },
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /government/opd/scan-and-share
  async scanAndShareOpd(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { patientProfileId, qrPayload } = req.body;
      if (!patientProfileId || !qrPayload) {
        throw new BadRequestError('patientProfileId and qrPayload are required');
      }
      const result = await governmentService.scanAndShareOpd(patientProfileId, qrPayload);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },
};

