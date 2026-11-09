import { execFile } from 'child_process';
import path from 'path';
import fs from 'fs';

export interface WatchTelemetry {
  device: {
    name: string;
    macAddress: string;
    connectionType: string;
    hostInterface: string;
    connectionStatus: 'Connected' | 'Standby (Paired to Laptop)' | 'Disconnected' | 'Unknown';
    batteryLevel: number | null;
    paired: boolean;
  };
  telemetry: {
    heartRate: {
      bpm: number | null;
      sensorContact: boolean;
      supported: boolean;
      status: string;
    };
    steps: {
      value: number | null;
      supported: boolean;
      status: string;
    };
    spo2: {
      value: number | null;
      supported: boolean;
      status: string;
    };
    sleep: {
      value: number | null;
      supported: boolean;
      status: string;
    };
  };
  bridgeMode: string;
  timestamp: string;
  error?: string;
}

let lastTelemetryCache: { data: WatchTelemetry; expiresAt: number } | null = null;
const CACHE_TTL_MS = 6000;

export const wearableService = {
  /**
   * Retrieves real telemetry from the laptop-connected smartwatch (FireBoltt 182 / BLE Wearables)
   * via the Windows Bluetooth LE host radio bridge.
   */
  async getBridgeWatchTelemetry(macOverride?: string): Promise<WatchTelemetry> {
    const now = Date.now();
    if (lastTelemetryCache && lastTelemetryCache.expiresAt > now && !macOverride) {
      return lastTelemetryCache.data;
    }

    let scriptPath = path.resolve(__dirname, '../scripts/get_watch_telemetry.ps1');
    if (!fs.existsSync(scriptPath)) {
      const srcPath = path.resolve(__dirname, '../../src/scripts/get_watch_telemetry.ps1');
      if (fs.existsSync(srcPath)) {
        scriptPath = srcPath;
      } else {
        const cwdPath = path.resolve(process.cwd(), 'src/scripts/get_watch_telemetry.ps1');
        if (fs.existsSync(cwdPath)) {
          scriptPath = cwdPath;
        }
      }
    }
    const mac = macOverride || 'F44EFCB8F342';

    return new Promise<WatchTelemetry>((resolve) => {
      execFile(
        'powershell',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', scriptPath, '-Mac', mac],
        { timeout: 25000 },
        (error, stdout, _stderr) => {
          if (error) {
            const fallback: WatchTelemetry = {
              device: {
                name: 'FireBoltt 182',
                macAddress: 'F4:4E:FC:B8:F3:42',
                connectionType: 'Bluetooth Low Energy (BLE) + Classic',
                hostInterface: 'Windows 11 BLE Radio',
                connectionStatus: 'Disconnected',
                batteryLevel: null,
                paired: true,
              },
              telemetry: {
                heartRate: {
                  bpm: null,
                  sensorContact: false,
                  supported: true,
                  status: 'Unable to communicate with Windows Bluetooth radio: ' + error.message,
                },
                steps: {
                  value: null,
                  supported: false,
                  status: 'Proprietary vendor protocol - Companion app required',
                },
                spo2: {
                  value: null,
                  supported: false,
                  status: 'Proprietary vendor protocol - Not exposed via GATT',
                },
                sleep: {
                  value: null,
                  supported: false,
                  status: 'Proprietary vendor protocol - Companion app required',
                },
              },
              bridgeMode: 'Local Laptop Bridge',
              timestamp: new Date().toISOString(),
              error: error.message,
            };
            return resolve(fallback);
          }

          try {
            const trimmed = stdout.trim();
            const jsonStart = trimmed.indexOf('{');
            const jsonEnd = trimmed.lastIndexOf('}');
            if (jsonStart !== -1 && jsonEnd !== -1) {
              const parsed = JSON.parse(trimmed.slice(jsonStart, jsonEnd + 1)) as WatchTelemetry;
              lastTelemetryCache = { data: parsed, expiresAt: now + CACHE_TTL_MS };
              return resolve(parsed);
            }
            throw new Error('No valid JSON returned from telemetry bridge');
          } catch (parseErr: any) {
            return resolve({
              device: {
                name: 'FireBoltt 182',
                macAddress: 'F4:4E:FC:B8:F3:42',
                connectionType: 'Bluetooth Low Energy (BLE) + Classic',
                hostInterface: 'Windows 11 BLE Radio',
                connectionStatus: 'Standby (Paired to Laptop)',
                batteryLevel: null,
                paired: true,
              },
              telemetry: {
                heartRate: {
                  bpm: null,
                  sensorContact: false,
                  supported: true,
                  status: 'Telemetry parsing error: ' + (parseErr?.message || 'Invalid output format'),
                },
                steps: { value: null, supported: false, status: 'Proprietary protocol' },
                spo2: { value: null, supported: false, status: 'Proprietary protocol' },
                sleep: { value: null, supported: false, status: 'Proprietary protocol' },
              },
              bridgeMode: 'Local Laptop Bridge',
              timestamp: new Date().toISOString(),
              error: String(parseErr),
            });
          }
        }
      );
    });
  },

  /**
   * Returns documented GATT specifications and capability profile for the detected watch.
   */
  getWatchCapabilities() {
    return {
      modelName: 'FireBoltt 182',
      hardwareModel: 'FD28',
      macAddress: 'F4:4E:FC:B8:F3:42',
      connectivity: {
        classicBluetooth: {
          supported: true,
          profiles: ['AVRCP (Audio/Video Remote Control)', 'A2DP Audio Sink'],
        },
        bluetoothLowEnergy: {
          supported: true,
          standardGattServices: [
            {
              uuid: '0x180D',
              name: 'Heart Rate Service',
              characteristics: [
                { uuid: '0x2A37', name: 'Heart Rate Measurement', properties: ['Notify'] },
                { uuid: '0x2A38', name: 'Body Sensor Location', properties: ['Read'] },
                { uuid: '0x2A39', name: 'Heart Rate Control Point', properties: ['Write'] },
              ],
            },
            {
              uuid: '0x180F',
              name: 'Battery Service',
              characteristics: [
                { uuid: '0x2A19', name: 'Battery Level', properties: ['Read', 'Notify'] },
              ],
            },
            {
              uuid: '0x180A',
              name: 'Device Information Service',
              characteristics: [
                { uuid: '0x2A24', name: 'Model Number String', properties: ['Read'] },
                { uuid: '0x2A29', name: 'Manufacturer Name String', properties: ['Read'] },
                { uuid: '0x2A26', name: 'Firmware Revision String', properties: ['Read'] },
                { uuid: '0x2A27', name: 'Hardware Revision String', properties: ['Read'] },
              ],
            },
          ],
          proprietaryServices: [
            {
              uuid: '0xFFD0',
              name: 'DaFit / FitCloudPro Vendor Data Service (Steps, Sleep, SpO2, Push notifications)',
              characteristics: ['0xFFD1', '0xFFD2', '0xFFD3'],
            },
            {
              uuid: '6E40FFF0',
              name: 'Nordic Semiconductor UART Service (Telemetry packet stream)',
              characteristics: ['6E40FFF1 (TX)', '6E40FFF2 (RX)'],
            },
          ],
        },
      },
    };
  },
};
