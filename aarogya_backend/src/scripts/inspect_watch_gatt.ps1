param (
    [string]$Mac = "F44EFCB8F342"
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($t, $r) {
    $asTask = $asTaskGeneric.MakeGenericMethod($r)
    $netTask = $asTask.Invoke($null, @($t))
    $netTask.Wait(5000) | Out-Null
    if ($netTask.IsCompleted) { return $netTask.Result }
    return $null
}

[Windows.Devices.Bluetooth.BluetoothLEDevice,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
$cleanMac = $Mac.Replace(":", "").Replace("-", "").ToUpper()
$addr = [Convert]::ToUInt64($cleanMac, 16)

$dev = Await ([Windows.Devices.Bluetooth.BluetoothLEDevice]::FromBluetoothAddressAsync($addr)) ([Windows.Devices.Bluetooth.BluetoothLEDevice])
if ($dev) {
    Write-Host "Device Found:" $dev.Name "Status:" $dev.ConnectionStatus
    $svcRes = Await ($dev.GetGattServicesAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Uncached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult])
    if (-not $svcRes -or $svcRes.Status -ne 'Success') {
        $svcRes = Await ($dev.GetGattServicesAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult])
    }
    Write-Host "Services Status:" $svcRes.Status "Count:" $svcRes.Services.Count
    foreach ($s in $svcRes.Services) {
        Write-Host "Service:" $s.Uuid
        $cRes = Await ($s.GetCharacteristicsAsync([Windows.Devices.Bluetooth.BluetoothCacheMode]::Cached)) ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult])
        if ($cRes -and $cRes.Status -eq 'Success') {
            foreach ($c in $cRes.Characteristics) {
                Write-Host "   Char:" $c.Uuid "Prop:" $c.CharacteristicProperties
            }
        }
    }
} else {
    Write-Host "Device not found for MAC $Mac"
}

