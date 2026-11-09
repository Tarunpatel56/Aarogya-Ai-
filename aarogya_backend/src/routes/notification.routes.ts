import { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import { notificationService } from '../services/notification.service';

const router = Router();

router.use(authenticate);

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const limit = req.query.limit ? parseInt(String(req.query.limit), 10) : 20;
    const offset = req.query.offset ? parseInt(String(req.query.offset), 10) : 0;
    const unreadOnly = req.query.unreadOnly === 'true';

    const result = await notificationService.getUserNotifications(userId, limit, offset, unreadOnly);

    res.status(200).json({
      success: true,
      data: result,
    });
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/read', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const notificationId = String(req.params.id);

    await notificationService.markAsRead(userId, notificationId);

    res.status(200).json({
      success: true,
      message: 'Notification marked as read',
    });
  } catch (error) {
    next(error);
  }
});

router.patch('/read-all', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;

    await notificationService.markAllAsRead(userId);

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error) {
    next(error);
  }
});

export const notificationRoutes = router;
