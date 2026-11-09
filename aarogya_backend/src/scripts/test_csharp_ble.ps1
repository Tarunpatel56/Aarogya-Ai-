$csharpSource = @"
using System;
using System.Threading;
using System.Threading.Tasks;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Storage.Streams;

public class BleHeartRateListener
{
    public static int LastBpm = 0;
    public static bool LastContact = false;
    public static DateTime LastMeasurementTime = DateTime.MinValue;
    public static string LastStatus = "Initialized";

    public static async Task<bool> StartListeningAsync(ulong bluetoothAddress, int listenTimeoutSeconds)
    {
        try
        {
            var device = await BluetoothLEDevice.FromBluetoothAddressAsync(bluetoothAddress);
            if (device == null)
            {
                LastStatus = "Device not found";
                return false;
            }

            var gattServices = await device.GetGattServicesForUuidAsync(GattServiceUuids.HeartRate, BluetoothCacheMode.Cached);
            if (gattServices.Status != GattCommunicationStatus.Success || gattServices.Services.Count == 0)
            {
                LastStatus = "HeartRate service not found: " + gattServices.Status;
                return false;
            }

            var hrService = gattServices.Services[0];
            var chars = await hrService.GetCharacteristicsForUuidAsync(GattCharacteristicUuids.HeartRateMeasurement, BluetoothCacheMode.Cached);
            if (chars.Status != GattCommunicationStatus.Success || chars.Characteristics.Count == 0)
            {
                LastStatus = "HeartRate characteristic not found";
                return false;
            }

            var hrChar = chars.Characteristics[0];

            hrChar.ValueChanged += (sender, args) =>
            {
                var buffer = args.CharacteristicValue;
                if (buffer != null && buffer.Length >= 2)
                {
                    using (var reader = DataReader.FromBuffer(buffer))
                    {
                        byte flags = reader.ReadByte();
                        bool is16Bit = (flags & 0x01) != 0;
                        bool contact = (flags & 0x06) == 0x06;

                        int bpm = 0;
                        if (is16Bit && buffer.Length >= 3)
                        {
                            bpm = reader.ReadUInt16();
                        }
                        else
                        {
                            bpm = reader.ReadByte();
                        }

                        if (bpm > 0)
                        {
                            LastBpm = bpm;
                            LastContact = contact;
                            LastMeasurementTime = DateTime.UtcNow;
                            LastStatus = "Active Stream (" + bpm + " BPM)";
                        }
                    }
                }
            };

            var cccdStatus = await hrChar.WriteClientCharacteristicConfigurationDescriptorAsync(
                GattClientCharacteristicConfigurationDescriptorValue.Notify
            );

            LastStatus = "Notify status: " + cccdStatus;
            return cccdStatus == GattCommunicationStatus.Success;
        }
        catch (Exception ex)
        {
            LastStatus = "Error: " + ex.Message;
            return false;
        }
    }
}
"@

Add-Type -TypeDefinition $csharpSource -Language CSharp -IgnoreWarnings
Write-Host "C# BLE Listener compiled successfully!"

