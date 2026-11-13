import { Router } from 'express';
import { placesController } from '../controllers/places.controller';

const router = Router();

router.get('/nearby', placesController.searchNearby);

export const placesRoutes = router;

