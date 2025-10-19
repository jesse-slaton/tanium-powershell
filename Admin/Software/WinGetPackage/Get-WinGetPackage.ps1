<#
.SYNOPSIS
    Fetches WinGet package information and generates Tanium Deploy packages.

.DESCRIPTION
    This administrative script retrieves package information from WinGet repositories,
    optionally downloads installers, and generates complete Tanium Deploy packages including:
    - Install/Update/Remove wrapper scripts tailored to installer type
    - JSON metadata following Tanium best practices
    - Package documentation
    - Support for dependencies and multi-architecture packages

.PARAMETER PackageId
    WinGet package identifier (e.g., 'Microsoft.PowerShell', 'Google.Chrome')

.PARAMETER Version
    Specific version to fetch. If not specified, uses latest available version.

.PARAMETER Architecture
    Architecture filter (x64, x86, arm, arm64, neutral). Can specify multiple.
    If not specified, includes all architectures.

.PARAMETER Scope
    Installation scope: 'user', 'machine', or 'both'. Default is 'machine'.

.PARAMETER InstallerType
    Filter by specific installer type (msi, inno, nullsoft, burn, exe, msstore).
    If not specified, uses the installer type from the manifest.

.PARAMETER DownloadInstallers
    Download installer files. If not specified, only generates metadata and scripts.

.PARAMETER IncludeDependencies
    Create separate packages for dependencies in subdirectories.

.PARAMETER OutputPath
    Output directory for generated packages. Default is current directory.

.PARAMETER Source
    WinGet source (winget, msstore). Default is 'winget'.

.EXAMPLE
    .\Get-WinGetPackage.ps1 -PackageId "Microsoft.PowerShell" -Architecture x64 -DownloadInstallers

    Fetches PowerShell for x64, downloads installer, and generates Tanium Deploy package.

.EXAMPLE
    .\Get-WinGetPackage.ps1 -PackageId "Google.Chrome" -Version "120.0.6099.130" -Architecture x64,x86

    Fetches specific Chrome version for both x64 and x86, creates metadata without downloading.

.EXAMPLE
    .\Get-WinGetPackage.ps1 -PackageId "Microsoft.VisualStudioCode" -IncludeDependencies -DownloadInstallers

    Fetches VS Code and creates separate packages for all dependencies.

.NOTES
    Author: Jesse Slaton
    Requires: WinGet CLI, TaniumDeployPackage module
    Version: 1.0.0
    Related Issue: #7
    License: MIT

.LINK
    https://github.com/jesse-slaton/tanium-powershell/issues/7
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = "WinGet package ID to fetch")]
    [string]$PackageId,

    [Parameter(HelpMessage = "Package name to search for (alternative to PackageId)")]
    [string]$PackageName,

    [Parameter(HelpMessage = "Specific version (default: latest)")]
    [string]$Version,

    [Parameter(HelpMessage = "Architecture filter")]
    [ValidateSet('x64', 'x86', 'arm', 'arm64', 'neutral')]
    [string[]]$Architecture,

    [Parameter(HelpMessage = "Installation scope")]
    [ValidateSet('user', 'machine', 'both')]
    [string]$Scope,

    [Parameter(HelpMessage = "Filter by installer type")]
    [ValidateSet('msi', 'inno', 'nullsoft', 'burn', 'exe', 'msstore', 'msix', 'appx', 'portable', 'zip')]
    [string]$InstallerType,

    [Parameter(HelpMessage = "Download installer files")]
    [switch]$DownloadInstallers,

    [Parameter(HelpMessage = "Include dependencies as separate packages")]
    [switch]$IncludeDependencies,

    [Parameter(HelpMessage = "Output directory for package")]
    [string]$OutputPath = $PWD,

    [Parameter(HelpMessage = "WinGet source")]
    [ValidateSet('winget', 'msstore')]
    [string]$Source = 'winget'
)

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Validate parameters
if (-not $PackageId -and -not $PackageName) {
    Write-Error "Either -PackageId or -PackageName must be specified"
    exit 2
}

if ($PackageId -and $PackageName) {
    Write-Warning "Both -PackageId and -PackageName specified. Using -PackageId: $PackageId"
}

# Check for WinGet CLI
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "WinGet CLI not found. Please install Windows Package Manager."
    Write-Host "Install from: https://aka.ms/getwinget"
    exit 1
}

# Check for and import TaniumDeployPackage module
$modulePath = Join-Path $PSScriptRoot "..\..\..\Modules\TaniumDeployPackage"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Verbose "Imported TaniumDeployPackage module"

    # Dot-source private functions that we need
    $getInstallerVersionPath = Join-Path $modulePath "Private\Get-InstallerVersion.ps1"
    if (Test-Path $getInstallerVersionPath) {
        . $getInstallerVersionPath
        Write-Verbose "Loaded Get-InstallerVersion function"
    }
} else {
    Write-Error "TaniumDeployPackage module not found at: $modulePath"
    exit 1
}

# If searching by name, find the package ID
if (-not $PackageId -and $PackageName) {
    Write-Host "Searching for package: $PackageName" -ForegroundColor Cyan

    $searchArgs = @('search', $PackageName)
    if ($Source -ne 'winget') {
        $searchArgs += @('--source', $Source)
    }

    $searchOutput = & winget @searchArgs 2>&1

    # Parse search results
    $results = @()
    $foundSeparator = $false
    foreach ($line in $searchOutput) {
        # Look for separator line
        if ($line -match '^-+') {
            $foundSeparator = $true
            continue
        }

        # After separator, parse data lines
        if ($foundSeparator -and $line.Trim().Length -gt 0) {
            # Try to parse: Name [spaces] Id [spaces] Version
            # msstore IDs are like 9MSMLRH6LZF3 (start with DIGIT, all caps/numbers, 12 chars)
            # Regular IDs are like Microsoft.PowerShell (Publisher.Package with dots)
            if ($line -match '^(.+?)\s+(\d[A-Z0-9]{10,}|[A-Za-z0-9]+\.[A-Za-z0-9._-]+)\s+(.+)$') {
                $results += [PSCustomObject]@{
                    Name = $matches[1].Trim()
                    Id = $matches[2].Trim()
                    Version = $matches[3].Trim()
                }
            }
        }
    }

    if ($results.Count -eq 0) {
        Write-Error "No packages found matching: $PackageName"
        exit 3
    }
    elseif ($results.Count -eq 1) {
        $PackageId = $results[0].Id
        Write-Host "Found package: $($results[0].Name) [$PackageId]" -ForegroundColor Green
    }
    else {
        Write-Host "`nMultiple packages found:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $results.Count; $i++) {
            Write-Host "  [$i] $($results[$i].Name) - $($results[$i].Id)" -ForegroundColor Gray
        }

        $selection = Read-Host "`nSelect package number (0-$($results.Count - 1))"
        if ($selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -lt $results.Count) {
            $PackageId = $results[[int]$selection].Id
            Write-Host "Selected: $($results[[int]$selection].Name) [$PackageId]" -ForegroundColor Green
        } else {
            Write-Error "Invalid selection"
            exit 2
        }
    }
}

Write-Host "Fetching package information for: $PackageId" -ForegroundColor Cyan

# Track if package was completed successfully
$packageCompleted = $false
$packageDir = $null

try {
    # Fetch package information using winget show
    Write-Verbose "Running: winget show --id $PackageId --exact $(if ($Source -ne 'winget') { "--source $Source" })"

    $showArgs = @('show', '--id', $PackageId, '--exact')
    if ($Source -ne 'winget') {
        $showArgs += @('--source', $Source)
    }

    $showOutput = & winget @showArgs 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error "WinGet failed to find package: $PackageId"
        Write-Error ($showOutput -join "`n")
        exit 1
    }

    # Parse winget show output
    Write-Verbose "Parsing package information..."
    $packageInfo = @{
        PackageId = $PackageId
        Version = $null
        Publisher = $null
        PackageName = $null
        Description = $null
        Homepage = $null
        License = $null
        InstallerType = $null
        AvailableScopes = @()
        InstallerUrl = $null
        InstallerSha256 = $null
        Installers = @()
    }

    $currentSection = $null
    foreach ($line in $showOutput) {
        if ($line -match '^Found (.+) \[(.+)\]') {
            $packageInfo.PackageName = $matches[1]
            continue
        }

        if ($line -match '^Version:\s+(.+)$') {
            $detectedVersion = $matches[1].Trim()
            if (-not $Version) {
                $packageInfo.Version = $detectedVersion
            } else {
                $packageInfo.Version = $Version
            }
        }
        elseif ($line -match '^Publisher:\s+(.+)$') {
            $packageInfo.Publisher = $matches[1].Trim()
        }
        elseif ($line -match '^Description:\s+(.+)$') {
            $packageInfo.Description = $matches[1].Trim()
        }
        elseif ($line -match '^Homepage:\s+(.+)$') {
            $packageInfo.Homepage = $matches[1].Trim()
        }
        elseif ($line -match '^License:\s+(.+)$') {
            $packageInfo.License = $matches[1].Trim()
        }
        elseif ($line -match '^Installer Type:\s+(.+)$') {
            $packageInfo.InstallerType = $matches[1].Trim().ToLower()
        }
        elseif ($line -match '^Installer Scope:\s+(.+)$') {
            $detectedScope = $matches[1].Trim().ToLower()
            if ($detectedScope -notin $packageInfo.AvailableScopes) {
                $packageInfo.AvailableScopes += $detectedScope
            }
        }
        elseif ($line -match '^\s*Installer Url:\s+(.+)$') {
            $packageInfo.InstallerUrl = $matches[1].Trim()
        }
        elseif ($line -match '^\s*Installer SHA256:\s+(.+)$') {
            $packageInfo.InstallerSha256 = $matches[1].Trim()
        }
    }

    # Determine scope to use
    if (-not $Scope) {
        if ($packageInfo.AvailableScopes.Count -eq 0) {
            # No scope info detected, default to machine
            Write-Verbose "No scope information detected in manifest, defaulting to 'machine'"
            $Scope = 'machine'
        }
        elseif ($packageInfo.AvailableScopes.Count -eq 1) {
            # Only one scope available, use it
            $Scope = $packageInfo.AvailableScopes[0]
            Write-Host "Using detected scope: $Scope" -ForegroundColor Cyan
        }
        else {
            # Multiple scopes available, prompt user
            Write-Host "`nMultiple installation scopes detected: $($packageInfo.AvailableScopes -join ', ')" -ForegroundColor Yellow

            $scopeOptions = @()
            foreach ($availableScope in $packageInfo.AvailableScopes) {
                $scopeOptions += @{
                    label = $availableScope
                    description = if ($availableScope -eq 'machine') {
                        "Install for all users (requires admin rights)"
                    } else {
                        "Install for current user only"
                    }
                }
            }

            $response = AskUserQuestion -questions @(
                @{
                    question = "Which installation scope do you want to use?"
                    header = "Scope"
                    options = $scopeOptions
                    multiSelect = $false
                }
            )

            $Scope = $response.scope
            Write-Host "Selected scope: $Scope" -ForegroundColor Green
        }
    }

    if (-not $packageInfo.PackageName) {
        Write-Error "Failed to parse package information from winget show output"
        exit 1
    }

    Write-Host "Package: $($packageInfo.PackageName)" -ForegroundColor Green
    Write-Host "Version: $($packageInfo.Version)" -ForegroundColor Green
    Write-Host "Publisher: $($packageInfo.Publisher)" -ForegroundColor Green
    if ($packageInfo.InstallerType) {
        Write-Host "Installer Type: $($packageInfo.InstallerType)" -ForegroundColor Green
    }

    # Generate package directory: <productname>\<version>\<scope>
    # Note: For MSIX packages, version will be updated after parsing the downloaded bundle
    $sanitizedName = $packageInfo.PackageName -replace '[\\/:*?"<>|]', '_'
    $sanitizedVersion = if ($packageInfo.Version) { $packageInfo.Version -replace '[\\/:*?"<>|]', '_' } else { "Unknown" }
    $packageDir = Join-Path $OutputPath "$sanitizedName\$sanitizedVersion\$Scope"

    Write-Host "`nCreating package directory: $packageDir" -ForegroundColor Cyan
    New-Item -Path $packageDir -ItemType Directory -Force | Out-Null

    # Download installers if requested
    if ($DownloadInstallers) {
        Write-Host "`nDownloading package installers..." -ForegroundColor Cyan

        $downloadArgs = @('download', '--id', $PackageId)

        if ($Version) {
            $downloadArgs += @('--version', $Version)
        }

        if ($Source -ne 'winget') {
            $downloadArgs += @('--source', $Source)
        }

        if ($Architecture) {
            $downloadArgs += @('--architecture', ($Architecture -join ','))
        }

        # Add scope filter (winget download doesn't support 'both', so skip if both)
        if ($Scope -and $Scope -ne 'both') {
            $downloadArgs += @('--scope', $Scope)
            Write-Verbose "Filtering downloads to scope: $Scope"
        }

        # Use package directory as download location
        $downloadArgs += @('--download-directory', $packageDir)

        # For msstore, accept agreements automatically and skip license to avoid auth
        if ($Source -eq 'msstore') {
            $downloadArgs += @('--accept-package-agreements', '--accept-source-agreements', '--skip-license')
        } else {
            # For regular winget packages, accept agreements
            $downloadArgs += @('--accept-package-agreements', '--accept-source-agreements')
        }

        Write-Verbose "Running: winget $($downloadArgs -join ' ')"

        try {
            & winget @downloadArgs

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "WinGet download completed with exit code: $LASTEXITCODE"
            }
        }
        catch [System.Management.Automation.PipelineStoppedException] {
            Write-Host "`n`nDownload interrupted by user" -ForegroundColor Yellow
            throw
        }
    }

    # Determine installer type for defaults
    $installerTypeForDefaults = if ($InstallerType) {
        $InstallerType
    } elseif ($Source -eq 'msstore' -or $PackageId -match '^\d[A-Z0-9]{11}') {
        # Microsoft Store packages: source is msstore OR packageId format is digit + 11 alphanumeric (e.g., 9MSMLRH6LZF3)
        'msstore'
    } elseif ($packageInfo.InstallerType) {
        # Normalize WinGet installer types to our defaults
        switch ($packageInfo.InstallerType) {
            'wix' { 'burn' }
            'nsis' { 'nullsoft' }
            { $_ -in @('msix', 'appx') } { 'msstore' }
            default { $packageInfo.InstallerType }
        }
    } else {
        'exe'  # fallback
    }

    Write-Host "`nLoading installer defaults for: $installerTypeForDefaults" -ForegroundColor Cyan
    $defaults = Get-InstallerDefaults -InstallerType $installerTypeForDefaults -ProductName $sanitizedName

    if (-not $defaults) {
        Write-Warning "No installer defaults loaded, using generic exe defaults"
        $defaults = Get-InstallerDefaults -InstallerType 'exe'
    }

    # Find downloaded installer file if available
    $installerFile = $null
    $isMsixPackage = $false
    $msixMainPackage = $null
    $msixDependencies = @()

    if ($DownloadInstallers -and (Test-Path $packageDir)) {
        # Check if this is an MSIX/AppX package and parse dependencies FIRST
        if ($installerTypeForDefaults -eq 'msstore') {
            $isMsixPackage = $true
            Write-Verbose "Detected MSIX/AppX package type, parsing dependencies..."

            # Find all MSIX/AppX files in root directory (main packages)
            $mainMsixFiles = @()
            $mainMsixFiles += Get-ChildItem -Path "$packageDir\*.msix" -File -ErrorAction SilentlyContinue
            $mainMsixFiles += Get-ChildItem -Path "$packageDir\*.appx" -File -ErrorAction SilentlyContinue
            $mainMsixFiles += Get-ChildItem -Path "$packageDir\*.msixbundle" -File -ErrorAction SilentlyContinue
            $mainMsixFiles += Get-ChildItem -Path "$packageDir\*.appxbundle" -File -ErrorAction SilentlyContinue
            Write-Verbose "Found $($mainMsixFiles.Count) MSIX files in root directory"

            if ($mainMsixFiles) {
                # Main package is typically a bundle - find the NEWEST version
                $bundles = $mainMsixFiles | Where-Object { $_.Extension -in @('.msixbundle', '.appxbundle') }

                if ($bundles) {
                    # Use newest/largest bundle
                    $msixMainPackage = ($bundles | Sort-Object Length -Descending | Select-Object -First 1).Name
                    Write-Verbose "Main package bundle: $msixMainPackage"

                    # Extract version directly from the MSIX bundle file
                    $bundlePath = Join-Path $packageDir $msixMainPackage
                    $extractedVersion = Get-InstallerVersion -InstallerPath $bundlePath

                    if ($extractedVersion) {
                        $packageVersion = $extractedVersion

                        # Update packageInfo with extracted version
                        $oldVersion = $packageInfo.Version
                        $packageInfo.Version = $packageVersion

                        Write-Host "Detected MSIX package version from bundle: $packageVersion" -ForegroundColor Cyan

                        # If version changed, we need to rename the package directory
                        if ($oldVersion -ne $packageVersion) {
                            $newSanitizedVersion = $packageVersion -replace '[\\/:*?"<>|]', '_'
                            $newPackageDir = Join-Path $OutputPath "$sanitizedName\$newSanitizedVersion\$Scope"

                            if ($packageDir -ne $newPackageDir) {
                                Write-Host "Updating package directory to use detected version..." -ForegroundColor Cyan
                                Write-Verbose "Moving from $packageDir to $newPackageDir"

                                # Create parent directory if needed
                                $parentDir = Split-Path $newPackageDir -Parent
                                if (-not (Test-Path $parentDir)) {
                                    New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
                                }

                                # Move entire directory
                                Move-Item -Path $packageDir -Destination $newPackageDir -Force

                                # Update packageDir variable
                                $packageDir = $newPackageDir
                                $sanitizedVersion = $newSanitizedVersion
                            }
                        }
                    } else {
                        Write-Warning "Could not extract version from MSIX bundle"
                    }
                } else {
                    # No bundles, use largest file as main package
                    $sortedBySize = $mainMsixFiles | Sort-Object Length -Descending
                    $msixMainPackage = $sortedBySize[0].Name
                    Write-Verbose "Main package (largest file): $msixMainPackage"
                }
            }

            # Find dependencies in Dependencies\ subdirectory (winget downloads them there)
            # Filter to only newest version of each dependency for the specified architecture
            $depsDir = Join-Path $packageDir "Dependencies"
            if (Test-Path $depsDir) {
                $depFiles = @()
                $depFiles += Get-ChildItem -Path "$depsDir\*.msix" -File -ErrorAction SilentlyContinue
                $depFiles += Get-ChildItem -Path "$depsDir\*.appx" -File -ErrorAction SilentlyContinue
                $depFiles += Get-ChildItem -Path "$depsDir\*.msixbundle" -File -ErrorAction SilentlyContinue
                $depFiles += Get-ChildItem -Path "$depsDir\*.appxbundle" -File -ErrorAction SilentlyContinue

                if ($depFiles) {
                    # Group dependencies by base name (without version/architecture)
                    # Example: Microsoft.VCLibs.140.00_14.0.33519.0_Universal_X64.appx
                    # Base: Microsoft.VCLibs.140.00, Version: 14.0.33519.0, Arch: X64

                    $depsByBaseName = @{}

                    foreach ($depFile in $depFiles) {
                        # Parse: BaseName_Version_Type_Architecture.extension
                        if ($depFile.Name -match '^(.+?)_(\d+\.\d+\.\d+\.\d+)_(.+?)_(X64|X86|Arm64|Arm|Universal)\.') {
                            $baseName = $matches[1]
                            $depVersion = $matches[2]
                            $depArch = $matches[4]

                            # Filter by architecture if specified
                            $archMatch = $false
                            if (-not $Architecture) {
                                # No architecture specified, prefer Universal or X64
                                $archMatch = $depArch -in @('Universal', 'X64')
                            } elseif ($Architecture -contains $depArch) {
                                $archMatch = $true
                            } elseif ($depArch -eq 'Universal') {
                                # Universal packages work for any architecture
                                $archMatch = $true
                            }

                            if ($archMatch) {
                                $key = "$baseName-$depArch"

                                if (-not $depsByBaseName.ContainsKey($key)) {
                                    $depsByBaseName[$key] = @{
                                        File = $depFile
                                        Version = [Version]$depVersion
                                    }
                                } else {
                                    # Keep the newest version
                                    if ([Version]$depVersion -gt $depsByBaseName[$key].Version) {
                                        $depsByBaseName[$key] = @{
                                            File = $depFile
                                            Version = [Version]$depVersion
                                        }
                                    }
                                }
                            }
                        }
                    }

                    # Extract newest dependencies
                    $msixDependencies = $depsByBaseName.Values | ForEach-Object { "Dependencies\$($_.File.Name)" }

                    if ($msixDependencies.Count -gt 0) {
                        Write-Host "Found $($msixDependencies.Count) dependencies (newest versions, filtered by architecture):" -ForegroundColor Cyan
                        foreach ($dep in $msixDependencies | Sort-Object) {
                            Write-Host "  - $dep" -ForegroundColor Gray
                        }
                    }
                }
            }

            # Set installerFile to main MSIX package
            if ($msixMainPackage) {
                $installerFile = $msixMainPackage
                Write-Verbose "Set installerFile to main MSIX package: $installerFile"
            } else {
                Write-Warning "MSIX package detected but no main package file found"
            }
        } else {
            # Non-MSIX package: Look for common installer extensions
            $installerExtensions = @('*.msi', '*.exe')
            foreach ($ext in $installerExtensions) {
                $foundFiles = Get-ChildItem -Path $packageDir -File -Filter $ext -ErrorAction SilentlyContinue
                if ($foundFiles) {
                    $installerFile = $foundFiles[0].Name
                    Write-Verbose "Found installer file: $installerFile"
                    break
                }
            }
        }
    }

    # Warn if no installer was downloaded
    if (-not $installerFile) {
        Write-Warning "No installer file found. Package scripts will fail unless Tanium Server downloads the installer."
        Write-Warning "Consider re-running with -DownloadInstallers flag for air-gapped deployments."
    }

    # Generate install script
    Write-Host "Generating install script..." -ForegroundColor Cyan
    $installScriptName = "Install-$sanitizedName.ps1"
    $removeScriptName = "Remove-$sanitizedName.ps1"

    if ($isMsixPackage) {
        # Use MSIX-specific script generation
        Write-Verbose "Using MSIX/AppX script generation"

        # Determine script generation mode:
        # - AllInOne = $true: Dependencies included in main install script (default behavior)
        # - AllInOne = $false: Dependencies NOT included, will be separate Tanium packages
        if ($IncludeDependencies) {
            # Separate dependencies mode - explicitly set AllInOne to false
            Write-Verbose "Separate dependencies mode (-IncludeDependencies): Main package will NOT install dependencies"
            $allInOne = $false
            $dependenciesToInclude = @()  # Empty array - don't include dependencies in script
        } else {
            # All-in-one mode (default) - explicitly set AllInOne to true
            Write-Verbose "All-in-one mode (default): Main package will install all dependencies"
            $allInOne = $true
            $dependenciesToInclude = $msixDependencies  # Include all dependencies in script
        }

        $installScript = New-MsixInstallScript `
            -PackageName $packageInfo.PackageName `
            -PackageId $PackageId `
            -MainPackageFile $msixMainPackage `
            -DependencyFiles $dependenciesToInclude `
            -Scope $Scope `
            -AllInOne $allInOne

        $installScriptPath = Join-Path $packageDir $installScriptName
        $installScript | Out-File -FilePath $installScriptPath -Encoding UTF8
        Write-Verbose "MSIX install script created: $installScriptPath"

        # Generate MSIX remove script
        Write-Host "Generating MSIX uninstall script..." -ForegroundColor Cyan

        $removeScript = New-MsixRemoveScript `
            -PackageName $packageInfo.PackageName `
            -PackageId $PackageId `
            -Scope $Scope `
            -AllInOne $allInOne

        $removeScriptPath = Join-Path $packageDir $removeScriptName
        $removeScript | Out-File -FilePath $removeScriptPath -Encoding UTF8
        Write-Verbose "MSIX uninstall script created: $removeScriptPath"
    } else {
        # Use generic script generation for traditional installers
        Write-Verbose "Using generic installer script generation"

        # Use defaults for install command and switches
        $installCommand = $defaults.install.command
        $installSwitches = $defaults.install.switches

        $installScript = New-InstallScript `
            -ProductName $packageInfo.PackageName `
            -ProductId $PackageId `
            -ProductVersion $packageInfo.Version `
            -InstallerFile $installerFile `
            -InstallerType $installerTypeForDefaults `
            -InstallCommand $installCommand `
            -InstallSwitches $installSwitches `
            -SuccessCodes $defaults.install.successCodes `
            -Timeout $defaults.install.timeout `
            -Scope $Scope `
            -AdditionalNotes "Package ID: $PackageId`nInstaller Type: $installerTypeForDefaults`nGenerated by Get-WinGetPackage.ps1"

        $installScriptPath = Join-Path $packageDir $installScriptName
        $installScript | Out-File -FilePath $installScriptPath -Encoding UTF8
        Write-Verbose "Install script created: $installScriptPath"

        # Generate uninstall script
        Write-Host "Generating uninstall script..." -ForegroundColor Cyan

        $removeScript = New-RemoveScript `
            -ProductName $packageInfo.PackageName `
            -ProductId $PackageId `
            -ProductVersion $packageInfo.Version `
            -UninstallMethod 'winget' `
            -SuccessCodes $defaults.uninstall.successCodes `
            -AdditionalNotes "Package ID: $PackageId`nInstaller Type: $installerTypeForDefaults`nGenerated by Get-WinGetPackage.ps1"

        $removeScriptPath = Join-Path $packageDir $removeScriptName
        $removeScript | Out-File -FilePath $removeScriptPath -Encoding UTF8
        Write-Verbose "Uninstall script created: $removeScriptPath"
    }

    # Generate Tanium Deploy metadata
    Write-Host "Generating Tanium Deploy metadata..." -ForegroundColor Cyan
    $metadataFile = "tanium-deploy-metadata.json"

    # Determine architecture for metadata
    $metadataArchitecture = if ($Architecture -and $Architecture.Count -eq 1) {
        $Architecture[0]
    } elseif ($installerFile -match '(x64|x86|arm64|arm)') {
        $matches[1]
    } else {
        'x64'  # default
    }

    # Calculate SHA256 if installer was downloaded
    $installerSha256 = $null
    $installerFilePath = $null
    if ($installerFile) {
        $installerFilePath = Join-Path $packageDir $installerFile
        if (Test-Path $installerFilePath) {
            try {
                Write-Verbose "Calculating SHA-256 hash for $installerFile..."
                $hash = Get-FileHash -Path $installerFilePath -Algorithm SHA256 -ErrorAction Stop
                $installerSha256 = $hash.Hash
                Write-Verbose "SHA-256: $installerSha256"
            }
            catch {
                Write-Warning "Failed to calculate SHA-256 hash: $_"
                # Fall back to manifest SHA256 if available
                if ($packageInfo.InstallerSha256) {
                    $installerSha256 = $packageInfo.InstallerSha256
                    Write-Verbose "Using SHA-256 from manifest: $installerSha256"
                }
            }
        }
    } else {
        # Use SHA256 from manifest if available
        $installerSha256 = $packageInfo.InstallerSha256
    }

    # Estimate disk space requirements
    $diskSpaceMB = 500  # default
    if ($installerFilePath -and (Test-Path $installerFilePath)) {
        $fileSizeMB = (Get-Item $installerFilePath).Length / 1MB
        $multiplier = if ($defaults.requirements.diskSpaceMultiplier) {
            $defaults.requirements.diskSpaceMultiplier
        } else { 3 }
        $diskSpaceMB = [math]::Max($fileSizeMB * $multiplier, 100)
    }

    $memoryMB = if ($defaults.requirements.memoryMB) {
        $defaults.requirements.memoryMB
    } else { 512 }

    # Determine detection method based on installer type
    if ($isMsixPackage) {
        # For MSIX packages, use AppX Package detection
        # Format: AppX Package "{PackageFamilyName}" >= "{Version}"
        # Since we may not have PackageFamilyName, use wildcard with PackageId
        $installVerification = "AppX Package `"*$PackageId*`" >= `"$($packageInfo.Version)`""
        $updateDetection = "AppX Package `"*$PackageId*`" >= `"$($packageInfo.Version)`""
    } else {
        # For traditional installers, use registry detection
        $installVerification = "Registry Value `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$PackageId\DisplayVersion`" >= `"$($packageInfo.Version)`""
        $updateDetection = "Registry Value `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$PackageId\DisplayVersion`" >= `"$($packageInfo.Version)`""
    }

    # Build metadata
    $metadata = @{
        vendor = if ($packageInfo.Publisher) { $packageInfo.Publisher } else { "Unknown" }
        productName = $packageInfo.PackageName
        productVersion = $packageInfo.Version
        architecture = $metadataArchitecture
        diskSpaceMB = [int]$diskSpaceMB
        memoryMB = $memoryMB
        downloadUrl = $packageInfo.InstallerUrl
        sha256 = $installerSha256
        additionalDetails = if ($packageInfo.Homepage) { $packageInfo.Homepage } else { "https://github.com/microsoft/winget-pkgs" }
        installOperation = @{
            command = "powershell.exe -ExecutionPolicy Bypass -File `".\$installScriptName`""
            timeout = $defaults.install.timeout
            successCodes = $defaults.install.successCodes
        }
        removeOperation = @{
            command = "powershell.exe -ExecutionPolicy Bypass -File `".\$removeScriptName`""
            timeout = $defaults.uninstall.timeout
            successCodes = $defaults.uninstall.successCodes
        }
        osRequirements = @{
            editionId = $null
            productName = if ($defaults.requirements.osMinimum) { $defaults.requirements.osMinimum } else { "Windows 10" }
            build = $null
        }
        selfService = @{
            name = "$($packageInfo.PackageName) $metadataArchitecture"
            icon = $null  # TODO: Icon support
        }
        installRequirements = 'Registry Path exists "HKLM\Path\Does\Not\Exist"'
        installVerification = $installVerification
        updateDetection = $updateDetection
    }

    $metadataPath = Join-Path $packageDir $metadataFile
    $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding UTF8
    Write-Host "Created: $metadataFile" -ForegroundColor Green

    # Handle -IncludeDependencies for MSIX packages
    if ($IncludeDependencies -and $isMsixPackage -and $msixDependencies.Count -gt 0) {
        Write-Host "`nCreating separate Tanium Deploy packages for dependencies..." -ForegroundColor Cyan

        $dependenciesBaseDir = Join-Path $packageDir "dependencies"
        New-Item -Path $dependenciesBaseDir -ItemType Directory -Force | Out-Null

        foreach ($depFile in $msixDependencies) {
            Write-Host "  Creating Tanium package for dependency: $depFile" -ForegroundColor Gray

            # Extract dependency name and version from filename
            # Format: DependencyName_Version_Architecture_hash.msix
            $depFileBase = [System.IO.Path]::GetFileNameWithoutExtension($depFile)
            $depParts = $depFileBase -split '_'

            # Determine dependency product name and version
            $depProductName = $depParts[0]
            $depVersion = if ($depParts.Count -gt 1 -and $depParts[1] -match '^\d+\.\d+') {
                $depParts[1]
            } else {
                $packageInfo.Version  # Fallback to main package version
            }

            # Sanitize names
            $depProductName = $depProductName -replace '[\\/:*?"<>|]', '_'
            $depVersion = $depVersion -replace '[\\/:*?"<>|]', '_'

            # Create full Tanium Deploy package structure: dependencies/ProductName/Version/Scope/
            $depPackageDir = Join-Path $dependenciesBaseDir "$depProductName\$depVersion\$Scope"
            New-Item -Path $depPackageDir -ItemType Directory -Force | Out-Null

            # Copy dependency file to its package directory
            $depSourcePath = Join-Path $packageDir $depFile
            if (Test-Path $depSourcePath) {
                Copy-Item -Path $depSourcePath -Destination $depPackageDir -Force
                Write-Verbose "Copied $depFile to $depPackageDir"
            }

            # Calculate dependency file SHA256
            $depSha256 = $null
            $depFilePath = Join-Path $depPackageDir $depFile
            if (Test-Path $depFilePath) {
                try {
                    $hash = Get-FileHash -Path $depFilePath -Algorithm SHA256 -ErrorAction Stop
                    $depSha256 = $hash.Hash
                    Write-Verbose "SHA-256: $depSha256"
                }
                catch {
                    Write-Warning "Failed to calculate SHA-256 for dependency: $depFile"
                }
            }

            # Generate install script for dependency
            $depInstallScriptName = "Install-$depProductName.ps1"
            $depInstallScript = New-MsixInstallScript `
                -PackageName $depProductName `
                -PackageId $depProductName `
                -MainPackageFile $depFile `
                -DependencyFiles @() `
                -Scope $Scope `
                -AllInOne $false

            $depInstallScriptPath = Join-Path $depPackageDir $depInstallScriptName
            $depInstallScript | Out-File -FilePath $depInstallScriptPath -Encoding UTF8
            Write-Verbose "Created install script: $depInstallScriptPath"

            # Generate remove script for dependency
            $depRemoveScriptName = "Remove-$depProductName.ps1"
            $depRemoveScript = New-MsixRemoveScript `
                -PackageName $depProductName `
                -PackageId $depProductName `
                -Scope $Scope `
                -AllInOne $false

            $depRemoveScriptPath = Join-Path $depPackageDir $depRemoveScriptName
            $depRemoveScript | Out-File -FilePath $depRemoveScriptPath -Encoding UTF8
            Write-Verbose "Created remove script: $depRemoveScriptPath"

            # Calculate dependency disk space requirements
            $depDiskSpaceMB = 100  # default
            if (Test-Path $depFilePath) {
                $depFileSizeMB = (Get-Item $depFilePath).Length / 1MB
                $multiplier = if ($defaults.requirements.diskSpaceMultiplier) {
                    $defaults.requirements.diskSpaceMultiplier
                } else { 2 }
                $depDiskSpaceMB = [math]::Max($depFileSizeMB * $multiplier, 50)
            }

            # Generate Tanium Deploy metadata for dependency
            $depMetadata = @{
                vendor = if ($packageInfo.Publisher) { $packageInfo.Publisher } else { "Unknown" }
                productName = $depProductName
                productVersion = $depVersion
                architecture = $metadataArchitecture
                diskSpaceMB = [int]$depDiskSpaceMB
                memoryMB = 256
                downloadUrl = $null  # Dependencies typically don't have individual download URLs
                sha256 = $depSha256
                additionalDetails = "Dependency for $($packageInfo.PackageName)"
                installOperation = @{
                    command = "powershell.exe -ExecutionPolicy Bypass -File `".\$depInstallScriptName`""
                    timeout = 900
                    successCodes = @(0)
                }
                removeOperation = @{
                    command = "powershell.exe -ExecutionPolicy Bypass -File `".\$depRemoveScriptName`""
                    timeout = 600
                    successCodes = @(0)
                }
                osRequirements = @{
                    editionId = $null
                    productName = "Windows 10"
                    build = $null
                }
                selfService = @{
                    name = "$depProductName (Dependency)"
                    icon = $null
                }
                installRequirements = 'Registry Path exists "HKLM\Path\Does\Not\Exist"'
                installVerification = "AppX Package `"*$depProductName*`" exists"
                updateDetection = "AppX Package `"*$depProductName*`" exists"
            }

            $depMetadataPath = Join-Path $depPackageDir "tanium-deploy-metadata.json"
            $depMetadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $depMetadataPath -Encoding UTF8
            Write-Verbose "Created metadata: $depMetadataPath"

            Write-Host "    Created Tanium package: dependencies/$depProductName/$depVersion/$Scope/" -ForegroundColor Green
        }

        Write-Host "Created $($msixDependencies.Count) dependency packages in: $dependenciesBaseDir" -ForegroundColor Green
        Write-Host "Note: CI/CD pipeline should import these dependencies as separate Tanium packages" -ForegroundColor Yellow
    }

    # TODO: Generate README
    # TODO: Handle icon download

    Write-Host "`nPackage structure created successfully" -ForegroundColor Green
    Write-Host "Location: $packageDir" -ForegroundColor Gray
    Write-Host "  - $installScriptName" -ForegroundColor Gray
    Write-Host "  - $removeScriptName" -ForegroundColor Gray
    Write-Host "  - $metadataFile" -ForegroundColor Gray

    if ($installerFile) {
        Write-Host "  - $installerFile" -ForegroundColor Gray
    }

    if ($packageInfo.InstallerUrl) {
        Write-Host "`nDownload URL: $($packageInfo.InstallerUrl)" -ForegroundColor Cyan
    }

    $packageCompleted = $true
}
catch {
    Write-Error "Failed to create package: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}
finally {
    # Clean up incomplete package directory
    if (-not $packageCompleted -and $packageDir -and (Test-Path $packageDir)) {
        Write-Host "`nCleaning up incomplete package directory..." -ForegroundColor Yellow
        Remove-Item -Path $packageDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Package directory removed" -ForegroundColor Green
    }
}

Write-Verbose "Get-WinGetPackage completed"
exit 0
