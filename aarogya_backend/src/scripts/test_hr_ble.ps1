param (
    [string]$Mac = "F44EFCB8F342"
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($t, $r) {
    $asTask = $asTaskGeneric.MakeGenericMethod($r)
    $netTask = $asTask.Invoke($null, @($t))
    $netTask.Wait(6000) | Out-Null
    if ($netTask.IsCompleted) { return $netTask.Result }
    return $null
}

[Windows.Devices.Bluetooth.BluetoothLEDevice,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
$cleanMac = $Mac.Replace(":", "").Replace("-", "").ToUpper()
$addr = [Convert]::ToUInt64($cleanMac, 16)

$dev = Await ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($addr)) ([Windows.Devices.Bluetooth.BluetoothLEDevice])
if (-not $dev) {
    Write-Host "Device not found."
    exit
}

Write-Host "Device:" $dev.Name "Status:" $dev.ConnectionStatus

# Check Device Info
$svcRes = Await ($dev.GetGattServicesAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult])
$hrSvc = $svcRes.Services | Where-Object { $_.Uuid.ToString() -like "*180d*" } | Select-Object -First 1

if ($hrSvc) {
    Write-Host "Found HR Service 180D!"
    $cRes = Await ($hrSvc.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
    $hrChar = $cRes.Characteristics | Where-Object { $_.Uuid.ToString() -like "*2a37*" } | Select-Object -First 1
    if ($hrChar) {
        Write-Host "Found HR Measurement 2A37! Properties:" $hrChar.CharacteristicProperties
        
        # Check if CCCD descriptor can be written (subscribe to Notify)
        $descRes = Await ($hrChar.GetDescriptorsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDescriptorsResult])
        Write-Host "Descriptors count:" $descRes.Descriptors.Count
        foreach ($d in $descRes.Descriptors) {
            Write-Host "  Desc:" $d.Uuid
        }
    }
} else {
    Write-Host "HR Service 180D not found in services."
}

