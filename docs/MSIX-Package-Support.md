# MSIX/AppX Package Support

## Overview

The WinGet package generator (`Get-WinGetPackage.ps1`) includes full support for Microsoft Store (msstore) packages with MSIX/AppX installers and dependencies.

## Features

### ✅ Automatic Version Detection
- Extracts version directly from MSIX bundle manifest (AppxBundleManifest.xml)
- No longer relies on filename parsing
- Works for `.msix`, `.msixbundle`, `.appx`, `.appxbundle` files
- Properly renames package directory from "Unknown" to detected version

### ✅ Dependency Management

Two modes supported:

#### All-in-One Mode (Default without `-IncludeDependencies`)
- Single Tanium package containing main app + all dependencies
- Install script installs dependencies automatically before main package
- Idempotent: Checks if already installed before reinstalling
- Simplest deployment option

#### Separate Dependencies Mode (`-IncludeDependencies`)
- Main package does **NOT** install dependencies
- Each dependency becomes a separate Tanium Deploy package
- Structure: `dependencies/ProductName/Version/Scope/`
- CI/CD pipeline imports dependencies first, then main package
- Allows shared dependencies across multiple applications

### ✅ Architecture Filtering
- Filters dependencies by `-Architecture` parameter (e.g., `x64`)
- Keeps only **newest version** of each dependency
- Supports Universal architecture (works for all platforms)
- Reduces dependency count (e.g., 19 raw dependencies → 5 filtered)

### ✅ Scope-Aware Installation
- **User scope**: Uses `Add-AppxPackage`
- **Machine scope**: Uses `Add-AppxProvisionedPackage`
- Automatic scope detection from WinGet manifest
- User prompt when multiple scopes available

### ✅ Proper Tanium Detection
Uses AppX Package detection format (not registry):
```
AppX Package "*PackageId*" >= "Version"
```

Reference: [Tanium Deploy Attributes](https://help.tanium.com/bundle/ug_deploy_cloud/page/deploy/attributes_reference.html)

## Usage Examples

### Basic MSIX Package (All-in-One)
```powershell
.\Get-WinGetPackage.ps1 -PackageId "9MSMLRH6LZF3" -Architecture x64 -DownloadInstallers
```

**Result**:
```
Windows Notepad/
└── 11.2507.26.0/
    └── machine/
        ├── Install-Windows Notepad.ps1      # Installs deps + main package
        ├── Remove-Windows Notepad.ps1
        ├── tanium-deploy-metadata.json
        └── Microsoft.WindowsNotepad_11.2507.26.0_Desktop_X64.msixbundle
```

### Separate Dependencies Mode
```powershell
.\Get-WinGetPackage.ps1 -PackageId "9MSMLRH6LZF3" -Architecture x64 -DownloadInstallers -IncludeDependencies
```

**Result**:
```
Windows Notepad/
└── 11.2507.26.0/
    └── machine/
        ├── Install-Windows Notepad.ps1      # Does NOT install dependencies
        ├── Remove-Windows Notepad.ps1
        ├── tanium-deploy-metadata.json
        ├── Microsoft.WindowsNotepad_11.2507.26.0_Desktop_X64.msixbundle
        └── dependencies/
            ├── Microsoft.UI.Xaml.2.8/
            │   └── 8.2501.31001.0/
            │       └── machine/
            │           ├── Install-Microsoft.UI.Xaml.2.8.ps1
            │           ├── Remove-Microsoft.UI.Xaml.2.8.ps1
            │           ├── tanium-deploy-metadata.json
            │           └── Microsoft.UI.Xaml.2.8_8.2501.31001.0_Universal_X64.appx
            ├── Microsoft.VCLibs.140.00/
            │   └── 14.0.33519.0/
            │       └── machine/
            └── ...
```

## Version Extraction Details

### Get-InstallerVersion Function

Located in `Modules/TaniumDeployPackage/Private/Get-InstallerVersion.ps1`

**Supported File Types**:
- `.msix`, `.msixbundle`, `.appx`, `.appxbundle`: Extracts from AppxManifest.xml inside ZIP
- `.msi`: Uses [MSI module](https://www.powershellgallery.com/packages/MSI) from PSGallery

**MSIX Extraction Process**:
1. Opens MSIX file as ZIP archive
2. Locates `AppxManifest.xml` or `AppxMetadata/AppxBundleManifest.xml`
3. Parses XML to extract `Identity.Version` attribute
4. Returns version string (e.g., "11.2507.26.0")

**MSI Extraction** (requires `Install-Module MSI`):
```powershell
Import-Module MSI
$msiInfo = Get-MSIFileInformation -Path $InstallerPath
return $msiInfo.ProductVersion
```

## CI/CD Pipeline Integration

When using `-IncludeDependencies`, your pipeline must:

1. **Discover** dependency packages in `dependencies/` subdirectory
2. **Check** if dependency already exists in Tanium (by name + version)
3. **Import** dependencies to Tanium **before** importing main package
4. **Skip** dependencies that already exist (avoid duplicates)

**Example Pipeline Logic**:
```powershell
$mainPackageDir = "Windows Notepad/11.2507.26.0/machine"
$depsDir = Join-Path $mainPackageDir "dependencies"

if (Test-Path $depsDir) {
    $depPackages = Get-ChildItem -Path $depsDir -Recurse -Filter "tanium-deploy-metadata.json"

    foreach ($depMetadata in $depPackages) {
        $metadata = Get-Content $depMetadata | ConvertFrom-Json

        # Check if exists
        if (-not (Get-TaniumPackage -Name $metadata.productName -Version $metadata.productVersion)) {
            Import-TaniumPackage -Path $depMetadata.DirectoryName
        }
    }
}

# Import main package
Import-TaniumPackage -Path $mainPackageDir
```

## Technical Implementation

### Dependency Filtering Algorithm

```powershell
# Group dependencies by base name and architecture
# Example: Microsoft.VCLibs.140.00_14.0.33519.0_Universal_X64.appx
#   → Base: Microsoft.VCLibs.140.00
#   → Version: 14.0.33519.0
#   → Arch: X64

foreach ($dep in $allDependencies) {
    if ($dep -match '^(.+?)_(\d+\.\d+\.\d+\.\d+)_(.+?)_(X64|X86|Arm64|Arm|Universal)') {
        $baseName = $matches[1]
        $version = [Version]$matches[2]
        $arch = $matches[4]

        # Keep only if architecture matches OR is Universal
        if ($arch -in $requestedArchitectures -or $arch -eq 'Universal') {
            # Keep only newest version per base name + architecture
            if (-not $deps[$baseName-$arch] -or $version -gt $deps[$baseName-$arch].Version) {
                $deps[$baseName-$arch] = @{ File = $dep; Version = $version }
            }
        }
    }
}
```

### Directory Renaming Process

```powershell
# Extract version from MSIX bundle
$extractedVersion = Get-InstallerVersion -InstallerPath $bundlePath

# Update package info
$packageInfo.Version = $extractedVersion

# Rename directory from "Unknown" to actual version
Move-Item -Path "Windows Notepad/Unknown/machine" `
          -Destination "Windows Notepad/11.2507.26.0/machine"
```

## Requirements

- **PowerShell 5.1+**: Core functionality
- **WinGet CLI**: Package download and manifest parsing
- **MSI Module** (optional): For MSI version extraction
  ```powershell
  Install-Module MSI -Scope CurrentUser
  ```

## Troubleshooting

### "Version Unknown" in output
- Ensure MSIX bundle was downloaded (`-DownloadInstallers`)
- Check that `Get-InstallerVersion` function is loaded
- Verify MSIX file is valid (not corrupted)

### Dependencies not filtered
- Specify `-Architecture` parameter (e.g., `x64`)
- Check dependency filenames match expected pattern
- Review verbose output for parsing errors

### Directory not renamed
- Check that version was successfully extracted
- Verify no file locks on directory
- Review verbose output for Move-Item errors

## References

- [WinGet Documentation](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
- [MSIX Package Format](https://learn.microsoft.com/en-us/windows/msix/overview)
- [Tanium Deploy Attributes Reference](https://help.tanium.com/bundle/ug_deploy_cloud/page/deploy/attributes_reference.html)
- [MSI PowerShell Module](https://www.powershellgallery.com/packages/MSI)
