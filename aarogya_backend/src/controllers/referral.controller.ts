import { Request, Response, NextFunction } from 'express';
import { referralService } from '../services/referral.service';
import { BadRequestError } from '../utils/AppError';

export const referralController = {
  // POST /referrals
  async createReferral(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { patientProfileId, referringDoctorId, targetDoctorId, targetSpecialty, urgencyLevel, clinicalSummary, attachedRecordIds } = req.body;
      if (!patientProfileId || !referringDoctorId || !targetSpecialty || !clinicalSummary) {
        throw new BadRequestError('patientProfileId, referringDoctorId, targetSpecialty, and clinicalSummary are required');
      }

      const result = await referralService.createReferral({
        patientProfileId,
        referringDoctorId,
        targetDoctorId,
        targetSpecialty,
        urgencyLevel: urgencyLevel || 'ROUTINE',
        clinicalSummary,
        attachedRecordIds,
      });

      res.status(201).json({
        success: true,
        data: { referral: result },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /referrals/doctor/:doctorId
  async getDoctorReferrals(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const doctorId = String(req.params.doctorId);
      const result = await referralService.getDoctorReferrals(doctorId);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },

  // PATCH /referrals/:id/respond
  async respondToReferral(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const { doctorId, status, specialistNotes } = req.body;
      if (!doctorId || !status || !['ACCEPTED', 'DECLINED', 'COMPLETED'].includes(status)) {
        throw new BadRequestError('doctorId and valid status (ACCEPTED, DECLINED, COMPLETED) are required');
      }

      const updated = await referralService.respondToReferral(id, doctorId, status, specialistNotes);
      res.status(200).json({
        success: true,
        data: { referral: updated },
      });
    } catch (error) {
      next(error);
    }
  },
};

