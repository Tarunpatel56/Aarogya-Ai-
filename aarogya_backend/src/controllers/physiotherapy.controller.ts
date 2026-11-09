import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/prisma';
import { NotFoundError } from '../utils/AppError';

export const physiotherapyController = {
  /**
   * Save a real-time on-device MediaPipe physiotherapy session report.
   */
  async saveSession(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;

      // 1. Find or auto-heal patient profile
      let patient = await prisma.patientProfile.findUnique({
        where: { userId },
      });

      if (!patient) {
        patient = await prisma.patientProfile.create({
          data: {
            userId,
            fullName: req.user?.email?.split('@')[0] || 'Aarogya Patient',
            bloodGroup: 'UNKNOWN',
          },
        });
      }

      const {
        sessionId,
        exerciseName,
        exerciseCategory,
        durationSeconds,
        completedReps,
        targetReps,
        averageFormAccuracy,
        painRatingVAS,
        difficultyFeedback,
        minAngle,
        maxAngle,
        targetAngleMin,
        targetAngleMax,
        postureErrors,
        repHistory,
        inferenceEngine,
        hardwareDelegate,
        averageFps,
        averageLatencyMs,
        status,
        notes,
      } = req.body;

      const session = await prisma.physiotherapySession.create({
        data: {
          id: sessionId || undefined,
          patientProfileId: patient.id,
          exerciseName: exerciseName || 'Exercise',
          exerciseCategory: exerciseCategory || 'REHABILITATION',
          durationSeconds: Number(durationSeconds) || 0,
          completedReps: Number(completedReps) || 0,
          targetReps: Number(targetReps) || 10,
          averageFormAccuracy: Number(averageFormAccuracy) || 0.0,
          painRatingVAS: Number(painRatingVAS) || 0,
          difficultyFeedback: difficultyFeedback || 'Just Right',
          minAngle: minAngle != null ? Number(minAngle) : null,
          maxAngle: maxAngle != null ? Number(maxAngle) : null,
          targetAngleMin: targetAngleMin != null ? Number(targetAngleMin) : null,
          targetAngleMax: targetAngleMax != null ? Number(targetAngleMax) : null,
          postureErrors: postureErrors || [],
          repHistory: repHistory || [],
          inferenceEngine: inferenceEngine || 'MediaPipe Lite',
          hardwareDelegate: hardwareDelegate || 'GPU',
          averageFps: Number(averageFps) || 30.0,
          averageLatencyMs: Number(averageLatencyMs) || 18.0,
          status: status || 'COMPLETED',
          notes: notes || null,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Physiotherapy session recorded successfully',
        data: { session },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieves the authenticated patient's session history.
   */
  async getPatientSessions(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.id;
      const patient = await prisma.patientProfile.findUnique({
        where: { userId },
      });

      if (!patient) {
        res.status(200).json({
          success: true,
          data: { sessions: [] },
        });
        return;
      }

      const sessions = await prisma.physiotherapySession.findMany({
        where: { patientProfileId: patient.id },
        orderBy: { createdAt: 'desc' },
        take: 50,
      });

      res.status(200).json({
        success: true,
        data: { sessions },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Retrieve a single physiotherapy session report by ID.
   */
  async getSessionById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const session = await prisma.physiotherapySession.findUnique({
        where: { id },
        include: {
          patientProfile: {
            select: {
              id: true,
              fullName: true,
              dateOfBirth: true,
              gender: true,
            },
          },
        },
      });

      if (!session) {
        throw new NotFoundError('Physiotherapy session report not found');
      }

      res.status(200).json({
        success: true,
        data: { session },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Allows authorized doctors to view a patient's physiotherapy telemetry and ROM history.
   */
  async getDoctorPatientSessions(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const patientProfileId = req.params.patientProfileId as string;

      const patient = await prisma.patientProfile.findUnique({
        where: { id: patientProfileId },
        select: { id: true, fullName: true, dateOfBirth: true, gender: true },
      });

      if (!patient) {
        throw new NotFoundError('Patient profile not found');
      }

      const sessions = await prisma.physiotherapySession.findMany({
        where: { patientProfileId },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({
        success: true,
        data: {
          patient,
          sessions,
        },
      });
    } catch (error) {
      next(error);
    }
  },
};
