import { Request, Response, NextFunction } from 'express';
import { wearableService } from '../services/wearable.service';

export const wearableController = {
  /**
   * Retrieves real-time status and telemetry from the connected smartwatch
   * through the local laptop Bluetooth bridge.
   */
  async getWatchTelemetry(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const macOverride = req.query.mac as string | undefined;
      const telemetry = await wearableService.getBridgeWatchTelemetry(macOverride);

      res.status(200).json({
        success: true,
        data: telemetry,
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * Returns documented GATT specifications and capability profile for the detected watch.
   */
  async getCapabilities(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const capabilities = wearableService.getWatchCapabilities();

      res.status(200).json({
        success: true,
        data: capabilities,
      });
    } catch (error) {
      next(error);
    }
  },
};
