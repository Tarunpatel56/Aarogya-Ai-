import { Request, Response, NextFunction } from 'express';
import { abdmService } from '../services/abdm.service';
import { BadRequestError } from '../utils/AppError';

export const abdmController = {
  // POST /abdm/generate-otp
  async generateOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { identifier, authMethod } = req.body;
      if (!identifier) {
        throw new BadRequestError('Identifier (Mobile or Aadhaar) is required');
      }
      const result = await abdmService.generateOtp(identifier, authMethod || 'AADHAAR_OTP');
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /abdm/create-or-link
  async createOrLinkAbha(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { patientProfileId, fullName, mobile, gender, dateOfBirth, authMethod, desiredAbhaAddress, otp, txnId } = req.body;
      if (!patientProfileId || !fullName || !mobile || !otp) {
        throw new BadRequestError('patientProfileId, fullName, mobile, and otp are required');
      }
      const profile = await abdmService.createOrLinkAbha(
        {
          patientProfileId,
          fullName,
          mobile,
          gender: gender || 'MALE',
          dateOfBirth: dateOfBirth || '1995-01-01',
          authMethod: authMethod || 'AADHAAR_OTP',
          desiredAbhaAddress,
        },
        otp,
        txnId || 'txn-sandbox'
      );
      res.status(200).json({
        success: true,
        data: { abhaProfile: profile },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /abdm/profile/:patientProfileId
  async getAbhaProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const patientProfileId = String(req.params.patientProfileId);
      const profile = await abdmService.getAbhaProfile(patientProfileId);
      res.status(200).json({
        success: true,
        data: { abhaProfile: profile },
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /abdm/consent/request
  async requestConsent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { abhaProfileId, requesterName, requesterRole, healthInfoTypes, dateRangeFrom, dateRangeTo, expiryDate, purposeCode } = req.body;
      if (!abhaProfileId || !requesterName) {
        throw new BadRequestError('abhaProfileId and requesterName are required');
      }
      const consent = await abdmService.requestConsent({
        abhaProfileId,
        requesterName,
        requesterRole: requesterRole || 'DOCTOR',
        purposeCode: purposeCode || 'CAREMGT',
        healthInfoTypes: healthInfoTypes || ['DISCHARGE_SUMMARY', 'PRESCRIPTION'],
        dateRangeFrom: dateRangeFrom || new Date(Date.now() - 86400000 * 30).toISOString(),
        dateRangeTo: dateRangeTo || new Date().toISOString(),
        expiryDate: expiryDate || new Date(Date.now() + 86400000 * 7).toISOString(),
      });
      res.status(201).json({
        success: true,
        data: { consent },
      });
    } catch (error) {
      next(error);
    }
  },

  // PATCH /abdm/consent/:id/action
  async updateConsent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const { action } = req.body;
      if (!action || !['GRANT', 'DENY', 'REVOKE'].includes(action)) {
        throw new BadRequestError('Action must be GRANT, DENY, or REVOKE');
      }
      const updated = await abdmService.updateConsentStatus(id, action);
      res.status(200).json({
        success: true,
        data: { consent: updated },
      });
    } catch (error) {
      next(error);
    }
  },
};

