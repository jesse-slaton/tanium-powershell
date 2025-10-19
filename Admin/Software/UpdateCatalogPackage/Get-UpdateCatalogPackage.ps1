<#
.SYNOPSIS
    Fetches Windows updates from Microsoft Update Catalog and generates Tanium Deploy packages.

.DESCRIPTION
    This administrative script searches for and downloads Windows updates from the Microsoft Update Catalog,
    then generates complete Tanium Deploy packages including:
    - Install wrapper scripts
    - Remove wrapper scripts
    - JSON metadata following Tanium best practices
    - Package documentation

    The script uses the MSCatalogLTS PowerShell module for catalog access and URL resolution.

.PARAMETER KB
    KB number to search for (e.g., 'KB5066835' or '5066835')

.PARAMETER OperatingSystem
    Operating system filter (e.g., 'Windows 10', 'Windows 11', 'Windows Server 2022')

.PARAMETER Architecture
    Architecture filter (x64, x86, ARM64). Default is x64.

.PARAMETER OSRelease
    Optional OS release/version filter (e.g., '24H2', '23H2', '22H2')

.PARAMETER OutputPath
    Output directory for generated package. Default is current directory.

.PARAMETER DownloadAll
    Download all files when multiple download links are found. Default is to download only the first file.

.PARAMETER UseBits
    Use BITS (Background Intelligent Transfer Service) for downloading. Provides automatic resume capability for interrupted downloads and better progress tracking. Default is true.

.EXAMPLE
    .\Get-UpdateCatalogPackage.ps1 -KB KB5066835 -OperatingSystem "Windows 11" -Architecture x64

    Fetches KB5066835 for Windows 11 x64 and generates a Tanium Deploy package.

.EXAMPLE
    .\Get-UpdateCatalogPackage.ps1 -KB 5066835 -OperatingSystem "Windows 11" -OSRelease "24H2" -Architecture x64

    Fetches KB5066835 for Windows 11 24H2 x64.

.NOTES
    Author: Jesse Slaton
    Requires: MSCatalogLTS module (Install-Module MSCatalogLTS)
    Version: 1.0.0
    Related Issue: #8
    License: MIT

    ATTRIBUTION:
    This script uses the Get-UpdateLinks function from the MSCatalogLTS module
    (https://github.com/Marco-online/MSCatalogLTS) by Marco-online,
    licensed under the MIT License.

.LINK
    https://github.com/jesse-slaton/tanium-powershell/issues/8

.LINK
    https://github.com/Marco-online/MSCatalogLTS
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "KB number to fetch")]
    [ValidatePattern('^(KB)?\d+$')]
    [string]$KB,

    [Parameter(HelpMessage = "Operating system filter")]
    [string]$OperatingSystem,

    [Parameter(HelpMessage = "Architecture filter")]
    [ValidateSet('x64', 'x86', 'ARM64')]
    [string]$Architecture = 'x64',

    [Parameter(HelpMessage = "OS release/version filter")]
    [string]$OSRelease,

    [Parameter(HelpMessage = "Output directory for package")]
    [string]$OutputPath = $PWD,

    [Parameter(HelpMessage = "Download all files when multiple links are found")]
    [switch]$DownloadAll,

    [Parameter(HelpMessage = "Use BITS for downloading with resume capability")]
    [bool]$UseBits = $true
)

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

# Check for required module and offer to install
if (-not (Get-Module -ListAvailable -Name MSCatalogLTS)) {
    Write-Host "MSCatalogLTS module is not installed." -ForegroundColor Yellow
    Write-Host "This module is required to search and download updates from Microsoft Update Catalog."
    Write-Host ""

    $install = Read-Host "Would you like to install MSCatalogLTS now? (Y/N)"

    if ($install -eq 'Y' -or $install -eq 'y') {
        Write-Host "`nInstalling MSCatalogLTS module..." -ForegroundColor Cyan
        try {
            Install-Module -Name MSCatalogLTS -Scope CurrentUser -Force -AllowClobber
            Write-Host "MSCatalogLTS module installed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install MSCatalogLTS module: $_"
            Write-Host "`nPlease install manually with: Install-Module MSCatalogLTS -Scope CurrentUser"
            exit 1
        }
    }
    else {
        Write-Host "`nCannot proceed without MSCatalogLTS module." -ForegroundColor Red
        Write-Host "Install manually with: Install-Module MSCatalogLTS -Scope CurrentUser"
        exit 1
    }
}

Import-Module MSCatalogLTS

# Import TaniumDeployPackage module for reusable package generation functions
$TaniumModulePath = Join-Path $PSScriptRoot "..\..\..\Modules\TaniumDeployPackage"
if (Test-Path $TaniumModulePath) {
    Import-Module $TaniumModulePath -Force
    Write-Verbose "Imported TaniumDeployPackage module"
} else {
    Write-Error "Could not find TaniumDeployPackage module at: $TaniumModulePath"
    Write-Host "Please ensure the module is available at the expected path."
    exit 1
}

# Import the private Get-UpdateLinks function from MSCatalogLTS module
# This allows us to use BITS for downloads with progress tracking while
# leveraging the module's tested URL resolution logic.
#
# MSCatalogLTS by Marco-online (https://github.com/Marco-online/MSCatalogLTS)
# Licensed under the MIT License
# Copyright (c) 2025 Marco-online
$MSCatalogModule = Get-Module MSCatalogLTS
if ($MSCatalogModule) {
    $GetUpdateLinksPath = Join-Path $MSCatalogModule.ModuleBase "Private\Get-UpdateLinks.ps1"
    if (Test-Path $GetUpdateLinksPath) {
        . $GetUpdateLinksPath
        Write-Verbose "Imported Get-UpdateLinks from MSCatalogLTS module"
    } else {
        Write-Error "Could not find Get-UpdateLinks.ps1 in MSCatalogLTS module at: $GetUpdateLinksPath"
        exit 1
    }
} else {
    Write-Error "MSCatalogLTS module not loaded"
    exit 1
}


# Normalize KB number
if ($KB -notmatch '^KB') {
    $KB = "KB$KB"
}
$KBNumber = $KB -replace 'KB', ''

Write-Host "Searching for $KB..." -ForegroundColor Cyan

try {
    # Build search query
    $searchTerms = @($KB)
    if ($OperatingSystem) {
        $searchTerms += $OperatingSystem
    }
    if ($OSRelease) {
        $searchTerms += $OSRelease
    }
    if ($Architecture) {
        $searchTerms += $Architecture
    }

    $searchQuery = $searchTerms -join ' '

    # Search for updates
    Write-Verbose "Search query: $searchQuery"
    $updates = Get-MSCatalogUpdate -Search $searchQuery

    if (-not $updates) {
        Write-Error "No updates found for $KB"
        return
    }

    # Display found updates and select
    if ($updates.Count -eq 1) {
        $selectedUpdate = $updates[0]
        Write-Host "`nFound 1 update:" -ForegroundColor Green
        Write-Host "  $($selectedUpdate.Title)"
        Write-Host "  Products: $($selectedUpdate.Products)"
        Write-Host "  Classification: $($selectedUpdate.Classification)"
        Write-Host "  Size: $($selectedUpdate.Size)"
        Write-Host "  Date: $($selectedUpdate.LastUpdated)"
    }
    elseif ($updates.Count -gt 1) {
        Write-Host "`nFound $($updates.Count) updates:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $updates.Count; $i++) {
            $update = $updates[$i]
            Write-Host "`n[$i] $($update.Title)"
            Write-Host "    Products: $($update.Products)"
            Write-Host "    Size: $($update.Size)"
        }
        Write-Host "`nMultiple updates found. Refine your search with -OSRelease or provide more specific filters." -ForegroundColor Yellow
        exit 1
    }
    else {
        Write-Error "No updates found for $KB"
        exit 1
    }

    # Build package directory name with OS, arch, and release info
    $dirNameParts = @("KB$KBNumber")
    if ($OperatingSystem) {
        $osSafe = $OperatingSystem -replace '\s+', '-'
        $dirNameParts += $osSafe
    }
    if ($OSRelease) {
        $dirNameParts += $OSRelease
    }
    if ($Architecture) {
        $dirNameParts += $Architecture
    }
    $packageDirName = $dirNameParts -join '-'
    $packageDir = Join-Path $OutputPath $packageDirName

    if (Test-Path $packageDir) {
        Write-Warning "Package directory already exists: $packageDir"
        Write-Host "Cleaning existing directory..."
        Remove-Item -Path $packageDir -Recurse -Force
    }

    New-Item -Path $packageDir -ItemType Directory -Force | Out-Null
    Write-Host "`nPackage directory: $packageDir" -ForegroundColor Cyan

    # Track if package was completed successfully
    $packageCompleted = $false

    # Get download links from Microsoft Update Catalog using the module's private function
    Write-Host "`nResolving download URLs..." -ForegroundColor Cyan
    $downloadLinks = Get-UpdateLinks -Guid $selectedUpdate.Guid

    if (-not $downloadLinks) {
        Write-Error "Failed to get download links for update"
        exit 1
    }

    Write-Host "Found $($downloadLinks.Count) download link(s)" -ForegroundColor Green

    # Determine which URLs to download
    $linksToDownload = if ($DownloadAll) {
        $downloadLinks
    } else {
        @($downloadLinks[0])
    }

    Write-Host "Downloading $($linksToDownload.Count) file(s)..." -ForegroundColor Cyan

    # Download each file
    $downloadedFiles = @()
    $downloadUrls = @()
    foreach ($link in $linksToDownload) {
        # Extract filename from URL
        $url = $link.URL
        $uri = [System.Uri]$url

        # Try to get filename from URL path
        $fileName = [System.IO.Path]::GetFileName($uri.LocalPath)

        # If no filename or invalid, try to generate from update info
        if ([string]::IsNullOrWhiteSpace($fileName) -or $fileName -notmatch '\.[a-z]{2,4}$') {
            # Generate filename from KB and extension
            $extension = '.msu'  # Default for Windows updates
            if ($url -match '\.(cab|exe|msu|msi)(\?|$)') {
                $extension = ".$($Matches[1])"
            }
            $fileName = "KB$KBNumber$extension"
        }

        $destinationFile = Join-Path $packageDir $fileName

        Write-Host "`nDownloading: $fileName" -ForegroundColor Cyan

        # Download using our custom function with BITS
        $success = Invoke-FileDownload -Url $url -Destination $destinationFile -UseBits $UseBits

        if ($success) {
            $downloadedFiles += Get-Item $destinationFile
            $downloadUrls += $url
        } else {
            Write-Error "Failed to download $fileName"
            exit 1
        }
    }

    # Select the first downloaded file for package generation
    $downloadedFile = $downloadedFiles[0]
    $primaryDownloadUrl = $downloadUrls[0]

    if (-not $downloadedFile) {
        Write-Error "Download failed - no file found in $packageDir"
        exit 1
    }

    # Generate install script
    Write-Host "`nGenerating install script..." -ForegroundColor Cyan
    $installScriptName = "Install-KB$KBNumber.ps1"
    $installScript = New-InstallScript -UpdateFile $downloadedFile -KB $KB `
        -Title $selectedUpdate.Title -Classification $selectedUpdate.Classification `
        -Products $selectedUpdate.Products

    $installScriptPath = Join-Path $packageDir $installScriptName
    $installScript | Out-File -FilePath $installScriptPath -Encoding UTF8
    Write-Host "Created: $installScriptName" -ForegroundColor Green

    # Generate remove script
    Write-Host "Generating remove script..." -ForegroundColor Cyan
    $removeScriptName = "Remove-KB$KBNumber.ps1"
    $removeScript = New-RemoveScript -KB $KB -KBNumber $KBNumber `
        -Title $selectedUpdate.Title -Classification $selectedUpdate.Classification `
        -Products $selectedUpdate.Products

    $removeScriptPath = Join-Path $packageDir $removeScriptName
    $removeScript | Out-File -FilePath $removeScriptPath -Encoding UTF8
    Write-Host "Created: $removeScriptName" -ForegroundColor Green

    # Generate metadata
    Write-Host "Generating Tanium Deploy metadata..." -ForegroundColor Cyan
    $metadataFile = "tanium-deploy-metadata.json"
    $metadata = New-TaniumDeployMetadata -Update $selectedUpdate -KB $KB `
        -InstallScript $installScriptName -RemoveScript $removeScriptName `
        -UpdateFileName $downloadedFile.Name -UpdateFilePath $downloadedFile.FullName `
        -DownloadUrl $primaryDownloadUrl

    $metadataPath = Join-Path $packageDir $metadataFile
    $metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataPath -Encoding UTF8
    Write-Host "Created: $metadataFile" -ForegroundColor Green

    # Generate README
    Write-Host "Generating README..." -ForegroundColor Cyan
    $readmeContent = New-PackageReadme -Update $selectedUpdate -KB $KB `
        -UpdateFileName $downloadedFile.Name -InstallScript $installScriptName `
        -RemoveScript $removeScriptName -MetadataFile $metadataFile

    $readmePath = Join-Path $packageDir "README.md"
    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
    Write-Host "Created: README.md" -ForegroundColor Green

    # Display summary
    Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
    Write-Host "Package created successfully!" -ForegroundColor Green
    Write-Host "Location: $packageDir" -ForegroundColor Cyan
    Write-Host "$('=' * 60)" -ForegroundColor Cyan

    Write-Host "`nPackage contents:"
    Get-ChildItem -Path $packageDir | ForEach-Object {
        $sizeStr = if ($_.Length -lt 1MB) {
            "$([math]::Round($_.Length / 1KB, 1)) KB"
        }
        else {
            "$([math]::Round($_.Length / 1MB, 1)) MB"
        }
        Write-Host "  - $($_.Name) ($sizeStr)"
    }

    Write-Host "`nNext steps:"
    Write-Host "1. Review the generated scripts and metadata"
    Write-Host "2. Upload the entire package directory to Tanium Deploy"
    Write-Host "3. Configure install/remove operations using the generated scripts"
    Write-Host "4. Import metadata from $metadataFile"

    # Mark package as completed successfully
    $packageCompleted = $true
}
catch {
    Write-Error "Failed to create package: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}
finally {
    # Clean up incomplete package directory
    if (-not $packageCompleted -and (Test-Path $packageDir)) {
        Write-Host "`nCleaning up incomplete package directory..." -ForegroundColor Yellow
        Remove-Item -Path $packageDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Package directory removed" -ForegroundColor Green
    }
}

Write-Verbose "Get-UpdateCatalogPackage completed"
exit 0
