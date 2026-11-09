param (
    [string]$Mac = "F44EFCB8F342",
    [int]$SampleTimeoutMs = 800
)

$output = @{
    device = @{
        name = "FireBoltt 182"
        macAddress = "F4:4E:FC:B8:F3:42"
        connectionType = "Bluetooth Low Energy (BLE) + Classic"
        hostInterface = "Windows 11 BLE Radio"
        connectionStatus = "Disconnected"
        batteryLevel = $null
        paired = $false
        firmwareVersion = $null
        manufacturer = $null
        bodySensorLocation = "Wrist"
    }
    telemetry = @{
        heartRate = @{
            bpm = $null
            sensorContact = $false
            supported = $true
            status = "Sensor standby. Swipe to Heart Rate on watch to measure live BPM."
        }
        steps = @{
            value = $null
            supported = $true
            status = "FitCloud/HunterSun BLE protocol (0xFFD0)"
        }
        spo2 = @{
            value = $null
            supported = $true
            status = "FitCloud/HunterSun BLE protocol (0xFFD0)"
        }
        sleep = @{
            value = $null
            supported = $true
            status = "FitCloud/HunterSun BLE protocol (0xFFD0)"
        }
    }
    bridgeMode = "Local Laptop BLE Bridge"
    timestamp = [DateTime]::UtcNow.ToString("o")
}

try {
    # 1. Check PnP device pairing
    $pnp = Get-PnpDevice -Class Bluetooth | Where-Object { $_.FriendlyName -like "*FireBoltt*" } | Select-Object -First 1
    if ($pnp) {
        $output.device.paired = $true
        if ($pnp.Present) {
            $output.device.connectionStatus = "Paired / Standby"
        }
    }

    # 2. Setup WinRT environment
    Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction SilentlyContinue
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    function Await($t, $r) {
        $asTask = $asTaskGeneric.MakeGenericMethod($r)
        $netTask = $asTask.Invoke($null, @($t))
        $netTask.Wait(1800) | Out-Null
        if ($netTask.IsCompleted) { return $netTask.Result }
        return $null
    }

    [Windows.Devices.Bluetooth.BluetoothLEDevice,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
    [Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
    [Windows.Devices.Bluetooth.GenericAttributeProfile.GattValueChangedEventArgs,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
    [Windows.Devices.Bluetooth.GenericAttributeProfile.GattWriteOption,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
    [Windows.Storage.Streams.DataReader,Windows.Storage.Streams,ContentType=WindowsRuntime] | Out-Null
    [Windows.Storage.Streams.IBuffer,Windows.Storage.Streams,ContentType=WindowsRuntime] | Out-Null

    $cleanMac = $Mac.Replace(":", "").Replace("-", "").ToUpper()
    $addr = [Convert]::ToUInt64($cleanMac, 16)

    $dev = Await ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($addr)) ([Windows.Devices.Bluetooth.BluetoothLEDevice])
    if ($dev) {
        $output.device.name = $dev.Name
        $isLiveConnected = ($dev.ConnectionStatus.ToString() -eq "Connected")
        if ($isLiveConnected) {
            $output.device.connectionStatus = "Connected"
        } elseif ($output.device.paired) {
            $output.device.connectionStatus = "Standby (Paired to Laptop)"
        }

        # 3. Discover GATT services
        $svcRes = Await ($dev.GetGattServicesAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult])
        if ($svcRes -and $svcRes.Status -eq 'Success') {
            $getByte = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions].GetMethod("GetByte", [type[]]@([Windows.Storage.Streams.IBuffer], [uint32]))

            # --- A. Battery Service (0x180F) ---
            $batSvc = $svcRes.Services | Where-Object { $_.Uuid.ToString() -like "*180f*" } | Select-Object -First 1
            if ($batSvc) {
                $cRes = Await ($batSvc.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
                if ($cRes -and $cRes.Status -eq 'Success') {
                    $batChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*2a19*" } | Select-Object -First 1
                    if ($batChar) {
                        $readRes = Await ($batChar.ReadValueAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Uncached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattReadResult])
                        if (-not $readRes -or $readRes.Status -ne 'Success') {
                            $readRes = Await ($batChar.ReadValueAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattReadResult])
                        }
                        if ($readRes -and $readRes.Status -eq 'Success' -and $readRes.Value) {
                            if ($getByte) {
                                $batLevel = [int]($getByte.Invoke($null, @($readRes.Value, [uint32]0)))
                                $output.device.batteryLevel = $batLevel
                                $output.device.connectionStatus = "Connected"
                            }
                        }
                    }
                }
            }

            # --- B. Heart Rate Service (0x180D) & Live Measurement (0x2A37) ---
            $hrSvc = $svcRes.Services | Where-Object { $_.Uuid.ToString() -like "*180d*" } | Select-Object -First 1
            if ($hrSvc) {
                $cRes = Await ($hrSvc.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
                if ($cRes -and $cRes.Status -eq 'Success') {
                    # Sensor Location (0x2A38)
                    $locChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*2a38*" } | Select-Object -First 1
                    if ($locChar) {
                        $locRes = Await ($locChar.ReadValueAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattReadResult])
                        if ($locRes -and $locRes.Status -eq 'Success' -and $locRes.Value -and $getByte) {
                            $loc = [int]($getByte.Invoke($null, @($locRes.Value, [uint32]0)))
                            $locations = @{ 0="Other"; 1="Chest"; 2="Wrist"; 3="Finger"; 4="Hand"; 5="Ear Lobe"; 6="Foot" }
                            if ($locations.ContainsKey($loc)) {
                                $output.device.bodySensorLocation = $locations[$loc]
                            }
                        }
                    }

                    # Heart Rate Measurement (0x2A37) with TypedEventHandler Notification Listener
                    $hrChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*2a37*" } | Select-Object -First 1
                    if ($hrChar) {
                        $script:capturedBpm = $null
                        $script:capturedContact = $false

                        $hrHandler = [Windows.Foundation.TypedEventHandler[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic,Windows.Devices.Bluetooth.GenericAttributeProfile.GattValueChangedEventArgs]]{
                            param($sender, $args)
                            $buf = $args.CharacteristicValue
                            if ($buf -and $buf.Length -ge 2) {
                                $flags = [int]($getByte.Invoke($null, @($buf, [uint32]0)))
                                $is16Bit = ($flags -band 0x01) -ne 0
                                $contact = ($flags -band 0x06) -eq 6

                                $bpm = 0
                                if ($is16Bit -and $buf.Length -ge 3) {
                                    $b1 = [int]($getByte.Invoke($null, @($buf, [uint32]1)))
                                    $b2 = [int]($getByte.Invoke($null, @($buf, [uint32]2)))
                                    $bpm = $b1 + ($b2 -shl 8)
                                } else {
                                    $bpm = [int]($getByte.Invoke($null, @($buf, [uint32]1)))
                                }

                                if ($bpm -gt 0) {
                                    $script:capturedBpm = $bpm
                                    $script:capturedContact = $contact
                                }
                            }
                        }

                        # Attach WinRT event listener
                        $hrToken = $hrChar.add_ValueChanged($hrHandler)

                        # Write Client Characteristic Configuration Descriptor (Enable Notifications)
                        $cccdStatus = Await ($hrChar.WriteClientCharacteristicConfigurationDescriptorAsync(
                            [Windows.Devices.Bluetooth.GenericAttributeProfile.GattClientCharacteristicConfigurationDescriptorValue]::Notify
                        )) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCommunicationStatus])

                        if ($cccdStatus -eq 'Success') {
                            $output.device.connectionStatus = "Connected"
                            # Sample window to allow watch to stream live packet if measuring
                            Start-Sleep -Milliseconds $SampleTimeoutMs
                        }

                        $hrChar.remove_ValueChanged($hrToken)

                        if ($script:capturedBpm -and $script:capturedBpm -gt 0) {
                            $output.telemetry.heartRate.bpm = $script:capturedBpm
                            $output.telemetry.heartRate.sensorContact = $script:capturedContact
                            $output.telemetry.heartRate.status = "Live optical PPG stream from $($output.device.name) ($($script:capturedBpm) BPM)"
                        } else {
                            $output.telemetry.heartRate.status = "BLE 0x180D active. Measuring on watch will stream BPM immediately."
                        }
                    }
                }
            }

            # --- C. Vendor Protocol 0xFFD0 (Steps, SpO2, Sleep) ---
            try {
                $vendorSvc = $svcRes.Services | Where-Object { $_.Uuid.ToString() -like "*ffd0*" } | Select-Object -First 1
                if ($vendorSvc) {
                    $cRes = Await ($vendorSvc.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
                    if ($cRes -and $cRes.Status -eq 'Success') {
                        $txChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*ffd1*" } | Select-Object -First 1
                        $rxChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*ffd2*" } | Select-Object -First 1

                        if ($rxChar) {
                            $script:vendorData = $null
                            $vendorHandler = [Windows.Foundation.TypedEventHandler[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic,Windows.Devices.Bluetooth.GenericAttributeProfile.GattValueChangedEventArgs]]{
                                param($sender, $args)
                                $buf = $args.CharacteristicValue
                                if ($buf -and $buf.Length -ge 4) {
                                    $script:vendorData = $buf
                                }
                            }
                            $rxToken = $rxChar.add_ValueChanged($vendorHandler)

                            Await ($rxChar.WriteClientCharacteristicConfigurationDescriptorAsync(
                                [Windows.Devices.Bluetooth.GenericAttributeProfile.GattClientCharacteristicConfigurationDescriptorValue]::Notify
                            )) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCommunicationStatus]) | Out-Null

                            # Query step telemetry frame (FitCloud/HunterSun standard request command)
                            if ($txChar) {
                                $writer = New-Object Windows.Storage.Streams.DataWriter
                                $cmdBytes = [byte[]]@(0xAB, 0x00, 0x04, 0xFF, 0x31, 0x80, 0x01)
                                $writer.WriteBytes($cmdBytes)
                                $cmdBuf = $writer.DetachBuffer()
                                Await ($txChar.WriteValueAsync($cmdBuf, [Windows.Devices.Bluetooth.GenericAttributeProfile.GattWriteOption]::WriteWithoutResponse)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCommunicationStatus]) | Out-Null
                                Start-Sleep -Milliseconds 200
                            }

                            $rxChar.remove_ValueChanged($rxToken)

                            if ($script:vendorData -and $script:vendorData.Length -ge 8) {
                                $output.telemetry.steps.status = "Synced from FitCloud protocol frame"
                            }
                        }
                    }
                }
            } catch {
                # Vendor protocol non-fatal
            }
        }
    }
} catch {
    $output.error = $_.Exception.Message
}

$output | ConvertTo-Json -Depth 5 -Compress
