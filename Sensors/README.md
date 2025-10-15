# Tanium Sensors

This directory contains PowerShell-based Tanium sensors for data collection.

## What are Tanium Sensors?

Sensors are read-only scripts that collect information from endpoints and return data to the Tanium platform. Sensors must execute quickly (<1000ms) and cannot make system changes.

## Key Characteristics

- **Read-Only**: No system modifications allowed
- **Fast Execution**: Must complete in under 1000ms
- **Pipe-Delimited Output**: Results typically formatted as `Value1|Value2|Value3`
- **Lightweight**: Minimal resource consumption
- **CIM/WMI Access**: Common data sources

## Documentation Standards

Sensors do NOT require comment-based help (Get-Help support). Use simple file headers:

```powershell
# Script: SensorName.ps1
# Purpose: Brief description
# Author: Jesse Slaton
# Created: YYYY-MM-DD
# Modified: YYYY-MM-DD
#
# Tanium Sensor Specifications:
#   - Execution time: < 1000ms
#   - Output format: Pipe-delimited
#   - Read-only: No system changes
#
# Prerequisites:
#   - List requirements
#
# Expected Output: Value1|Value2|Value3
```

See [DOCUMENTATION_STANDARDS.md](../DOCUMENTATION_STANDARDS.md) for complete guidance.

## Current Sensors

| Sensor | Purpose |
|--------|---------|
| Get-ComputerInfo.ps1 | Computer model/manufacturer information |
| GetOdbcDsnsToJSON.ps1 | ODBC data sources in JSON format |
| GetOSBrandName.ps1 | Operating system brand name |
| GetOSSetupDate.ps1 | OS installation date |
| GetSystemDriveBusandMediaType.ps1 | Drive bus type and media type |
| Get_SecureBootStatus.ps1 | Secure Boot enabled status |
| HasWirelessAdapter.ps1 | Wireless adapter presence check |

## Best Practices

### Performance

- Use CIM cmdlets over WMI when possible (faster)
- Cache expensive operations
- Avoid loops over large datasets
- Test execution time: `Measure-Command { .\SensorName.ps1 }`

### Output Format

- Use pipe-delimited for multiple values: `Value1|Value2|Value3`
- Use simple strings for single values
- Handle errors gracefully (return meaningful error indicators)
- Avoid Write-Host (use Write-Output or direct output)

### Error Handling

```powershell
Try {
    $result = Get-CimInstance -ClassName Win32_OperatingSystem
    Write-Output $result.Caption
}
Catch {
    Write-Output "Error: Unable to retrieve OS information"
}
```

## Common Patterns

### Registry Query

```powershell
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"
if (Test-Path $regPath) {
    $value = (Get-ItemProperty -Path $regPath -Name ProductName).ProductName
    Write-Output $value
}
else {
    Write-Output "Not Found"
}
```

### WMI/CIM Query

```powershell
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
Write-Output "$($os.Caption)|$($os.Version)|$($os.BuildNumber)"
```

### File System Check

```powershell
if (Test-Path "C:\Program Files\MyApp\app.exe") {
    $version = (Get-Item "C:\Program Files\MyApp\app.exe").VersionInfo.FileVersion
    Write-Output $version
}
else {
    Write-Output "Not Installed"
}
```

## Testing Sensors

Before deploying:

1. **Test execution time**: Must be under 1000ms
   ```powershell
   Measure-Command { .\SensorName.ps1 }
   ```

2. **Test on multiple OS versions**: Ensure compatibility

3. **Test error conditions**: Missing files, denied access, etc.

4. **Verify output format**: Check for consistency

## Related Documentation

- [Tanium Sensor Authoring Guide](https://docs.tanium.com/platform_user/platform_user/authoring_sensors.html)
- [PowerShell Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/required-development-guidelines)
- [Repository Documentation Standards](../DOCUMENTATION_STANDARDS.md)
