import { EventEmitter } from 'events';
import { NotificationType, Prisma } from '@prisma/client';
import { prisma } from '../config/prisma';
import { logger } from '../utils/logger';

export interface CreateNotificationParams {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  metadata?: Prisma.InputJsonValue;
}

class NotificationService extends EventEmitter {
  constructor() {
    super();
    // Allow clean internal listening
    this.setMaxListeners(20);
  }

  /**
   * Persists an internal in-app notification and emits an internal event.
   */
  async createNotification(params: CreateNotificationParams) {
    try {
      const notification = await prisma.notification.create({
        data: {
          userId: params.userId,
          type: params.type,
          title: params.title,
          message: params.message,
          metadata: params.metadata || Prisma.DbNull,
        },
      });

      this.emit('notification:created', notification);
      logger.info('Internal notification created', {
        userId: params.userId,
        type: params.type,
        title: params.title,
      });

      return notification;
    } catch (error: any) {
      logger.error('Failed to create notification', { error: error.message, params });
      // Non-blocking for primary appointment flow
      return null;
    }
  }

  /**
   * Fetches paginated notifications for a specific authenticated user.
   */
  async getUserNotifications(userId: string, limit = 20, offset = 0, unreadOnly = false) {
    const where: Prisma.NotificationWhereInput = {
      userId,
      ...(unreadOnly ? { isRead: false } : {}),
    };

    const [notifications, total, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      prisma.notification.count({ where }),
      prisma.notification.count({ where: { userId, isRead: false } }),
    ]);

    return {
      notifications,
      pagination: {
        total,
        unreadCount,
        limit,
        offset,
      },
    };
  }

  /**
   * Marks a notification as read with ownership verification.
   */
  async markAsRead(userId: string, notificationId: string) {
    return prisma.notification.updateMany({
      where: {
        id: notificationId,
        userId,
      },
      data: {
        isRead: true,
      },
    });
  }

  /**
   * Marks all notifications as read for a user.
   */
  async markAllAsRead(userId: string) {
    return prisma.notification.updateMany({
      where: {
        userId,
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });
  }
}

export const notificationService = new NotificationService();
