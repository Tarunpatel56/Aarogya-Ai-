import { Request, Response, NextFunction } from 'express';
import { placesService } from '../services/places.service';
import { BadRequestError } from '../utils/AppError';

export const placesController = {
  // GET /places/nearby
  async searchNearby(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const lat = parseFloat(String(req.query.latitude || '22.7196'));
      const lng = parseFloat(String(req.query.longitude || '75.8577'));
      const category = req.query.category ? String(req.query.category) : undefined;
      const radiusMeters = req.query.radiusMeters ? parseInt(String(req.query.radiusMeters), 10) : undefined;
      const keyword = req.query.keyword ? String(req.query.keyword) : undefined;

      if (isNaN(lat) || isNaN(lng)) {
        throw new BadRequestError('Valid latitude and longitude numbers are required');
      }

      const result = await placesService.searchNearby({
        latitude: lat,
        longitude: lng,
        category,
        radiusMeters,
        keyword,
      });

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  },
};

