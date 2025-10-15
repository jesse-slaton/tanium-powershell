# Tanium Admin Scripts

This directory contains administrative scripts for managing Tanium Client components.

## What are Admin Scripts?

Admin scripts manage the Tanium Client itself, including Tanium Patch and Tanium Deploy. **These scripts must run outside of the Tanium environment** because you cannot manage the Tanium Client from within itself.

## Key Characteristics

- **External Execution**: Cannot run within Tanium (managing the client from itself)
- **Full Comment-Based Help**: Must support Get-Help (unlike Packages/Sensors)
- **Administrative Access**: Requires elevated privileges
- **Client Management**: Tanium Client, Tanium Patch, Tanium Deploy operations
- **Functions**: Typically contain reusable functions

## Documentation Standards

**Admin scripts REQUIRE full comment-based help for Get-Help support**:

```powershell
<#
.SYNOPSIS
    Brief description of what this script does

.DESCRIPTION
    Detailed description of functionality and use cases

.PARAMETER ParameterName
    Description of the parameter

.EXAMPLE
    .\Get-TaniumClientPatchVersion-Package.ps1

    Returns: 1.6.5.1234

.NOTES
    Author: Jesse Slaton
    Created: YYYY-MM-DD
    Modified: YYYY-MM-DD

    Prerequisites:
    - Tanium Client installed
    - Administrative privileges

.LINK
    https://docs.tanium.com/patch/patch/index.html
#>

function Get-TaniumClientPatchVersion {
    [CmdletBinding()]
    param()

    # Function implementation
}
```

See [DOCUMENTATION_STANDARDS.md](../DOCUMENTATION_STANDARDS.md) for complete guidance.

## Directory Structure

```
Admin/
├── ActiveDirectory/    # AD-related operations (see Issue #11 for review)
├── FileSystem/         # File system operations for Tanium
├── Office/             # Tanium Client configuration functions
├── Software/           # Software-related Tanium operations
└── System/             # System-level Tanium operations
```

## Why Admin Scripts Must Run Externally

**You cannot manage the Tanium Client from within Tanium** for these reasons:

1. **Service Dependency**: Stopping/restarting Tanium Client would kill the running script
2. **File Locks**: Tanium Client locks its own files and databases
3. **Process Conflicts**: Cannot update running processes
4. **Registry Access**: Tanium Client may hold locks on its registry keys

### Examples Requiring External Execution

- Stopping/starting Tanium Client service
- Updating Tanium Client binaries
- Modifying Tanium Client configuration files
- Clearing Tanium Client databases
- Installing/removing Tanium modules
- Tanium Patch operations
- Tanium Deploy operations

## Best Practices

### 1. Always Use Comment-Based Help

Every Admin script and function must have full comment-based help:

```powershell
<#
.SYNOPSIS
    Gets the Tanium Patch version

.DESCRIPTION
    Retrieves the version of Tanium Patch from the manifest file.
    Must be run outside of Tanium as it accesses Tanium Client components.

.EXAMPLE
    .\Get-TaniumClientPatchVersion-Package.ps1

    Returns the Tanium Patch version number.

.EXAMPLE
    $version = .\Get-TaniumClientPatchVersion-Package.ps1
    if ($version -match '^1\.6') {
        Write-Host "Patch 1.6.x detected"
    }

.NOTES
    Author: Jesse Slaton
    Created: 2022-01-15
    Modified: 2025-10-14
    Version: 1.1

    Prerequisites:
    - Tanium Client with Patch module installed
    - Access to Tanium Client directory

    Dependencies:
    - Get-TaniumClientPatchManifest function

.LINK
    https://docs.tanium.com/patch/patch/index.html
#>
```

### 2. Check for Tanium Client Installation

```powershell
function Get-TaniumClientPath {
    <#
    .SYNOPSIS
        Gets the Tanium Client installation path

    .DESCRIPTION
        Queries the registry to find the Tanium Client installation directory.
        Checks both 64-bit and 32-bit registry locations.

    .EXAMPLE
        Get-TaniumClientPath
        Returns: C:\Program Files (x86)\Tanium\Tanium Client

    .NOTES
        Helper function for locating Tanium Client files and configurations
    #>
    [CmdletBinding()]
    param()

    $regPaths = @(
        'HKLM:\Software\Tanium\Tanium Client',
        'HKLM:\Software\WOW6432Node\Tanium\Tanium Client'
    )

    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            $clientPath = (Get-ItemProperty -Path $path -Name Path -ErrorAction SilentlyContinue).Path
            if ($clientPath -and (Test-Path $clientPath)) {
                return $clientPath
            }
        }
    }

    throw "Tanium Client not found. Ensure Tanium Client is installed."
}
```

### 3. Require Administrative Privileges

```powershell
#Requires -RunAsAdministrator

function Set-TaniumClientSetting {
    <#
    .SYNOPSIS
        Configures a Tanium Client setting

    .PARAMETER SettingName
        Name of the setting to configure

    .PARAMETER Value
        Value to set

    .EXAMPLE
        Set-TaniumClientSetting -SettingName "LogVerbosityLevel" -Value "3"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SettingName,

        [Parameter(Mandatory)]
        [string]$Value
    )

    # Admin operations here
}
```

### 4. Use Proper Error Handling

```powershell
function Get-TaniumClientPatchLog {
    <#
    .SYNOPSIS
        Retrieves the Tanium Patch log file contents

    .PARAMETER Tail
        Number of lines to retrieve from end of log (default: 100)

    .EXAMPLE
        Get-TaniumClientPatchLog -Tail 50
        Returns the last 50 lines from the Patch log
    #>
    [CmdletBinding()]
    param(
        [int]$Tail = 100
    )

    try {
        $clientPath = Get-TaniumClientPath
        $logPath = Join-Path $clientPath "Patch\TaniumPatch.log"

        if (-not (Test-Path $logPath)) {
            Write-Warning "Patch log not found at $logPath"
            return $null
        }

        Get-Content $logPath -Tail $Tail
    }
    catch {
        Write-Error "Failed to retrieve Patch log: $_"
    }
}
```

## Common Patterns

### Accessing Tanium Client Configuration

```powershell
function Get-TaniumClientSetting {
    <#
    .SYNOPSIS
        Gets a Tanium Client configuration setting

    .DESCRIPTION
        Reads the Tanium Client configuration file and retrieves the specified setting.

    .PARAMETER SettingName
        Name of the setting to retrieve (e.g., "ServerName", "ServerPort")

    .EXAMPLE
        Get-TaniumClientSetting -SettingName "ServerName"
        Returns: tanium.company.com

    .NOTES
        Reads from TaniumClient.dat configuration file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SettingName
    )

    $clientPath = Get-TaniumClientPath
    $configFile = Join-Path $clientPath "TaniumClient.dat"

    if (-not (Test-Path $configFile)) {
        throw "Tanium Client configuration file not found"
    }

    # Parse configuration file
    $content = Get-Content $configFile
    foreach ($line in $content) {
        if ($line -match "^$SettingName=(.+)$") {
            return $matches[1].Trim()
        }
    }

    return $null
}
```

### Tanium Patch Operations

```powershell
function Start-TaniumClientPatchScan {
    <#
    .SYNOPSIS
        Initiates a Tanium Patch scan

    .DESCRIPTION
        Triggers Tanium Patch to perform a scan for missing patches.
        Must be run outside of Tanium with administrative privileges.

    .EXAMPLE
        Start-TaniumClientPatchScan
        Initiates a patch scan and waits for completion

    .NOTES
        Author: Jesse Slaton
        Requires:
        - Tanium Client with Patch module installed
        - Administrative privileges
    #>
    [CmdletBinding()]
    param()

    #Requires -RunAsAdministrator

    $clientPath = Get-TaniumClientPath
    $patchExe = Join-Path $clientPath "Patch\TaniumPatch.exe"

    if (-not (Test-Path $patchExe)) {
        throw "Tanium Patch not installed at $patchExe"
    }

    Write-Verbose "Initiating Tanium Patch scan..."
    $process = Start-Process -FilePath $patchExe -ArgumentList "/scan" -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Output "Patch scan completed successfully"
    }
    else {
        Write-Error "Patch scan failed with exit code $($process.ExitCode)"
    }

    return $process.ExitCode
}
```

### Tanium Deploy Operations

```powershell
function Get-TaniumClientDeployVersion {
    <#
    .SYNOPSIS
        Gets the Tanium Deploy version

    .DESCRIPTION
        Retrieves the version of Tanium Deploy from the manifest file.
        Must be run outside of Tanium.

    .EXAMPLE
        Get-TaniumClientDeployVersion
        Returns: 7.4.5.1234

    .NOTES
        Requires Tanium Client with Deploy module installed
    #>
    [CmdletBinding()]
    param()

    $clientPath = Get-TaniumClientPath
    $deployManifest = Join-Path $clientPath "Deploy\TaniumDeploy.manifest"

    if (-not (Test-Path $deployManifest)) {
        throw "Tanium Deploy not installed"
    }

    try {
        [xml]$manifest = Get-Content $deployManifest
        return $manifest.Manifest.Version
    }
    catch {
        Write-Error "Failed to parse Deploy manifest: $_"
    }
}
```

## Testing Admin Scripts

Since these run outside Tanium, test using standard PowerShell cmdlets:

```powershell
# Test Get-Help support
Get-Help .\Get-TaniumClientPatchVersion-Package.ps1 -Full

# Test examples section
Get-Help .\Get-TaniumClientPatchVersion-Package.ps1 -Examples

# Test parameter help
Get-Help .\Start-TaniumClientPatchScan.ps1 -Parameter Tail

# Test function execution
.\Get-TaniumClientPatchVersion-Package.ps1

# Test with parameters
.\Get-TaniumClientSetting.ps1 -SettingName "ServerName"
```

### Validation Checklist

Before committing Admin scripts:

- [ ] Full comment-based help implemented
- [ ] At least 2 examples provided
- [ ] All parameters documented
- [ ] Error handling implemented
- [ ] Requires statements added (#Requires -RunAsAdministrator)
- [ ] Get-Help displays correctly
- [ ] Tested on clean system
- [ ] Tested with missing Tanium components (graceful errors)

## Common Admin Tasks

### Diagnostic Information

| Function | Purpose |
|----------|---------|
| Get-TaniumClientVersion | Get Client version |
| Get-TaniumClientPatchVersion | Get Patch module version |
| Get-TaniumClientDeployVersion | Get Deploy module version |
| Get-TaniumClientConfiguration | Get client configuration |

### Log Management

| Function | Purpose |
|----------|---------|
| Get-TaniumClientLog | View Client logs |
| Get-TaniumClientPatchLog | View Patch logs |
| Get-TaniumClientDeployLog | View Deploy logs |
| Search-TaniumClientLog | Search logs for patterns |

### Patch Management

| Function | Purpose |
|----------|---------|
| Start-TaniumClientPatchScan | Initiate patch scan |
| Get-TaniumClientPatchApplicablePatches | List applicable patches |
| Get-TaniumClientPatchScanResults | Get scan results |
| Get-TaniumClientPatchManifest | Get patch manifest data |
| Remove-TaniumClientPatchScanResults | Clear scan results |

### Deploy Management

| Function | Purpose |
|----------|---------|
| Get-TaniumClientDeployDeployment | List deployments |
| Get-TaniumClientDeployScanHistory | Get scan history |
| Start-TaniumClientDeployCatalogScan | Initiate catalog scan |
| Get-TaniumClientDeployDbTable | Query Deploy database |

## Related Documentation

- [Tanium Client Management](https://docs.tanium.com/platform_install/platform_install/reference_client_management.html)
- [Tanium Patch Documentation](https://docs.tanium.com/patch/patch/index.html)
- [Tanium Deploy Documentation](https://docs.tanium.com/deploy/deploy/index.html)
- [PowerShell Comment-Based Help](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
- [Repository Documentation Standards](../DOCUMENTATION_STANDARDS.md)
