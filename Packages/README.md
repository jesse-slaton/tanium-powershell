# Tanium Platform Packages

This directory contains PowerShell-based Tanium Platform Packages for system configuration and state changes.

## What are Platform Packages?

Platform Packages perform state-changing operations on endpoints such as registry modifications, service configuration, Active Directory changes, and system settings. Unlike Deploy Packages (software installation), Platform Packages modify system configuration.

## Key Characteristics

- **State-Changing**: Modifies system configuration
- **Idempotent**: Safe to run multiple times without adverse effects
- **Supports -WhatIf**: Should include `[CmdletBinding(SupportsShouldProcess)]`
- **Requires Admin**: Typically needs elevated privileges
- **Targeted Changes**: Specific, well-defined modifications

## Documentation Standards

Platform Packages do NOT require comment-based help (Get-Help support). Use simple file headers:

```powershell
# Script: Package-Name.ps1
# Purpose: Brief description of what this changes
# Author: Jesse Slaton
# Created: YYYY-MM-DD
# Modified: YYYY-MM-DD
#
# Tanium Package Specifications:
#   - Type: Platform Package (state-changing)
#   - Supports: -WhatIf, -Confirm
#   - Requires: Administrative privileges
#   - Idempotent: Safe to run multiple times
#
# Prerequisites:
#   - Run as Administrator
#   - Specific requirements
#
# Changes Made:
#   - Registry: HKLM:\Path\To\Key
#   - Services: ServiceName
#   - Files: C:\Path\To\File
```

See [DOCUMENTATION_STANDARDS.md](../DOCUMENTATION_STANDARDS.md) for complete guidance.

## Directory Structure

```
Packages/
├── ActiveDirectory/    # AD user/computer/group operations
├── FileSystem/         # File and directory operations
├── General/            # General-purpose packages
├── Network/            # Network configuration changes
├── Office/             # Tanium Client configuration
├── Registry/           # Registry modifications
├── Security/           # Security settings and certificates
└── System/             # System-level changes (services, settings)
```

## Idempotency Requirement

**CRITICAL**: All Platform Packages must be idempotent - safe to run multiple times.

### Good Example (Idempotent)

```powershell
#Requires -RunAsAdministrator

# Check current state first
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
$currentValue = (Get-ItemProperty -Path $regPath -Name DisableCompression -ErrorAction SilentlyContinue).DisableCompression

# Only make change if needed
if ($currentValue -ne 0) {
    Set-ItemProperty -Path $regPath -Name 'DisableCompression' -Value 0 -Type DWORD -Force
    Write-Output "SMBv3 compression disabled"
}
else {
    Write-Output "SMBv3 compression already disabled"
}
```

### Bad Example (Not Idempotent)

```powershell
# WRONG - Always makes change without checking current state
Set-ItemProperty -Path $regPath -Name 'DisableCompression' -Value 0 -Force
```

## Best Practices

### 1. Always Check Current State

```powershell
# Check before modifying
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force
}

$currentValue = (Get-ItemProperty -Path $registryPath -Name $keyName -ErrorAction SilentlyContinue).$keyName

if ($currentValue -ne $desiredValue) {
    Set-ItemProperty -Path $registryPath -Name $keyName -Value $desiredValue
}
```

### 2. Use ShouldProcess for State Changes

```powershell
[CmdletBinding(SupportsShouldProcess)]
param()

#Requires -RunAsAdministrator

if ($PSCmdlet.ShouldProcess("ServiceName", "Stop service")) {
    Stop-Service -Name ServiceName -Force
}
```

### 3. Provide Meaningful Output

```powershell
if ($changed) {
    Write-Output "Changed: $description"
}
else {
    Write-Output "No change needed: Already in desired state"
}
```

### 4. Handle Errors Gracefully

```powershell
Try {
    Set-ItemProperty -Path $regPath -Name $keyName -Value $value -ErrorAction Stop
    Write-Output "Success: Registry key updated"
}
Catch {
    Write-Error "Failed to update registry: $_"
    Exit 1
}
```

## Common Patterns

### Registry Modification

```powershell
#Requires -RunAsAdministrator

$regPath = "HKLM:\SOFTWARE\Company\Application"
$keyName = "Setting"
$desiredValue = "NewValue"

# Ensure path exists
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Check current value
$current = (Get-ItemProperty -Path $regPath -Name $keyName -ErrorAction SilentlyContinue).$keyName

# Only change if different
if ($current -ne $desiredValue) {
    Set-ItemProperty -Path $regPath -Name $keyName -Value $desiredValue
    Write-Output "Updated $keyName to $desiredValue"
}
else {
    Write-Output "Already configured correctly"
}
```

### Service Configuration

```powershell
#Requires -RunAsAdministrator

$serviceName = "MyService"
$desiredStartupType = "Automatic"

$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    if ($service.StartType -ne $desiredStartupType) {
        Set-Service -Name $serviceName -StartupType $desiredStartupType
        Write-Output "Service startup type changed to $desiredStartupType"
    }
    else {
        Write-Output "Service already configured correctly"
    }
}
else {
    Write-Error "Service $serviceName not found"
}
```

### File System Operation

```powershell
#Requires -RunAsAdministrator

$sourcePath = "$PSScriptRoot\config.xml"
$destPath = "C:\ProgramData\Application\config.xml"

# Ensure destination directory exists
$destDir = Split-Path $destPath -Parent
if (-not (Test-Path $destDir)) {
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
}

# Copy only if source is newer or destination doesn't exist
if (-not (Test-Path $destPath) -or ((Get-Item $sourcePath).LastWriteTime -gt (Get-Item $destPath).LastWriteTime)) {
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Output "Config file updated"
}
else {
    Write-Output "Config file already current"
}
```

## Testing Packages

Before deploying:

1. **Test idempotency**: Run twice, verify second run doesn't error
2. **Test -WhatIf**: Verify it shows what would change
3. **Test on clean system**: Verify it works from scratch
4. **Test on configured system**: Verify it detects existing config
5. **Test error conditions**: Missing permissions, locked files, etc.

```powershell
# Test sequence
.\Package.ps1 -WhatIf          # See what would change
.\Package.ps1                  # Make changes
.\Package.ps1                  # Run again - should report "already configured"
```

## Related Documentation

- [Tanium Package Authoring Guide](https://docs.tanium.com/platform_user/platform_user/authoring_actions.html)
- [PowerShell about_Functions_CmdletBindingAttribute](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute)
- [Repository Documentation Standards](../DOCUMENTATION_STANDARDS.md)
