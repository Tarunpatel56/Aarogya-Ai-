import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { prisma } from '../config/prisma';
import { logger } from '../utils/logger';

export interface AuthenticatedSocketUser {
  id: string;
  email: string;
  role: string;
  verificationStatus: string;
}

export interface CustomSocket extends Socket {
  user?: AuthenticatedSocketUser;
}

class SocketService {
  private io: Server | null = null;

  /**
   * Initialize Socket.IO with the HTTP server
   */
  public init(httpServer: HttpServer): Server {
    if (this.io) {
      return this.io;
    }

    this.io = new Server(httpServer, {
      cors: {
        origin: (origin, callback) => callback(null, true),
        credentials: true,
        methods: ['GET', 'POST'],
      },
      pingTimeout: 30000,
      pingInterval: 10000,
    });

    // Authentication middleware
    this.io.use(async (socket: CustomSocket, next) => {
      try {
        const rawToken =
          socket.handshake.auth?.token ||
          socket.handshake.headers?.authorization?.replace(/^Bearer\s+/i, '') ||
          socket.handshake.query?.token;

        if (!rawToken || typeof rawToken !== 'string') {
          // Allow connection with unauthenticated tag for public/testing if required
          socket.user = undefined;
          return next();
        }

        const decoded = jwt.verify(rawToken, env.JWT_ACCESS_SECRET) as any;
        socket.user = {
          id: decoded.sub || decoded.userId || decoded.id,
          email: decoded.email,
          role: decoded.role,
          verificationStatus: decoded.verificationStatus,
        };
        next();
      } catch (err: any) {
        logger.warn('Socket connection authentication error', { error: err.message });
        // Proceed without authenticated user tag
        socket.user = undefined;
        next();
      }
    });

    // Connection lifecycle
    this.io.on('connection', (socket: CustomSocket) => {
      const user = socket.user;
      logger.info('Socket client connected', {
        socketId: socket.id,
        userId: user?.id,
        role: user?.role,
      });

      if (user?.id) {
        socket.join(`user:${user.id}`);

        if (user.role === 'DOCTOR') {
          socket.join('doctors');
        } else if (user.role === 'AMBULANCE_DRIVER' || user.role === 'PARAMEDIC' || user.role === 'DRIVER') {
          socket.join('ambulance_drivers');
        }
      }

      // Room management
      socket.on('join_ambulance_drivers', () => {
        socket.join('ambulance_drivers');
        logger.info(`Socket ${socket.id} explicitly joined ambulance_drivers channel`);
      });

      socket.on('join_emergency', (emergencyId: string) => {
        if (emergencyId) {
          socket.join(`emergency:${emergencyId}`);
          logger.info(`Socket ${socket.id} joined emergency:${emergencyId}`);
        }
      });

      socket.on('leave_emergency', (emergencyId: string) => {
        if (emergencyId) {
          socket.leave(`emergency:${emergencyId}`);
        }
      });

      socket.on('join_consultation', (appointmentId: string) => {
        if (appointmentId) {
          socket.join(`consultation:${appointmentId}`);
          logger.info(`Socket ${socket.id} joined consultation:${appointmentId}`);
        }
      });

      socket.on('leave_consultation', (appointmentId: string) => {
        if (appointmentId) {
          socket.leave(`consultation:${appointmentId}`);
        }
      });

      socket.on('join_hospital', (hospitalId: string) => {
        if (hospitalId) {
          socket.join(`hospital:${hospitalId}`);
          logger.info(`Socket ${socket.id} joined hospital:${hospitalId}`);
        }
      });

      // Live GPS Coordinate updates from ambulance driver
      socket.on(
        'update_ambulance_location',
        async (data: {
          emergencyId: string;
          latitude: number;
          longitude: number;
          speed?: number;
          heading?: number;
          etaMinutes?: number;
        }) => {
          try {
            if (!data.emergencyId || data.latitude === undefined || data.longitude === undefined) {
              return;
            }

            // Broadcast to the emergency room immediately for sub-second live rendering
            this.emitAmbulanceLocation(data.emergencyId, {
              emergencyId: data.emergencyId,
              latitude: data.latitude,
              longitude: data.longitude,
              speed: data.speed,
              heading: data.heading,
              etaMinutes: data.etaMinutes,
              timestamp: new Date().toISOString(),
            });

            // Persist driver coordinates into PostgreSQL EmergencyRequest record
            await prisma.emergencyRequest.updateMany({
              where: { id: data.emergencyId },
              data: {
                driverLatitude: data.latitude,
                driverLongitude: data.longitude,
                estimatedMinutes: data.etaMinutes,
              },
            });
          } catch (err: any) {
            logger.warn('Failed to update live ambulance coordinates', { error: err.message });
          }
        }
      );

      // Consultation real-time messaging
      socket.on(
        'send_consultation_message',
        (data: { appointmentId: string; message: string; senderRole: string; senderName?: string }) => {
          if (!data.appointmentId || !data.message) return;

          const payload = {
            id: `msg-${Date.now()}`,
            appointmentId: data.appointmentId,
            message: data.message,
            senderRole: data.senderRole || user?.role || 'UNKNOWN',
            senderName: data.senderName || (user?.email?.split('@')[0] ?? 'User'),
            timestamp: new Date().toISOString(),
          };

          this.io?.to(`consultation:${data.appointmentId}`).emit('consultation_message', payload);
        }
      );

      socket.on('disconnect', () => {
        logger.info('Socket client disconnected', { socketId: socket.id });
      });
    });

    logger.info('Socket.IO real-time engine initialized successfully');
    return this.io;
  }

  public getIO(): Server | null {
    return this.io;
  }

  // ============================================================================
  // Event Broadcasting Helpers
  // ============================================================================

  /**
   * Broadcast newly triggered SOS to all eligible ambulance drivers
   */
  public emitEmergencyBroadcast(emergency: any): void {
    if (!this.io) return;
    const broadcastPayload = {
      success: true,
      emergency,
      timestamp: new Date().toISOString(),
    };
    // Emit to dedicated ambulance channel
    this.io.to('ambulance_drivers').emit('emergency_broadcast', broadcastPayload);
    // Also emit broadcast globally to guarantee all listening EMS terminals receive it immediately
    this.io.emit('emergency_broadcast', broadcastPayload);
  }

  /**
   * Broadcast emergency acceptance by driver to the patient and hospital
   */
  public emitEmergencyAccepted(emergencyId: string, payload: any): void {
    if (!this.io) return;
    const data = {
      success: true,
      emergencyId,
      ...payload,
      timestamp: new Date().toISOString(),
    };
    this.io.to(`emergency:${emergencyId}`).emit('emergency_accepted', data);
    this.io.emit('emergency_accepted', data);
    this.emitEmergencyStatusUpdate(emergencyId, 'ASSIGNED', payload);
  }

  /**
   * Broadcast emergency claim to all ambulance drivers so they remove it from their queues (first come first served)
   */
  public emitEmergencyClaimed(emergencyId: string, claimedByDriverId: string, payload: any = {}): void {
    if (!this.io) return;
    const data = {
      success: true,
      emergencyId,
      claimedByDriverId,
      ...payload,
      timestamp: new Date().toISOString(),
    };
    this.io.to('ambulance_drivers').emit('emergency_claimed', data);
    this.io.emit('emergency_claimed', data);
    logger.info(`[SOCKET] Emitted emergency_claimed for dispatch ${emergencyId} by driver ${claimedByDriverId}`);
  }

  /**
   * Broadcast real-time driver verification status update by Super Admin
   */
  public emitDriverVerificationUpdate(driverUserId: string, payload: any): void {
    if (!this.io) return;
    const data = {
      success: true,
      driverUserId,
      ...payload,
      timestamp: new Date().toISOString(),
    };
    this.io.to(`user:${driverUserId}`).emit('driver_verification_update', data);
    this.io.emit('driver_verification_update', data);
    logger.info(`[SOCKET] Emitted driver_verification_update for driver ${driverUserId}: ${payload.status}`);
  }

  /**
   * Broadcast emergency transit milestone update
   */
  public emitEmergencyStatusUpdate(emergencyId: string, status: string, payload: any = {}): void {
    if (!this.io) return;
    const data = {
      success: true,
      emergencyId,
      status,
      ...payload,
      timestamp: new Date().toISOString(),
    };
    this.io.to(`emergency:${emergencyId}`).emit('emergency_status_updated', data);
    this.io.emit('emergency_status_updated', data);
  }

  /**
   * Broadcast real-time moving ambulance coordinates to tracking room
   */
  public emitAmbulanceLocation(emergencyId: string, location: any): void {
    if (!this.io) return;
    const data = {
      success: true,
      emergencyId,
      ...location,
    };
    this.io.to(`emergency:${emergencyId}`).emit('ambulance_location_updated', data);
    this.io.emit('ambulance_location_updated', data);
  }

  /**
   * Notify hospital trauma bay of incoming emergency patient
   */
  public emitHospitalTraumaAlert(hospitalId: string, payload: any): void {
    if (!this.io) return;
    this.io.to(`hospital:${hospitalId}`).emit('hospital_trauma_alert', {
      success: true,
      hospitalId,
      ...payload,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Notify user of appointment state transition
   */
  public emitAppointmentUpdate(userId: string, appointment: any): void {
    if (!this.io) return;
    this.io.to(`user:${userId}`).emit('appointment_updated', {
      success: true,
      appointment,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Notify patient when doctor issues a digital prescription
   */
  public emitPrescriptionCreated(patientUserId: string, prescription: any): void {
    if (!this.io) return;
    this.io.to(`user:${patientUserId}`).emit('prescription_created', {
      success: true,
      prescription,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Alert treating doctor of abnormal patient vitals
   */
  public emitVitalsAlert(doctorUserId: string, alert: any): void {
    if (!this.io) return;
    this.io.to(`user:${doctorUserId}`).emit('patient_vitals_alert', {
      success: true,
      alert,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Send custom event to a specific user room
   */
  public emitToUser(userId: string, event: string, payload: any): void {
    if (!this.io) return;
    this.io.to(`user:${userId}`).emit(event, payload);
  }

  /**
   * Send custom event to a specific room
   */
  public emitToRoom(room: string, event: string, payload: any): void {
    if (!this.io) return;
    this.io.to(room).emit(event, payload);
  }
}

export const socketService = new SocketService();

