@{
    # Script module or binary module file associated with this manifest
    RootModule = 'TaniumDeployPackage.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'f5e2d3a1-7b4c-4f8e-9d2a-6c1b5e8a3f7d'

    # Author of this module
    Author = 'Jesse Slaton'

    # Company or vendor of this module
    CompanyName = ''

    # Copyright statement for this module
    Copyright = '(c) 2025 Jesse Slaton. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for generating Tanium Deploy packages from various sources (Microsoft Update Catalog, WinGet, manual installers). Provides reusable functions for downloading, metadata generation, and wrapper script creation following Tanium best practices.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Invoke-FileDownload'
        'New-InstallScript'
        'New-RemoveScript'
        'New-MsixInstallScript'
        'New-MsixRemoveScript'
        'New-TaniumDeployMetadata'
        'New-PackageReadme'
        'Get-InstallerDefaults'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Tanium', 'Deploy', 'Package', 'Windows', 'Update', 'WinGet', 'BITS')

            # A URL to the license for this module
            LicenseUri = 'https://github.com/jesse-slaton/tanium-powershell/blob/main/LICENSE'

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/jesse-slaton/tanium-powershell'

            # ReleaseNotes of this module
            ReleaseNotes = @'
# 1.0.0 (2025-10-17)

Initial release of TaniumDeployPackage module.

## Features
- BITS-based file download with progress tracking and resume capability
- Automatic fallback to WebClient if BITS unavailable
- Reusable functions for Tanium Deploy package generation
- Support for Windows Update Catalog packages
- Follows Tanium Deploy best practices

## Exported Functions
- Invoke-FileDownload: Download files with BITS/WebClient and progress tracking

## Internal Functions
- New-InstallScript: Generate install wrapper scripts
- New-RemoveScript: Generate removal wrapper scripts
- New-TaniumDeployMetadata: Generate JSON metadata
- New-PackageReadme: Generate package documentation
- Helper functions for parsing (architecture, OS, sizes)

## References
- Tanium Deploy Package Metadata Specification
- MSCatalogLTS module integration
'@
        }
    }
}
