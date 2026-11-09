import { prisma } from '../config/prisma';
import { VitalMetricType, VitalSource } from '@prisma/client';
import { socketService } from './socket.service';
import { logger } from '../utils/logger';
import { BadRequestError } from '../utils/AppError';

export interface VitalInput {
  metricType: VitalMetricType;
  metricValue: number;
  secondaryValue?: number | null;
  unit: string;
  measuredAt: string | Date;
  deviceId?: string | null;
  source?: VitalSource;
  metadata?: any;
}

export interface DeviceConnectInput {
  name: string;
  macAddress: string;
  deviceType?: string;
  batteryLevel?: number | null;
  firmwareVersion?: string | null;
  metadata?: any;
}

class VitalsService {
  /**
   * Validate vital reading bounds to prevent fake or corrupted telemetry
   */
  private validateReading(input: VitalInput): void {
    const { metricType, metricValue, secondaryValue } = input;

    if (isNaN(metricValue) || metricValue === null || metricValue === undefined) {
      throw new BadRequestError(`Invalid metricValue for ${metricType}`);
    }

    switch (metricType) {
      case VitalMetricType.HEART_RATE:
        if (metricValue < 30 || metricValue > 250) {
          throw new BadRequestError(`Heart rate ${metricValue} bpm is out of physiologic range (30-250)`);
        }
        break;
      case VitalMetricType.SPO2:
        if (metricValue < 50 || metricValue > 100) {
          throw new BadRequestError(`SpO2 ${metricValue}% is out of physiologic range (50-100)`);
        }
        break;
      case VitalMetricType.STEPS:
        if (metricValue < 0 || metricValue > 200000) {
          throw new BadRequestError(`Steps ${metricValue} is out of valid range (0-200,000)`);
        }
        break;
      case VitalMetricType.SLEEP:
        if (metricValue < 0 || metricValue > 24) {
          throw new BadRequestError(`Sleep duration ${metricValue}h must be between 0 and 24 hours`);
        }
        break;
      case VitalMetricType.BLOOD_PRESSURE:
        if (metricValue < 50 || metricValue > 280) {
          throw new BadRequestError(`Systolic BP ${metricValue} mmHg is out of physiologic range (50-280)`);
        }
        if (secondaryValue !== undefined && secondaryValue !== null) {
          if (secondaryValue < 30 || secondaryValue > 180) {
            throw new BadRequestError(`Diastolic BP ${secondaryValue} mmHg is out of physiologic range (30-180)`);
          }
        }
        break;
      case VitalMetricType.BODY_TEMPERATURE:
        if (metricValue < 30 || metricValue > 45) {
          throw new BadRequestError(`Body temperature ${metricValue}°C is out of physiologic range (30-45)`);
        }
        break;
      case VitalMetricType.BLOOD_GLUCOSE:
        if (metricValue < 20 || metricValue > 700) {
          throw new BadRequestError(`Blood glucose ${metricValue} mg/dL is out of physiologic range (20-700)`);
        }
        break;
    }
  }

  /**
   * Sync a batch of vital measurements from Smartwatch BLE or Local Storage
   */
  public async syncVitals(patientProfileId: string, rawReadings: any[]) {
    if (!rawReadings || !Array.isArray(rawReadings) || rawReadings.length === 0) {
      throw new BadRequestError('Readings array cannot be empty');
    }

    const readings: VitalInput[] = rawReadings.map((r) => ({
      metricType: r.metricType,
      metricValue:
        r.metricValue !== undefined && r.metricValue !== null
          ? Number(r.metricValue)
          : r.value !== undefined && r.value !== null
          ? Number(r.value)
          : NaN,
      secondaryValue:
        r.secondaryValue !== undefined && r.secondaryValue !== null
          ? Number(r.secondaryValue)
          : null,
      unit: r.unit || '',
      measuredAt: r.measuredAt ? new Date(r.measuredAt) : new Date(),
      deviceId: r.deviceId || null,
      source: r.source || VitalSource.SMARTWATCH_BLE,
      metadata: r.metadata,
    }));

    const patient = await prisma.patientProfile.findUnique({
      where: { id: patientProfileId },
      include: { user: true },
    });

    if (!patient) {
      throw new BadRequestError('Patient profile not found');
    }

    const savedRecords = [];

    for (const r of readings) {
      this.validateReading(r);

      const measuredAt = new Date(r.measuredAt);
      if (isNaN(measuredAt.getTime())) {
        throw new BadRequestError(`Invalid date format for measuredAt: ${r.measuredAt}`);
      }

      // Upsert using the unique constraint [patientProfileId, metricType, measuredAt]
      // to ensure idempotency and prevent duplicate accumulation during repeated syncs.
      const record = await prisma.vitalReading.upsert({
        where: {
          patientProfileId_metricType_measuredAt: {
            patientProfileId,
            metricType: r.metricType,
            measuredAt,
          },
        },
        update: {
          metricValue: r.metricValue,
          secondaryValue: r.secondaryValue ?? null,
          unit: r.unit,
          deviceId: r.deviceId ?? null,
          source: r.source ?? VitalSource.SMARTWATCH_BLE,
          metadata: r.metadata ?? undefined,
          syncStatus: 'SYNCED',
        },
        create: {
          patientProfileId,
          metricType: r.metricType,
          metricValue: r.metricValue,
          secondaryValue: r.secondaryValue ?? null,
          unit: r.unit,
          measuredAt,
          deviceId: r.deviceId ?? null,
          source: r.source ?? VitalSource.SMARTWATCH_BLE,
          metadata: r.metadata ?? undefined,
          syncStatus: 'SYNCED',
        },
      });

      savedRecords.push(record);
    }

    // Update device lastSyncAt if deviceId was provided
    const firstDeviceId = readings.find((r) => r.deviceId)?.deviceId;
    if (firstDeviceId) {
      await prisma.patientDevice
        .updateMany({
          where: {
            patientProfileId,
            macAddress: firstDeviceId,
          },
          data: {
            lastSyncAt: new Date(),
            connectionStatus: 'CONNECTED',
          },
        })
        .catch(() => {});
    }

    // Broadcast real-time vital update through Socket.IO to Patient and authorized Doctors
    try {
      socketService.emitToUser(patient.userId, 'vital:updated', {
        patientProfileId,
        count: savedRecords.length,
        latest: savedRecords[savedRecords.length - 1],
      });

      // Broadcast to doctor clinical stream room
      const io = socketService.getIO();
      if (io) {
        io.to(`patient_vitals:${patientProfileId}`).emit('doctor:vital:stream', {
          patientProfileId,
          patientName: patient.fullName,
          readings: savedRecords,
          syncedAt: new Date().toISOString(),
        });
      }
    } catch (err) {
      logger.warn('Failed to dispatch Socket.IO vital broadcast', { error: err });
    }

    logger.info('Vitals synchronized successfully', {
      patientProfileId,
      recordsCount: savedRecords.length,
    });

    return {
      syncedCount: savedRecords.length,
      readings: savedRecords,
    };
  }

  /**
   * Get latest reading for each supported vital metric
   */
  public async getLatestVitals(patientProfileId: string) {
    const metricTypes = Object.values(VitalMetricType);
    const latestMap: Record<string, any> = {};

    for (const mt of metricTypes) {
      const latest = await prisma.vitalReading.findFirst({
        where: {
          patientProfileId,
          metricType: mt,
        },
        orderBy: { measuredAt: 'desc' },
      });

      latestMap[mt] = latest;
    }

    // Check device connection status
    const primaryDevice = await prisma.patientDevice.findFirst({
      where: { patientProfileId },
      orderBy: { updatedAt: 'desc' },
    });

    return {
      vitals: latestMap,
      latest: latestMap,
      device: primaryDevice,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Get historical readings for charts (e.g. daily HR graph, hourly step graph)
   */
  public async getVitalsHistory(
    patientProfileId: string,
    metricType?: VitalMetricType,
    from?: Date,
    to?: Date,
    limit: number = 100
  ) {
    const where: any = { patientProfileId };

    if (metricType) {
      where.metricType = metricType;
    }

    if (from || to) {
      where.measuredAt = {};
      if (from) where.measuredAt.gte = from;
      if (to) where.measuredAt.lte = to;
    }

    const records = await prisma.vitalReading.findMany({
      where,
      orderBy: { measuredAt: 'desc' },
      take: Math.min(limit, 500),
    });

    return {
      count: records.length,
      metricType: metricType || 'ALL',
      readings: records.reverse(), // Ascending order for chart plotting
    };
  }

  /**
   * Computes statistical summary (min, max, avg BPM, step goals, sleep duration)
   */
  public async getVitalsSummary(patientProfileId: string, targetDate?: Date) {
    const date = targetDate || new Date();
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    // 1. Heart Rate Stats for today
    const hrReadings = await prisma.vitalReading.findMany({
      where: {
        patientProfileId,
        metricType: VitalMetricType.HEART_RATE,
        measuredAt: { gte: startOfDay, lte: endOfDay },
      },
      select: { metricValue: true },
    });

    let heartRateSummary = {
      min: null as number | null,
      max: null as number | null,
      avg: null as number | null,
      samples: hrReadings.length,
    };

    if (hrReadings.length > 0) {
      const values = hrReadings.map((r) => r.metricValue);
      const min = Math.min(...values);
      const max = Math.max(...values);
      const sum = values.reduce((acc, v) => acc + v, 0);
      const avg = Math.round(sum / values.length);
      heartRateSummary = { min, max, avg, samples: hrReadings.length };
    }

    // 2. Steps today (cumulative max or sum of hourly deltas)
    const stepReadings = await prisma.vitalReading.findMany({
      where: {
        patientProfileId,
        metricType: VitalMetricType.STEPS,
        measuredAt: { gte: startOfDay, lte: endOfDay },
      },
      orderBy: { measuredAt: 'desc' },
      take: 1,
    });

    const totalSteps = stepReadings.length > 0 ? Math.round(stepReadings[0].metricValue) : 0;
    const stepGoal = 10000;
    const distanceKm = +(totalSteps * 0.00075).toFixed(2); // ~0.75m per stride average
    const caloriesBurned = Math.round(totalSteps * 0.04); // ~0.04 kcal per step

    // 3. SpO2 latest today
    const latestSpo2 = await prisma.vitalReading.findFirst({
      where: {
        patientProfileId,
        metricType: VitalMetricType.SPO2,
        measuredAt: { gte: startOfDay, lte: endOfDay },
      },
      orderBy: { measuredAt: 'desc' },
    });

    // 4. Sleep duration today
    const latestSleep = await prisma.vitalReading.findFirst({
      where: {
        patientProfileId,
        metricType: VitalMetricType.SLEEP,
        measuredAt: { gte: startOfDay, lte: endOfDay },
      },
      orderBy: { measuredAt: 'desc' },
    });

    // 5. Blood Pressure latest
    const latestBp = await prisma.vitalReading.findFirst({
      where: {
        patientProfileId,
        metricType: VitalMetricType.BLOOD_PRESSURE,
      },
      orderBy: { measuredAt: 'desc' },
    });

    return {
      date: startOfDay.toISOString().split('T')[0],
      heartRate: heartRateSummary,
      steps: {
        total: totalSteps,
        goal: stepGoal,
        progressPercent: Math.min(100, Math.round((totalSteps / stepGoal) * 100)),
        distanceKm,
        caloriesBurned,
      },
      spo2: {
        value: latestSpo2 ? latestSpo2.metricValue : null,
        measuredAt: latestSpo2 ? latestSpo2.measuredAt : null,
      },
      sleep: {
        durationHours: latestSleep ? latestSleep.metricValue : null,
        measuredAt: latestSleep ? latestSleep.measuredAt : null,
      },
      bloodPressure: {
        systolic: latestBp ? latestBp.metricValue : null,
        diastolic: latestBp ? latestBp.secondaryValue : null,
        measuredAt: latestBp ? latestBp.measuredAt : null,
      },
    };
  }

  /**
   * Device Management APIs
   */
  public async getDevices(patientProfileId: string) {
    const devices = await prisma.patientDevice.findMany({
      where: { patientProfileId },
      orderBy: { updatedAt: 'desc' },
    });

    return {
      count: devices.length,
      devices,
    };
  }

  public async connectDevice(patientProfileId: string, input: any) {
    const name = input?.name || input?.deviceName;
    const macAddress = input?.macAddress;
    if (!macAddress || !name) {
      throw new BadRequestError('Device name and macAddress are required');
    }

    const device = await prisma.patientDevice.upsert({
      where: {
        patientProfileId_macAddress: {
          patientProfileId,
          macAddress: macAddress.toUpperCase(),
        },
      },
      update: {
        name,
        deviceType: input.deviceType || 'SMARTWATCH',
        batteryLevel: input.batteryLevel ?? undefined,
        firmwareVersion: input.firmwareVersion ?? undefined,
        connectionStatus: 'CONNECTED',
        isPaired: true,
        lastSyncAt: new Date(),
        metadata: input.metadata ?? undefined,
      },
      create: {
        patientProfileId,
        name,
        macAddress: macAddress.toUpperCase(),
        deviceType: input.deviceType || 'SMARTWATCH',
        batteryLevel: input.batteryLevel ?? null,
        firmwareVersion: input.firmwareVersion ?? null,
        connectionStatus: 'CONNECTED',
        isPaired: true,
        lastSyncAt: new Date(),
        metadata: input.metadata ?? undefined,
      },
    });

    logger.info('Device connected/registered', {
      patientProfileId,
      macAddress: device.macAddress,
      name: device.name,
    });

    return device;
  }

  public async disconnectDevice(patientProfileId: string, macAddress: string) {
    const normalizedMac = macAddress.toUpperCase();
    await prisma.patientDevice.updateMany({
      where: {
        patientProfileId,
        macAddress: normalizedMac,
      },
      data: {
        connectionStatus: 'DISCONNECTED',
      },
    });

    const device = await prisma.patientDevice.findUnique({
      where: {
        patientProfileId_macAddress: {
          patientProfileId,
          macAddress: normalizedMac,
        },
      },
    });

    return { success: true, isConnected: false, device };
  }

  public async getDeviceStatus(patientProfileId: string, macAddress?: string) {
    const where: any = { patientProfileId };
    if (macAddress) {
      where.macAddress = macAddress.toUpperCase();
    }

    const device = await prisma.patientDevice.findFirst({
      where,
      orderBy: { updatedAt: 'desc' },
    });

    return {
      isConnected: device?.connectionStatus === 'CONNECTED',
      connected: device?.connectionStatus === 'CONNECTED',
      device,
    };
  }
}

export const vitalsService = new VitalsService();
