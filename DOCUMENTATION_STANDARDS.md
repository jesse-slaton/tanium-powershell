# PowerShell Documentation Standards

This document defines the documentation standards for all PowerShell scripts in the tanium-powershell repository.

## Table of Contents

- [Overview](#overview)
- [Script Headers](#script-headers)
- [Comment-Based Help](#comment-based-help)
- [Templates by Script Type](#templates-by-script-type)
- [Best Practices](#best-practices)

## Overview

Documentation requirements vary by script type:

### Tanium Packages, Deploy Packages, and Sensors
These scripts are consumed by Tanium and do NOT need Get-Help support:
1. **Good file headers** with author, purpose, and date
2. **Markdown documentation** files explaining usage
3. **Inline comments** for complex logic
4. **CHANGELOG.md** for tracking version history (where necessary)

### Admin and API Scripts
These scripts are used directly by administrators and MUST have Get-Help support:
1. **Proper file headers** with author attribution
2. **Full comment-based help** following PowerShell standards
3. **Markdown documentation** for the directory/module
4. **Inline comments** for complex logic
5. **Examples** demonstrating practical usage via Get-Help
6. **CHANGELOG.md** for tracking version history (where necessary)

## Script Headers

### For Packages, Deploy Packages, and Sensors

Simple file header with essential information:

```powershell
# Script: Script-Name.ps1
# Purpose: Brief description of what this does
# Author: Jesse Slaton
# Created: YYYY-MM-DD
# Modified: YYYY-MM-DD
#
# Prerequisites:
#   - List requirements
#   - Module dependencies
#   - Permission requirements
```

### For Admin and API Scripts

Full comment-based help for Get-Help support:

#### Required Elements

- `.SYNOPSIS` - One-line description of what the script does
- `.DESCRIPTION` - Detailed explanation of functionality
- `.PARAMETER` - Description for each parameter
- `.EXAMPLE` - At least 2 practical examples
- `.NOTES` - Author, creation/modification dates, prerequisites, dependencies
- `.LINK` - Related documentation or Tanium resources (optional)

## Comment-Based Help

PowerShell's comment-based help system makes documentation accessible via `Get-Help`. Format:

```powershell
<#
.SYNOPSIS
    Brief one-line description

.DESCRIPTION
    Detailed description of what the script does, including:
    - Purpose and use case
    - Expected behavior
    - Any important warnings or considerations

.PARAMETER ParameterName
    Description of the parameter, including:
    - What it controls
    - Valid values or ranges
    - Default value (if applicable)

.EXAMPLE
    .\Script-Name.ps1 -Parameter Value

    Description of what this example does and expected output.

.EXAMPLE
    .\Script-Name.ps1 -Parameter1 Value1 -Parameter2 Value2

    Description of a more complex example.

.NOTES
    Author: Jesse Slaton
    Created: YYYY-MM-DD
    Modified: YYYY-MM-DD
    Version: 1.0

    Prerequisites:
    - List any required modules
    - List any required permissions
    - List any system requirements

    Dependencies:
    - External tools or scripts
    - Required files or configurations

.LINK
    https://docs.tanium.com/relevant-page
#>
```

## Templates by Script Type

### Tanium Sensor Template

Sensors are read-only data collection scripts that must execute in under 1000ms.
**Sensors do NOT need comment-based help** - use simple headers and document in README.md.

```powershell
# Script: SensorName.ps1
# Purpose: Retrieves [specific data] from the system
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
#   - Windows PowerShell 5.1 or later
#   - Appropriate WMI/CIM access permissions
#
# Expected Output: Value1|Value2|Value3

# Sensor logic here
# Must output pipe-delimited format
# Must execute in < 1000ms
```

### Tanium Platform Package Template

Platform Packages perform state-changing operations (registry, configuration, system settings, etc.).
**Platform Packages do NOT need comment-based help** - use simple headers and document in README.md.

**IMPORTANT: Platform Packages must be idempotent** - safe to run multiple times without adverse effects.

**CRITICAL LIMITATIONS - Tanium Execution Context**:
- **Runs as SYSTEM**: Tanium executes in SYSTEM context (not user context)
- **NO Active Directory operations**: SYSTEM cannot authenticate to AD - any AD changes must happen outside Tanium
- **NO credential storage**: Tanium has no secrets management - never store credentials
- **NO network authentication**: SYSTEM account cannot authenticate to remote resources
- **User context only via Deploy**: Tanium Deploy can execute as logged-in user when explicitly configured

**Note**: If a script requires AD access or credentials, it was likely not intended for Tanium execution.

```powershell
# Script: Package-Name.ps1
# Purpose: [Action] [Target] on the system
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
#   - Required PowerShell version
#
# Changes Made:
#   - List specific system changes
#   - Registry keys modified
#   - Services affected
#
# Parameters:
#   ParameterName - Description of parameter and valid values

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$ParameterName
)

#Requires -RunAsAdministrator

# Package logic here - MUST BE IDEMPOTENT
# Check current state before making changes
# Use ShouldProcess for state-changing operations
if ($PSCmdlet.ShouldProcess("Target", "Action")) {
    # Verify current state
    if (-not (Test-CurrentState)) {
        # Only perform action if needed
        Set-DesiredState
    }
}
```

### Tanium Deploy Package Template

Deploy Packages handle software lifecycle (install, update, remove). Do not require -WhatIf support as Tanium Deploy manages deployment lifecycle.
**Deploy Packages do NOT need comment-based help** - use simple headers and document in README.md.

**IMPORTANT: Deploy Packages should strive for idempotency** - safe to run multiple times without adverse effects.
See [MSI Idempotency Considerations](#msi-idempotency-considerations) for handling Windows Installer challenges.

```powershell
# Script: Deploy-Software.ps1
# Purpose: [Install|Update|Remove] [Software Name]
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
#   - Appropriate installation permissions
#
# Parameters:
#   Operation - Specify operation: Install, Update, or Remove
#   Version - Software version to deploy
#   LogPath - Path for installation logs (default: $env:TEMP\DeployLog.log)
#
# Exit Codes:
#   0 - Success
#   1 - General failure
#   1618 - Another installation in progress (retry recommended)
#   3010 - Success, reboot required
#   [Other codes as applicable]

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet('Install', 'Update', 'Remove')]
    [string]$Operation,

    [string]$Version,

    [string]$LogPath = "$env:TEMP\DeployLog.log"
)

#Requires -RunAsAdministrator
#Requires -Modules TaniumClient

# Deploy package logic here
# See MSI Idempotency Considerations section for handling MSI return codes
Exit $ExitCode
```

### Admin Script Template

Admin scripts manage the Tanium Client itself and must run outside of Tanium (cannot manage the client from within itself).

```powershell
<#
.SYNOPSIS
    [Action] Tanium Client [Component]

.DESCRIPTION
    Administrative script for managing Tanium Client [specific component].
    This script must be run outside of Tanium as it manages the Tanium Client process.

.PARAMETER ParameterName
    Description of parameter

.EXAMPLE
    .\Admin-Script.ps1 -Parameter Value

    Performs administrative action on Tanium Client.

.NOTES
    Author: Jesse Slaton
    Created: YYYY-MM-DD
    Modified: YYYY-MM-DD
    Version: 1.0

    Tanium Admin Script Specifications:
    - Must run outside Tanium environment
    - Manages Tanium Client components
    - Requires administrative access

    Prerequisites:
    - Run as Administrator
    - Tanium Client installed
    - Appropriate registry/filesystem permissions

    Components Managed:
    - Tanium Client Service
    - Tanium Patch
    - Tanium Deploy
    - [Other components]

.LINK
    https://docs.tanium.com/platform_install/platform_install/reference_client_management.html
#>

function Get-ComponentName {
    [CmdletBinding()]
    param()

    # Function logic
}

# Admin script logic here
```

## Advanced Tanium Patterns

### Package/Sensor Combo Pattern

For operations that exceed the 1000ms sensor timeout, use a **Package/Sensor combo**:

1. **Package** performs the long-running operation and writes results to an artifact file
2. **Sensor** quickly reads the artifact file (<1000ms) and returns data

This is Tanium's recommended approach for operations like:
- Filesystem searches (finding PST files, large file scans)
- Complex system queries requiring multiple WMI calls
- Operations requiring network calls or intensive processing

#### Example: File Search Package/Sensor Combo

**Package: Search-LargePSTFiles-Package.ps1**
```powershell
# Script: Search-LargePSTFiles-Package.ps1
# Purpose: Searches filesystem for PST files and writes results to JSON artifact
# Author: Jesse Slaton
#
# Tanium Package/Sensor Combo - Package Component
#   - Executes long-running filesystem search
#   - Writes results to artifact file for sensor to read
#   - Implements rate limiting to avoid excessive execution

$artifactPath = "$env:SystemDrive\Windows\Temp\TaniumPSTSearch.json"
$lastRunKey = "HKLM:\SOFTWARE\WOW6432Node\Tanium\Tanium Client\Sensor Data\PSTSearch"

# Rate limiting: Only run if last scan was >7 days ago
$lastRun = (Get-ItemProperty -Path $lastRunKey -Name LastRun -ErrorAction SilentlyContinue).LastRun
if ($lastRun) {
    $daysSinceLastRun = (New-TimeSpan -Start ([DateTime]$lastRun) -End (Get-Date)).Days
    if ($daysSinceLastRun -lt 7) {
        Write-Output "Skipped: Last run was $daysSinceLastRun days ago"
        Exit 0
    }
}

# Perform filesystem search (long-running)
$pstFiles = Get-ChildItem -Path "C:\" -Filter "*.pst" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -gt 1GB } |
    Select-Object FullName, @{N='SizeGB';E={[math]::Round($_.Length/1GB, 2)}}, LastWriteTime

# Write results to artifact
$pstFiles | ConvertTo-Json | Out-File -FilePath $artifactPath -Force

# Update last run timestamp
if (-not (Test-Path $lastRunKey)) {
    New-Item -Path $lastRunKey -Force | Out-Null
}
Set-ItemProperty -Path $lastRunKey -Name LastRun -Value (Get-Date).ToString('o')

Write-Output "Found $($pstFiles.Count) PST files. Results written to $artifactPath"
```

**Sensor: Get-LargePSTFiles-Sensor.ps1**
```powershell
# Script: Get-LargePSTFiles-Sensor.ps1
# Purpose: Reads PST search artifact and returns results
# Author: Jesse Slaton
#
# Tanium Package/Sensor Combo - Sensor Component
#   - Reads artifact file created by package
#   - Executes in <1000ms
#   - Returns pipe-delimited results

$artifactPath = "$env:SystemDrive\Windows\Temp\TaniumPSTSearch.json"

if (-not (Test-Path $artifactPath)) {
    Write-Output "No Data|Package not run yet"
    Exit 0
}

# Quick read of JSON artifact (<1000ms)
try {
    $pstFiles = Get-Content $artifactPath -Raw | ConvertFrom-Json

    if ($pstFiles.Count -eq 0) {
        Write-Output "0|No large PST files found"
    }
    else {
        # Return count and details pipe-delimited
        $details = $pstFiles | ForEach-Object { "$($_.FullName) ($($_.SizeGB)GB)" }
        Write-Output "$($pstFiles.Count)|$($details -join '; ')"
    }
}
catch {
    Write-Output "Error|Failed to read artifact"
}
```

### Rate Limiting Pattern (Platform Packages Only)

**Important**: Rate limiting via registry is for **Platform Packages** only. Tanium Deploy Packages should use Tanium Deploy's built-in rate limiting features instead.

For Platform Packages that are resource-intensive or generate network traffic, implement **rate limiting** using registry keys to prevent excessive execution.

**Registry Location** (accounts for OS bitness):
- **64-bit Windows**: `SOFTWARE\WOW6432Node\Tanium\Tanium Client\Sensor Data\RateLimits\<PackageName>`
- **32-bit Windows**: `SOFTWARE\Tanium\Tanium Client\Sensor Data\RateLimits\<PackageName>`

*Note: Tanium Client is a 32-bit application, so on 64-bit Windows it registers under WOW6432Node.*

**Registry Values**:
- **ExpiresAt** (String): RFC822 format with Zulu time - "Mon, 05 Jan 2015 15:17:59 +0000"
- **SetAt** (String): RFC822 format when rate limit was set

**Important**: All registry access must use `[Microsoft.Win32.RegistryKey]` class, not PowerShell registry providers.

#### Rate Limiting Components

The rate limiting system consists of three components:

1. **Helper Functions**: Inline functions for copy-paste into packages (`Packages/Templates/RateLimiting-Helpers.ps1`)
2. **Enumeration Sensor**: Lists all rate limits with expiration status (`Sensors/Get-RateLimitStatus.ps1`)
3. **Cleanup Package**: Removes expired rate limit entries (`Packages/Maintenance/Remove-ExpiredRateLimits-Package.ps1`)

#### Rate Limiting Implementation

Use the helper functions from `Packages/Templates/RateLimiting-Helpers.ps1` by copying them directly into your package script:

```powershell
# Script: Resource-Intensive-Package.ps1
# Implements rate limiting to execute no more than once per week

# ============================================================================
# RATE LIMITING HELPER FUNCTIONS (Copy from RateLimiting-Helpers.ps1)
# ============================================================================

function Get-RateLimitRegistryPath {
    param([string]$PackageName)
    if ([Environment]::Is64BitOperatingSystem) {
        "SOFTWARE\WOW6432Node\Tanium\Tanium Client\Sensor Data\RateLimits\$PackageName"
    } else {
        "SOFTWARE\Tanium\Tanium Client\Sensor Data\RateLimits\$PackageName"
    }
}

function Test-RateLimitExpired {
    param([string]$PackageName)

    $regPath = Get-RateLimitRegistryPath $PackageName
    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $false)

    if ($null -eq $regKey) { return $true }

    try {
        $expiresAt = $regKey.GetValue("ExpiresAt")
        if ($null -eq $expiresAt) { return $true }

        $expDate = [DateTime]::ParseExact($expiresAt, "ddd, dd MMM yyyy HH:mm:ss zzz", [System.Globalization.CultureInfo]::InvariantCulture)
        return ([DateTime]::UtcNow -ge $expDate)
    }
    catch {
        return $true
    }
    finally {
        if ($null -ne $regKey) { $regKey.Close() }
    }
}

function Set-RateLimit {
    param([string]$PackageName, [int]$Hours = 24)

    $regPath = Get-RateLimitRegistryPath $PackageName
    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $true)

    if ($null -eq $regKey) {
        $regKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($regPath)
    }

    try {
        $expires = (Get-Date).ToUniversalTime().AddHours($Hours)
        $expiresRFC822 = $expires.ToString("ddd, dd MMM yyyy HH:mm:ss +0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $setAtRFC822 = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss +0000", [System.Globalization.CultureInfo]::InvariantCulture)

        $regKey.SetValue("ExpiresAt", $expiresRFC822, [Microsoft.Win32.RegistryValueKind]::String)
        $regKey.SetValue("SetAt", $setAtRFC822, [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        if ($null -ne $regKey) { $regKey.Close() }
    }
}

# ============================================================================
# PACKAGE LOGIC WITH RATE LIMITING
# ============================================================================

# Check if rate limit has expired
if (Test-RateLimitExpired "MyPackage") {
    Write-Output "Executing resource-intensive operation..."

    # ... package logic here ...

    # Set rate limit for 7 days (168 hours)
    Set-RateLimit "MyPackage" -Hours 168
    Write-Output "Completed. Rate limited for 7 days."
} else {
    Write-Output "Rate limited. Run skipped."
}
```

#### When to Use Rate Limiting

Implement rate limiting for packages that:
- **Generate network traffic**: Large file downloads, API calls, web scraping
- **Are CPU intensive**: Complex calculations, compression, encryption
- **Are disk intensive**: Large file searches, disk scanning, log parsing
- **Take significant time**: Operations >30 seconds
- **Should run periodically**: Weekly/monthly maintenance tasks

#### Managing Rate Limits

**Enumerate Rate Limits**: Use the `Get-RateLimitStatus.ps1` sensor to list all configured rate limits:
```
PackageName1|Mon, 05 Jan 2025 15:17:59 +0000|False|PackageName2|Mon, 01 Jan 2025 10:00:00 +0000|True
```

**Cleanup Expired Entries**: Run the `Remove-ExpiredRateLimits-Package.ps1` package periodically to remove expired rate limit entries and prevent registry bloat.

## MSI Idempotency Considerations

Windows Installer (MSI) presents unique challenges for idempotency because it only allows single-instance execution. Deploy packages must handle specific error codes gracefully to ensure idempotent behavior.

**IMPORTANT**: Installation state checks must use the same logic as Tanium Deploy's Install Verification rule - checking for the Product Code GUID in the registry uninstall keys.

### Standard MSI Arguments

Use these standard arguments for all MSI-based deployments:

```powershell
# Installation
/i "path\to\package.msi" ALLUSERS=1 /qn /norestart /l*v "C:\path\to\install.log"

# Uninstallation
/x "{PRODUCT-CODE-GUID}" ALLUSERS=1 /qn /norestart /l*v "C:\path\to\uninstall.log"

# Update/Repair
/fa "path\to\package.msi" ALLUSERS=1 /qn /norestart /l*v "C:\path\to\repair.log"
```

#### Argument Breakdown

- **ALLUSERS=1** - Machine-based install (all users). Use for Tanium Deploy packages.
- **ALLUSERS=2** - Per-user install (current user only). Rarely used with Tanium.
- **ALLUSERS=""** - Let MSI decide based on package configuration.
- **/qn** - Quiet mode, no UI
- **/norestart** - Suppress automatic reboot (let Tanium Deploy control reboots)
- **/l*v** - Verbose logging (all information including verbose)

### MSI Error Codes for Idempotency

Reference: [Windows Installer Error Codes](https://learn.microsoft.com/en-us/windows/win32/msi/error-codes)

#### Success Codes (Return as-is)

| Code | Name | Description |
|------|------|-------------|
| 0 | ERROR_SUCCESS | Success |
| 3010 | ERROR_SUCCESS_REBOOT_REQUIRED | Success, reboot required |
| 1641 | ERROR_SUCCESS_REBOOT_INITIATED | Success, reboot initiated (treat as 0) |

#### Idempotency-Safe Codes

| Code | Name | When to Treat as Success |
|------|------|-------------------------|
| 1605 | ERROR_UNKNOWN_PRODUCT | Remove operation only |
| 1638 | ERROR_PRODUCT_VERSION | If Product Code already exists in registry |

#### Retry-Required Codes

| Code | Name | Action |
|------|------|--------|
| 1618 | ERROR_INSTALL_ALREADY_RUNNING | Retry with exponential backoff |

### Using the MSI PowerShell Module

**Recommended**: Use the [MSI PowerShell Module](https://www.powershellgallery.com/packages/MSI) to inspect MSI files and extract metadata.

```powershell
# Install the module
Install-Module -Name MSI -Scope CurrentUser

# Get MSI properties
$msiInfo = Get-MSIFileInformation -Path "C:\path\to\package.msi"

# Extract key properties
$ProductCode = $msiInfo.ProductCode      # {GUID}
$ProductName = $msiInfo.ProductName      # "My Application"
$ProductVersion = $msiInfo.ProductVersion # "1.2.3.4"
$Manufacturer = $msiInfo.Manufacturer    # "Vendor Name"
$UpgradeCode = $msiInfo.UpgradeCode      # {GUID} - Important for updates!
```

#### Upgrade Code Sanity Check

The **Upgrade Code** links related product versions. If it changes, you're dealing with a different product line that requires special handling:

```powershell
# Compare Upgrade Codes between versions
$oldMsi = Get-MSIFileInformation -Path "OldVersion.msi"
$newMsi = Get-MSIFileInformation -Path "NewVersion.msi"

if ($oldMsi.UpgradeCode -ne $newMsi.UpgradeCode) {
    Write-Warning "Upgrade Code changed! This is a different product line."
    Write-Warning "Update operation should: 1) Uninstall old ProductCode, 2) Install new MSI"

    # Handle as separate install/uninstall
    # Uninstall old product first
    $uninstallArgs = "/x `"$($oldMsi.ProductCode)`" ALLUSERS=1 /qn /norestart /l*v `"$UninstallLog`""
    Start-Process msiexec.exe -ArgumentList $uninstallArgs -Wait

    # Then install new product
    $installArgs = "/i `"$NewMsiPath`" ALLUSERS=1 /qn /norestart /l*v `"$InstallLog`""
    Start-Process msiexec.exe -ArgumentList $installArgs -Wait
}
else {
    # Same product line - normal upgrade
    $installArgs = "/i `"$NewMsiPath`" ALLUSERS=1 /qn /norestart /l*v `"$InstallLog`""
    Start-Process msiexec.exe -ArgumentList $installArgs -Wait
}
```

### Template Files

See `Deploy-Packages/Templates/` for reusable MSI deployment templates:
- **MSI-Deploy-Template.ps1** - Complete MSI deployment template with idempotency
- **New-MSIDeployScript.ps1** - Script generator using MSI module to create deployment packages

## Best Practices

### General Guidelines

1. **Be Specific**: Synopsis should clearly state what the script does
2. **Use Examples**: Provide at least 2 real-world examples
3. **Document Prerequisites**: List all requirements (modules, permissions, etc.)
4. **Include Author Info**: Always attribute to Jesse Slaton
5. **Version History**: Update Modified date when making changes
6. **Link to Docs**: Include relevant Tanium documentation links

### Parameter Documentation

- Describe purpose and valid values
- Note default values
- Explain any validation rules
- Include examples in context

### Example Documentation

```powershell
.EXAMPLE
    .\Get-TaniumClientVersion.ps1

    Returns: 7.4.5.1234

    Retrieves the currently installed Tanium Client version.

.EXAMPLE
    Get-TaniumClientVersion | Where-Object { $_ -match '^7\.4' }

    Returns version only if it starts with 7.4, useful for version validation.
```

### Notes Section Best Practices

```powershell
.NOTES
    Author: Jesse Slaton
    Created: 2024-01-15
    Modified: 2024-03-20
    Version: 2.1

    Tanium Sensor Specifications:
    - Execution time: ~50ms typical
    - Output format: Pipe-delimited
    - Read-only: No system changes

    Prerequisites:
    - Windows PowerShell 5.1+
    - WMI/CIM read permissions
    - Tanium Client 7.4+

    Dependencies:
    - None

    Known Issues:
    - May timeout on systems with >1000 registry keys
    - Requires elevation for certain registry hives
```

### Inline Comments

For complex logic, add inline comments:

```powershell
# Check if Office ClickToRun is installed by verifying registry path
if (Test-Path -Path $OfficeRegistryPath) {
    # Gather installed ProductReleaseIDs to determine which Office products are present
    $ProductReleaseIds = (Get-OfficeConfiguration -Value 'ProductReleaseIds').split(',')

    # Process each product to identify excluded apps
    foreach ($ProductReleaseId in $ProductReleaseIds) {
        # Excluded apps are stored per-product in registry
        $ExcludedApps = (Get-OfficeConfiguration -Value "$ProductReleaseId.ExcludedApps").split(',')
    }
}
```

### Function Documentation

Functions within scripts should also have comment-based help:

```powershell
function Get-TaniumClientDirectory {
    <#
    .SYNOPSIS
        Gets the Tanium Client installation directory

    .DESCRIPTION
        Queries the registry to determine the Tanium Client installation path.
        Checks both 32-bit and 64-bit registry locations.

    .EXAMPLE
        $ClientPath = Get-TaniumClientDirectory

        Returns: C:\Program Files (x86)\Tanium\Tanium Client

    .NOTES
        Helper function for locating Tanium Client files and logs
    #>
    [CmdletBinding()]
    param()

    # Function logic
}
```

## Directory README Files

Each major directory should have a README.md explaining:

- Purpose of scripts in this directory
- Common use cases
- Prerequisites or dependencies
- Naming conventions
- Organization structure

See individual directory READMEs for specific guidance.

## CHANGELOG.md

Use CHANGELOG.md files to track significant changes over time. **Use when necessary** for:

- Complex scripts with multiple versions
- Scripts with breaking changes
- Widely-used scripts that need version tracking
- Directory-level changes affecting multiple scripts

### CHANGELOG Format

Follow [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features in development

## [1.2.0] - 2024-03-15

### Added
- New parameter for custom timeout values
- Support for additional Office channels

### Changed
- Improved error handling for network timeouts
- Updated default log path

### Fixed
- Fixed issue with registry detection on 32-bit systems

### Deprecated
- Old parameter name (use new name instead)

## [1.1.0] - 2024-02-01

### Added
- Initial support for Office 2021

### Changed
- Refactored download logic

## [1.0.0] - 2024-01-15

### Added
- Initial release
- Basic install/update/remove operations
```

### Changelog Categories

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security-related changes

### When NOT to Use CHANGELOG

- Simple single-purpose scripts that rarely change
- One-off utility scripts
- Scripts still in initial development (pre-1.0)

## Validation

### For Packages, Deploy Packages, and Sensors

Before committing:

1. Verify file header includes author, purpose, and dates
2. Check that inline comments explain complex logic
3. Ensure README.md exists for the directory
4. Verify CHANGELOG.md exists if script has version history
5. Test script functionality

### For Admin and API Scripts

Before committing:

1. Test `Get-Help .\Script-Name.ps1` shows proper help
2. Test `Get-Help .\Script-Name.ps1 -Examples` displays examples
3. Test `Get-Help .\Script-Name.ps1 -Parameter ParameterName` shows parameter help
4. Verify all parameters are documented
5. Ensure examples are accurate and runnable
6. Verify README.md exists for the directory
7. Check CHANGELOG.md exists if script has version history

## References

- [PowerShell Comment-Based Help](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
- [Tanium Sensor Authoring Guide](https://docs.tanium.com/platform_user/platform_user/authoring_sensors.html)
- [Tanium Package Development](https://docs.tanium.com/platform_user/platform_user/authoring_actions.html)
- [PowerShell Best Practices](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/required-development-guidelines)
