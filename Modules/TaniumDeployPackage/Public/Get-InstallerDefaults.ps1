function Get-InstallerDefaults {
    <#
    .SYNOPSIS
        Loads installer type defaults for silent installation, uninstallation, and detection.

    .DESCRIPTION
        Retrieves default configuration for a specific installer type including silent switches,
        timeout values, success codes, and detection methods. These defaults are used to
        generate appropriate install/uninstall scripts for Tanium Deploy packages.

    .PARAMETER InstallerType
        The type of installer (msi, inno, nullsoft, burn, exe, msstore)

    .PARAMETER ProductName
        Optional product name to check for product-specific defaults

    .EXAMPLE
        $defaults = Get-InstallerDefaults -InstallerType msi
        # Returns MSI installer defaults

    .EXAMPLE
        $defaults = Get-InstallerDefaults -InstallerType inno -ProductName "MyApp"
        # Returns Inno Setup defaults, merged with MyApp-specific overrides if they exist

    .OUTPUTS
        PSCustomObject with installer defaults
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('msi', 'inno', 'nullsoft', 'burn', 'exe', 'msstore', 'wix', 'nsis')]
        [string]$InstallerType,

        [Parameter()]
        [string]$ProductName
    )

    # Normalize installer type aliases
    $normalizedType = switch ($InstallerType.ToLower()) {
        'nsis' { 'nullsoft' }
        'wix' { 'burn' }
        default { $InstallerType.ToLower() }
    }

    # Load installer type defaults
    $defaultsPath = Join-Path $PSScriptRoot "..\Defaults\$normalizedType.defaults.json"

    if (-not (Test-Path $defaultsPath)) {
        Write-Warning "No defaults found for installer type: $InstallerType (normalized: $normalizedType)"
        Write-Warning "Falling back to generic exe defaults"
        $defaultsPath = Join-Path $PSScriptRoot "..\Defaults\exe.defaults.json"
    }

    try {
        $defaults = Get-Content -Path $defaultsPath -Raw | ConvertFrom-Json
        Write-Verbose "Loaded defaults for installer type: $normalizedType"
    }
    catch {
        Write-Error "Failed to load installer defaults from ${defaultsPath}: $($_.Exception.Message)"
        return $null
    }

    # If ProductName specified, check for product-specific overrides
    if ($ProductName) {
        # Look for product defaults in current directory or common locations
        $productDefaultsPaths = @(
            Join-Path $PWD "$ProductName.defaults.json"
            Join-Path $PWD "$ProductName\$ProductName.defaults.json"
        )

        foreach ($path in $productDefaultsPaths) {
            if (Test-Path $path) {
                try {
                    $productDefaults = Get-Content -Path $path -Raw | ConvertFrom-Json
                    Write-Verbose "Loaded product-specific defaults from: $path"

                    # Merge product defaults with installer type defaults (product overrides installer)
                    $mergedDefaults = $defaults.PSObject.Copy()
                    foreach ($prop in $productDefaults.PSObject.Properties) {
                        $mergedDefaults.$($prop.Name) = $prop.Value
                    }

                    $defaults = $mergedDefaults
                    break
                }
                catch {
                    Write-Warning "Failed to load product defaults from ${path}: $($_.Exception.Message)"
                }
            }
        }
    }

    return $defaults
}
