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
$cleanMac = $Mac.Replace(":", "").Replace("-", "").ToUpper()
$addr = [Convert]::ToUInt64($cleanMac, 16)

$dev = Await ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($addr)) ([Windows.Devices.Bluetooth.BluetoothLEDevice])
if (-not $dev) { exit }

Write-Host "Device:" $dev.Name "Status:" $dev.ConnectionStatus

$svcRes = Await ($dev.GetGattServicesAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult])
$hrSvc = $svcRes.Services | Where-Object { $_.Uuid.ToString() -like "*180d*" } | Select-Object -First 1

if ($hrSvc) {
    $cRes = Await ($hrSvc.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
    $locChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*2a38*" } | Select-Object -First 1
    if ($locChar) {
        $readRes = Await ($locChar.ReadValueAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattReadResult])
        if ($readRes -and $readRes.Status -eq 'Success' -and $readRes.Value) {
            $getByte = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions].GetMethod("GetByte", [type[]]@([Windows.Storage.Streams.IBuffer], [uint32]))
            $loc = [int]($getByte.Invoke($null, @($readRes.Value, [uint32]0)))
            $locations = @{ 0="Other"; 1="Chest"; 2="Wrist"; 3="Finger"; 4="Hand"; 5="Ear Lobe"; 6="Foot" }
            Write-Host "Body Sensor Location:" $locations[$loc] "($loc)"
        } else {
            Write-Host "Body Sensor Location read status:" $readRes.Status
        }
    }

    # Query Device Info (Manufacturer, Model, Firmware)
    $infoSvc = $svcRes.Services | Where-Object { $_.Uuid.ToString() -like "*180a*" } | Select-Object -First 1
    if ($infoSvc) {
        $iRes = Await ($infoSvc.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
        foreach ($c in $iRes.Characteristics) {
            $r = Await ($c.ReadValueAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattReadResult])
            if ($r -and $r.Status -eq 'Success' -and $r.Value) {
                $reader = [Windows.Storage.Streams.DataReader]::FromBuffer($r.Value)
                $val = $reader.ReadString($r.Value.Length)
                Write-Host "DeviceInfo Char $($c.Uuid): $val"
            }
        }
    }
}

