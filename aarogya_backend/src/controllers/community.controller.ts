import { Request, Response, NextFunction } from 'express';
import { communityService } from '../services/community.service';
import { BadRequestError } from '../utils/AppError';

export const communityController = {
  // GET /community/government-schemes
  async getSchemes(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { category } = req.query as { category?: string };
      const schemes = communityService.getSchemes(category);
      res.status(200).json({
        success: true,
        data: {
          schemes,
          count: schemes.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /community/government-schemes/:id
  async getSchemeById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = String(req.params.id);
      const scheme = communityService.getSchemeById(id);
      if (!scheme) {
        res.status(404).json({ success: false, message: 'Government health scheme not found' });
        return;
      }
      res.status(200).json({
        success: true,
        data: { scheme },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /community/blood-donors
  async getBloodDonors(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { bloodGroup, city } = req.query as { bloodGroup?: string; city?: string };
      const donors = communityService.getBloodDonors(bloodGroup, city);
      res.status(200).json({
        success: true,
        data: {
          donors,
          count: donors.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /community/blood-donors
  async registerBloodDonor(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { fullName, bloodGroup, city, district, contactPhone, lastDonatedDate } = req.body;
      if (!fullName || !bloodGroup || !contactPhone || !city) {
        throw new BadRequestError('fullName, bloodGroup, city, and contactPhone are required');
      }

      const donor = communityService.registerBloodDonor({
        fullName: fullName.trim(),
        bloodGroup: bloodGroup.trim().toUpperCase(),
        city: city.trim(),
        district: district?.trim(),
        contactPhone: contactPhone.trim(),
        lastDonatedDate,
        isAvailable: true,
      });

      res.status(201).json({
        success: true,
        message: 'Successfully registered as voluntary blood donor',
        data: { donor },
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /community/blood-donors/request-sos
  async requestBloodSos(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { bloodGroup, hospitalName, city, contactPhone, unitsNeeded, notes } = req.body;
      if (!bloodGroup || !hospitalName || !city || !contactPhone) {
        throw new BadRequestError('bloodGroup, hospitalName, city, and contactPhone are required');
      }

      const alert = communityService.createBloodSosRequest({
        bloodGroup: String(bloodGroup).trim().toUpperCase(),
        hospitalName: String(hospitalName).trim(),
        city: String(city).trim(),
        contactPhone: String(contactPhone).trim(),
        unitsNeeded: unitsNeeded ? Number(unitsNeeded) : 1,
        notes: notes ? String(notes).trim() : undefined,
      });

      res.status(201).json({
        success: true,
        message: `Emergency SOS Alert broadcasted to all ${bloodGroup} donors in ${city}.`,
        data: { alert },
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /community/health-camps
  async submitHealthCamp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { title, organizer, category, venue, city, startDate, endDate, timings, servicesOffered, contactPhone, isFree, sourceType } = req.body;
      if (!title || !venue || !city || !startDate || !contactPhone) {
        throw new BadRequestError('title, venue, city, startDate, and contactPhone are required');
      }

      const camp = communityService.createHealthCamp({
        title: String(title).trim(),
        organizer: organizer ? String(organizer).trim() : 'Community Organizer',
        category: category || 'GENERAL_CHECKUP',
        venue: String(venue).trim(),
        city: String(city).trim(),
        startDate: String(startDate).trim(),
        endDate: endDate ? String(endDate).trim() : undefined,
        timings: timings ? String(timings).trim() : '09:00 AM - 04:00 PM',
        servicesOffered: Array.isArray(servicesOffered) ? servicesOffered : [servicesOffered || 'Free Health Checkup'],
        contactPhone: String(contactPhone).trim(),
        isFree: isFree !== false,
        sourceType: sourceType || 'DOCTOR_PARTNER',
      });

      res.status(201).json({
        success: true,
        message: 'Health Camp registered successfully and published to community feed.',
        data: { camp },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /community/health-camps
  async getHealthCamps(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { city, category } = req.query as { city?: string; category?: string };
      const camps = communityService.getHealthCamps(city, category);
      res.status(200).json({
        success: true,
        data: {
          camps,
          count: camps.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /community/vaccinations
  async getVaccines(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { category } = req.query as { category?: string };
      const vaccines = communityService.getVaccines(category);
      res.status(200).json({
        success: true,
        data: {
          vaccines,
          count: vaccines.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /community/medicine-safety/:drugName
  async getMedicineSafety(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const drugName = String(req.params.drugName || '');
      if (!drugName) {
        throw new BadRequestError('drugName parameter is required');
      }
      const safetyInfo = communityService.getMedicineSafety(drugName);
      res.status(200).json({
        success: true,
        data: { safetyInfo },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /community/announcements
  async getAnnouncements(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { role } = req.query as { role?: string };
      const announcements = communityService.getAnnouncements(role);
      res.status(200).json({
        success: true,
        data: {
          announcements,
          count: announcements.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  // POST /community/feedback
  async submitFeedback(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { role = 'PATIENT', category = 'GENERAL', rating = 5, subject, message } = req.body;
      if (!subject || !message) {
        throw new BadRequestError('subject and message are required');
      }

      const userEmail = (req as any).user?.email;
      const userId = (req as any).user?.id;

      const feedback = communityService.submitFeedback({
        userId,
        userEmail,
        role,
        category,
        rating: Number(rating),
        subject: subject.trim(),
        message: message.trim(),
      });

      res.status(201).json({
        success: true,
        message: 'Feedback submitted successfully. Thank you for helping improve Aarogya AI!',
        data: { feedback },
      });
    } catch (error) {
      next(error);
    }
  },

  // GET /community/health-tips
  async getHealthTips(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { category } = req.query as { category?: string };
      const tips = communityService.getHealthTips(category);
      res.status(200).json({
        success: true,
        data: {
          tips,
          count: tips.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },
};
