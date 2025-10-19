function Get-InstallerVersion {
    <#
    .SYNOPSIS
        Extracts version information from installer files.

    .DESCRIPTION
        Reads version information directly from installer files:
        - MSIX/MSIXBUNDLE/APPX/APPXBUNDLE: Extracts from AppxManifest.xml
        - MSI: Queries Windows Installer database for ProductVersion

    .PARAMETER InstallerPath
        Path to the installer file

    .EXAMPLE
        Get-InstallerVersion -InstallerPath "C:\Temp\Package.msixbundle"

    .OUTPUTS
        String containing the version number, or $null if version cannot be determined
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InstallerPath
    )

    if (-not (Test-Path $InstallerPath)) {
        Write-Warning "Installer file not found: $InstallerPath"
        return $null
    }

    $extension = [System.IO.Path]::GetExtension($InstallerPath).ToLower()

    switch ($extension) {
        { $_ -in @('.msix', '.msixbundle', '.appx', '.appxbundle') } {
            # MSIX/AppX files are ZIP archives containing AppxManifest.xml
            try {
                Write-Verbose "Extracting version from MSIX/AppX package: $InstallerPath"

                # Load the ZIP file
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $zip = [System.IO.Compression.ZipFile]::OpenRead($InstallerPath)

                try {
                    # Find AppxManifest.xml (could be in root or AppxMetadata folder for bundles)
                    $manifestEntry = $zip.Entries | Where-Object {
                        $_.FullName -eq 'AppxManifest.xml' -or
                        $_.FullName -eq 'AppxMetadata/AppxBundleManifest.xml'
                    } | Select-Object -First 1

                    if ($manifestEntry) {
                        $stream = $manifestEntry.Open()
                        $reader = New-Object System.IO.StreamReader($stream)
                        $manifestXml = $reader.ReadToEnd()
                        $reader.Close()
                        $stream.Close()

                        # Parse XML to extract version
                        [xml]$manifest = $manifestXml

                        # Try bundle manifest first, then package manifest
                        $version = $null
                        if ($manifest.Bundle) {
                            $version = $manifest.Bundle.Identity.Version
                        } elseif ($manifest.Package) {
                            $version = $manifest.Package.Identity.Version
                        }

                        if ($version) {
                            Write-Verbose "Extracted version from manifest: $version"
                            return $version
                        }
                    } else {
                        Write-Warning "AppxManifest.xml not found in package"
                    }
                } finally {
                    $zip.Dispose()
                }
            } catch {
                Write-Warning "Failed to extract version from MSIX/AppX: $_"
            }
        }

        '.msi' {
            # Use MSI module from PSGallery (Install-Module MSI)
            if (-not (Get-Module -ListAvailable -Name MSI)) {
                Write-Warning "MSI module not installed. Install with: Install-Module MSI -Scope CurrentUser"
                Write-Warning "Skipping version extraction for MSI file"
                return $null
            }

            try {
                Write-Verbose "Using MSI module to query version: $InstallerPath"
                Import-Module MSI -ErrorAction Stop
                $msiInfo = Get-MSIFileInformation -Path $InstallerPath -ErrorAction Stop
                if ($msiInfo.ProductVersion) {
                    Write-Verbose "Extracted version from MSI: $($msiInfo.ProductVersion)"
                    return $msiInfo.ProductVersion
                }
            } catch {
                Write-Warning "Failed to extract version from MSI using MSI module: $_"
            }
        }

        default {
            Write-Verbose "Version extraction not supported for file type: $extension"
        }
    }

    return $null
}
