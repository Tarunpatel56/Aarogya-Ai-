import { Request, Response, NextFunction } from 'express';
import { mchService } from '../services/mch.service';
import { BadRequestError } from '../utils/AppError';

export const mchController = {
  // GET /mch/profiles/:patientProfileId
  async getProfiles(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const patientProfileId = String(req.params.patientProfileId);
      const profiles = await mchService.getMchProfiles(patientProfileId);
      res.status(200).json({
        success: true,
        data: { profiles },
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /mch/profiles
  async createProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { patientProfileId, profileType, fullName, dateOfBirthOrLMP, expectedDueDate, bloodGroup, rchId, highRiskFlags } = req.body;
      if (!patientProfileId || !profileType || !fullName || !dateOfBirthOrLMP) {
        throw new BadRequestError('patientProfileId, profileType, fullName, and dateOfBirthOrLMP are required');
      }

      const profile = await mchService.createMchProfile({
        patientProfileId,
        profileType,
        fullName,
        dateOfBirthOrLMP,
        expectedDueDate,
        bloodGroup,
        rchId,
        highRiskFlags,
      });

      res.status(201).json({
        success: true,
        data: { profile },
      });
    } catch (error) {
      next(error);
    }
  },

  // PATCH /mch/vaccine-status
  async updateVaccineStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { profileId, vaccineName, administeredDate } = req.body;
      if (!profileId || !vaccineName || !administeredDate) {
        throw new BadRequestError('profileId, vaccineName, and administeredDate are required');
      }

      const updated = await mchService.updateVaccineStatus(profileId, vaccineName, administeredDate);
      res.status(200).json({
        success: true,
        data: { profile: updated },
      });
    } catch (error) {
      next(error);
    }
  },
};

