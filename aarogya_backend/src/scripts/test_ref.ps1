$refs = @(
    "C:\Windows\System32\WinMetadata\Windows.Foundation.winmd",
    "C:\Windows\System32\WinMetadata\Windows.Devices.winmd",
    "C:\Windows\System32\WinMetadata\Windows.Storage.winmd",
    "System.Runtime.WindowsRuntime"
)
$code = @"
using System;
using Windows.Devices.Bluetooth;
public class TestBle {
    public static string Hello() { return "WinRT Ready"; }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies $refs
Write-Host ([TestBle]::Hello())

