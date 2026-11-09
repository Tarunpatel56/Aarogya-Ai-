Add-Type -AssemblyName System.Runtime.WindowsRuntime
[Windows.Devices.Bluetooth.BluetoothLEDevice,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null
[Windows.Devices.Bluetooth.GenericAttributeProfile.GattValueChangedEventArgs,Windows.Devices.Bluetooth,ContentType=WindowsRuntime] | Out-Null

$handlerType = [Windows.Foundation.TypedEventHandler[Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic,Windows.Devices.Bluetooth.GenericAttributeProfile.GattValueChangedEventArgs]]
Write-Host "Handler type found:" $handlerType.FullName

