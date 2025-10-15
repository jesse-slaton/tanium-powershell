# Tanium Deploy Packages

This directory contains PowerShell-based software deployment packages for Tanium Deploy.

## What are Deploy Packages?

Deploy Packages handle software lifecycle management: installation, updates, and removal. These packages are specifically designed for use with Tanium Deploy and handle the complete software deployment process.

## Key Characteristics

- **Software Lifecycle**: Install, Update, Remove operations
- **Idempotent**: Safe to run multiple times (especially important for MSIs)
- **No -WhatIf Required**: Tanium Deploy manages deployment lifecycle
- **Exit Codes**: Must return appropriate codes for Tanium Deploy
- **Logging**: Comprehensive logging for troubleshooting

## Documentation Standards

Deploy Packages do NOT require comment-based help (Get-Help support). Use simple file headers:

```powershell
# Script: Deploy-SoftwareName.ps1
# Purpose: Install/Update/Remove Software Name
# Author: Jesse Slaton
# Created: YYYY-MM-DD
# Modified: YYYY-MM-DD
#
# Tanium Deploy Package Specifications:
#   - Type: Software Deployment
#   - Operations: Install, Update, Remove
#   - Logging: Detailed operation logs
#   - Idempotent: Handles MSI error codes appropriately
#
# Prerequisites:
#   - Required files in package directory
#   - Tanium Client installed
#   - Administrative privileges
#
# Parameters:
#   Operation - Install, Update, or Remove
#   Version - Software version to deploy
#
# Exit Codes:
#   0 - Success
#   3010 - Success, reboot required
#   1618 - Another installation in progress (retry)
#   Other - See MSI error codes or installer documentation
```

See [DOCUMENTATION_STANDARDS.md](../DOCUMENTATION_STANDARDS.md) for complete guidance.

## MSI-Based Deployments

Most deployments use Windows Installer (MSI). Special considerations apply.

### Standard MSI Arguments

```powershell
# Installation
msiexec.exe /i "package.msi" ALLUSERS=1 /qn /norestart /l*v "C:\path\to\install.log"

# Uninstallation
msiexec.exe /x "{PRODUCT-CODE-GUID}" ALLUSERS=1 /qn /norestart /l*v "C:\path\to\uninstall.log"

# Repair
msiexec.exe /fa "package.msi" ALLUSERS=1 /qn /norestart /l*v "C:\path\to\repair.log"
```

#### Argument Breakdown

- **ALLUSERS=1** - Machine-based install (all users)
- **/qn** - Quiet mode, no UI
- **/norestart** - Suppress automatic reboot (let Tanium control reboots)
- **/l*v** - Verbose logging (critical for troubleshooting)

### MSI Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Return 0 |
| 3010 | Success, reboot required | Return 3010 |
| 1605 | Product not found | Return 0 if Remove operation |
| 1618 | Another install running | Retry with exponential backoff |
| 1638 | Another version installed | Check Product Code, return 0 if already installed |
| 1603 | Fatal error | Return 1603, check logs |

See [DOCUMENTATION_STANDARDS.md - MSI Idempotency](../DOCUMENTATION_STANDARDS.md#msi-idempotency-considerations) for complete details.

### Installation State Check

**IMPORTANT**: Use Product Code GUID (matches Tanium Deploy Install Verification logic):

```powershell
function Test-MsiInstalled {
    param(
        [Parameter(Mandatory)]
        [string]$ProductCode  # {GUID}
    )

    $primaryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"
    $wow64Path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"

    return (Test-Path $primaryPath) -or (Test-Path $wow64Path)
}

# Pre-installation check
if (Test-MsiInstalled -ProductCode '{00AE1248-489D-48B6-805D-714F8F123521}') {
    Write-Output "Already installed"
    Exit 0  # Idempotent success
}
```

## Using the MSI PowerShell Module

**Recommended**: Use the MSI module to inspect MSI files and extract metadata.

```powershell
# Install module
Install-Module -Name MSI -Scope CurrentUser

# Get MSI properties
$msiInfo = Get-MSIFileInformation -Path ".\package.msi"

# Extract properties
$ProductCode = $msiInfo.ProductCode      # {GUID}
$ProductName = $msiInfo.ProductName      # "My Application"
$ProductVersion = $msiInfo.ProductVersion # "1.2.3.4"
$UpgradeCode = $msiInfo.UpgradeCode      # {GUID} - Important!
```

### Upgrade Code Sanity Check

If Upgrade Code changes between versions, you're dealing with a different product line:

```powershell
$oldMsi = Get-MSIFileInformation -Path "OldVersion.msi"
$newMsi = Get-MSIFileInformation -Path "NewVersion.msi"

if ($oldMsi.UpgradeCode -ne $newMsi.UpgradeCode) {
    # Different product line - uninstall old, install new
    Write-Warning "Upgrade Code changed - requires uninstall then install"

    # Uninstall old
    $uninstallArgs = "/x `"$($oldMsi.ProductCode)`" ALLUSERS=1 /qn /norestart /l*v `"$UninstallLog`""
    $process = Start-Process msiexec.exe -ArgumentList $uninstallArgs -Wait -PassThru

    # Install new
    $installArgs = "/i `"$NewMsiPath`" ALLUSERS=1 /qn /norestart /l*v `"$InstallLog`""
    $process = Start-Process msiexec.exe -ArgumentList $installArgs -Wait -PassThru
}
```

## Best Practices

### 1. Always Pre-Check Installation State

```powershell
# Before installing
if (Test-MsiInstalled -ProductCode $ProductCode) {
    Write-Output "Product already installed"
    Exit 0
}

# Before removing
if (-not (Test-MsiInstalled -ProductCode $ProductCode)) {
    Write-Output "Product not installed - already removed"
    Exit 0
}
```

### 2. Implement Retry Logic for 1618

```powershell
$maxRetries = 5
$waitSeconds = 30
$attempt = 0

do {
    $attempt++
    $process = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
    $exitCode = $process.ExitCode

    if ($exitCode -eq 1618 -and $attempt -le $maxRetries) {
        Write-Output "Another installation in progress. Waiting $waitSeconds seconds..."
        Start-Sleep -Seconds $waitSeconds
        $waitSeconds *= 2  # Exponential backoff
    }
    else {
        break
    }
} while ($attempt -le $maxRetries)
```

### 3. Handle Exit Codes Appropriately

```powershell
switch ($exitCode) {
    0 {
        Write-Output "Installation successful"
        Exit 0
    }
    3010 {
        Write-Output "Installation successful - Reboot required"
        Exit 3010  # Let Tanium know reboot needed
    }
    1605 {
        if ($Operation -eq 'Remove') {
            Write-Output "Product not found - Already removed"
            Exit 0  # Idempotent success
        }
        Exit 1605
    }
    1618 {
        Write-Error "Another installation in progress - Retries exhausted"
        Exit 1618
    }
    default {
        Write-Error "Installation failed with exit code $exitCode"
        Exit $exitCode
    }
}
```

### 4. Use Verbose Logging

```powershell
$logPath = "$env:SystemDrive\Windows\Temp\$ProductName-$Operation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

$msiArgs = "/i `"$MsiPath`" ALLUSERS=1 /qn /norestart /l*v `"$logPath`""

Write-Output "MSI log: $logPath"
```

## Template Files

See `Templates/` subdirectory for reusable templates:
- **MSI-Deploy-Template.ps1** - Complete MSI deployment with idempotency
- **New-MSIDeployScript.ps1** - Script generator using MSI module

## Testing Deploy Packages

Test thoroughly before production deployment:

```powershell
# Test 1: Clean install
.\Deploy-App.ps1 -Operation Install -Version "1.2.3"
# Expected: Exit 0, product installed

# Test 2: Idempotent install
.\Deploy-App.ps1 -Operation Install -Version "1.2.3"
# Expected: Exit 0 immediately (pre-check detects installation)

# Test 3: Update
.\Deploy-App.ps1 -Operation Install -Version "1.2.4"
# Expected: Exit 0 or 3010, product updated

# Test 4: Remove
.\Deploy-App.ps1 -Operation Remove
# Expected: Exit 0, product removed

# Test 5: Idempotent remove
.\Deploy-App.ps1 -Operation Remove
# Expected: Exit 0 (pre-check detects already removed)

# Test 6: Check logs
Get-Content "C:\Windows\Temp\*install*.log" | Select-String "error|fail" -Context 2
```

## Common Patterns

### Complete MSI Deployment

```powershell
param(
    [Parameter(Mandatory)]
    [ValidateSet('Install', 'Remove')]
    [string]$Operation
)

#Requires -RunAsAdministrator

$ProductCode = '{12345678-1234-1234-1234-123456789012}'
$MsiPath = "$PSScriptRoot\MyApp.msi"
$LogPath = "$env:SystemDrive\Windows\Temp\MyApp-$Operation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Pre-check
if ($Operation -eq 'Install') {
    if (Test-MsiInstalled -ProductCode $ProductCode) {
        Write-Output "Already installed"
        Exit 0
    }
    $msiArgs = "/i `"$MsiPath`" ALLUSERS=1 /qn /norestart /l*v `"$LogPath`""
}
else {
    if (-not (Test-MsiInstalled -ProductCode $ProductCode)) {
        Write-Output "Not installed - already removed"
        Exit 0
    }
    $msiArgs = "/x `"$ProductCode`" ALLUSERS=1 /qn /norestart /l*v `"$LogPath`""
}

# Execute
$process = Start-Process msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
$exitCode = $process.ExitCode

# Handle exit code
switch ($exitCode) {
    { $_ -in @(0, 3010) } {
        Write-Output "Success (Exit code: $exitCode)"
        Exit $exitCode
    }
    1605 {
        if ($Operation -eq 'Remove') {
            Exit 0  # Already removed
        }
        Exit 1605
    }
    default {
        Write-Error "Failed with exit code $exitCode. Check log: $LogPath"
        Exit $exitCode
    }
}
```

## Related Documentation

- [Tanium Deploy Documentation](https://docs.tanium.com/deploy/deploy/index.html)
- [Windows Installer Error Codes](https://learn.microsoft.com/en-us/windows/win32/msi/error-codes)
- [MSI PowerShell Module](https://www.powershellgallery.com/packages/MSI)
- [Repository Documentation Standards](../DOCUMENTATION_STANDARDS.md)
