param (
    [string]$Mac = "F44EFCB8F342"
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($t, $r) {
    $asTask = $asTaskGeneric.MakeGenericMethod($r)
    $netTask = $asTask.Invoke($null, @($t))
    $netTask.Wait(4000) | Out-Null
    if ($netTask.IsCompleted) { return $netTask.Result }
    return $null
}

[Windows.Devices.Bluetooth.BluetoothLEDevice,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
[Windows.Devices.Bluetooth.GenericAttributeProfile.GattValueChangedEventArgs,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null

$cleanMac = $Mac.Replace(":", "").Replace("-", "").ToUpper()
$addr = [Convert]::ToUInt64($cleanMac, 16)

$dev = Await ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($addr)) ([Windows.Devices.Bluetooth.BluetoothLEDevice])
if (-not $dev) { exit }

$svcRes = Await ($dev.GetGattServicesAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult])
$hrSvc = $svcRes.Services | Where-Object { $_.Uuid.ToString() -like "*180d*" } | Select-Object -First 1
$cRes = Await ($hrSvc.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
$hrChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*2a37*" } | Select-Object -First 1

$global:capturedBpm = 0

$handler = [Windows.Foundation.TypedEventHandler[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic,Windows.Devices.Bluetooth.GenericAttributeProfile.GattValueChangedEventArgs]]{
    param($sender, $args)
    $buf = $args.CharacteristicValue
    if ($buf -and $buf.Length -ge 2) {
        $getByte = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions].GetMethod("GetByte", [type[]]@([Windows.Storage.Streams.IBuffer], [uint32]))
        $flags = [int]($getByte.Invoke($null, @($buf, [uint32]0)))
        $is16Bit = ($flags -band 0x01) -ne 0
        $bpm = 0
        if ($is16Bit -and $buf.Length -ge 3) {
            $b1 = [int]($getByte.Invoke($null, @($buf, [uint32]1)))
            $b2 = [int]($getByte.Invoke($null, @($buf, [uint32]2)))
            $bpm = $b1 + ($b2 -shl 8)
        } else {
            $bpm = [int]($getByte.Invoke($null, @($buf, [uint32]1)))
        }
        $global:capturedBpm = $bpm
        Write-Host "Live BPM captured via TypedEventHandler delegate: $bpm"
    }
}

$token = $hrChar.add_ValueChanged($handler)
Write-Host "Event handler attached successfully with token:" $token

# Enable CCCD
$status = Await ($hrChar.WriteClientCharacteristicConfigurationDescriptorAsync([Windows.Devices.Bluetooth.GenericAttributeProfile.GattClientCharacteristicConfigurationDescriptorValue]::Notify)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCommunicationStatus])
Write-Host "CCCD Status:" $status

Start-Sleep -Seconds 1
$hrChar.remove_ValueChanged($token)
Write-Host "Done!"

