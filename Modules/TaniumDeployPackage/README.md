# TaniumDeployPackage PowerShell Module

PowerShell module for generating Tanium Deploy packages from various sources (Microsoft Update Catalog, WinGet, manual installers). Provides reusable functions for downloading, metadata generation, and wrapper script creation following Tanium best practices.

## Features

- **BITS-based file download** with progress tracking and resume capability
- **Automatic fallback** to WebClient if BITS unavailable
- **Reusable functions** for Tanium Deploy package generation
- **Multiple source support**: Windows Update Catalog, WinGet (planned), manual installers (planned)
- **Follows Tanium Deploy best practices** for metadata, install requirements, and verification

## Installation

### Manual Installation

1. Copy the `TaniumDeployPackage` folder to one of your PowerShell module directories:
   ```powershell
   # User modules (recommended)
   $env:USERPROFILE\Documents\WindowsPowerShell\Modules\TaniumDeployPackage

   # System-wide modules (requires admin)
   C:\Program Files\WindowsPowerShell\Modules\TaniumDeployPackage
   ```

2. Import the module:
   ```powershell
   Import-Module TaniumDeployPackage
   ```

### Verify Installation

```powershell
Get-Module TaniumDeployPackage -ListAvailable
Get-Command -Module TaniumDeployPackage
```

## Requirements

- **PowerShell**: 5.1 or later
- **Windows**: Any version supporting PowerShell 5.1+
- **Dependencies**: MSCatalogLTS module (for Windows Update Catalog packages)

## Exported Functions

### Invoke-FileDownload

Downloads files using BITS (Background Intelligent Transfer Service) with progress tracking and automatic resume capability. Falls back to WebClient if BITS is unavailable.

**Syntax:**
```powershell
Invoke-FileDownload -Url <string> -Destination <string> [-UseBits]
```

**Parameters:**
- **Url** (required): URL of the file to download
- **Destination** (required): Local path where the file should be saved
- **UseBits** (optional): Use BITS for download (default: $true)

**Examples:**

```powershell
# Download with BITS (default)
Invoke-FileDownload -Url "https://example.com/file.msu" -Destination "C:\Temp\file.msu"

# Download with WebClient fallback
Invoke-FileDownload -Url "https://example.com/file.exe" -Destination "C:\Temp\file.exe" -UseBits:$false
```

**Features:**
- Real-time progress bar with percentage, speed, and ETA
- Automatic resume for interrupted downloads (BITS only)
- SHA-256 hash calculation after download
- Comprehensive error handling
- Automatic fallback to WebClient if BITS fails

## Internal Functions (Private)

These functions are available for internal module use but not exported:

### Metadata Generation
- **New-TaniumDeployMetadata**: Generates Tanium Deploy JSON metadata
- **New-PackageReadme**: Generates package README documentation

### Script Generation
- **New-InstallScript**: Generates PowerShell install wrapper scripts
- **New-RemoveScript**: Generates PowerShell removal wrapper scripts

### Helper Functions
- **Get-ArchitectureFromString**: Parses architecture (x64, x86, ARM64) from strings
- **Get-CompactOSName**: Generates compact OS names for self-service display (Win10, Win11, etc.)
- **Get-SizeInMB**: Converts size strings (KB, MB, GB) to megabytes

## Classes

### PackageMetadata

Type-safe class for package metadata with validation.

**Properties:**
- Vendor, ProductName, ProductVersion, Architecture
- DiskSpaceMB, MemoryMB
- DownloadUrl, SHA256, AdditionalDetails
- InstallOperation, RemoveOperation
- SelfService (name, icon)
- InstallRequirements, InstallVerification

**Methods:**
- `ToHashtable()`: Converts to hashtable for JSON serialization
- `Validate()`: Validates all required fields are present

## Usage Examples

### Example 1: Download a file with progress tracking

```powershell
Import-Module TaniumDeployPackage

$url = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2024/10/windows11.0-kb5066835-x64_abcd1234.msu"
$dest = "C:\Temp\KB5066835.msu"

Invoke-FileDownload -Url $url -Destination $dest
```

### Example 2: Using private functions (internal use)

```powershell
# This is how the module uses internal functions
# (Not typically called by end users directly)

# Parse architecture from update title
$arch = Get-ArchitectureFromString -String "Windows 11 for x64-based Systems"
# Returns: "x64"

# Get compact OS name for self-service
$osName = Get-CompactOSName -String "Windows 11"
# Returns: "Win11"

# Convert size string to MB
$sizeMB = Get-SizeInMB -SizeString "3933.9 MB"
# Returns: 3933
```

## Tanium Deploy Best Practices

This module follows Tanium best practices for package generation:

### Hotfixes / Windows Updates
- **Install Requirements**: Uses bogus registry path `HKLM\Path\Does\Not\Exist` to ensure install always runs
- **Install Verification**: Uses WQL query against Win32_QuickFixEngineering
- **Timeout**: 60 minutes for install, 30 minutes for removal
- **Disk Space**: 3x download size
- **Self-Service Name**: ≤25 characters, includes KB, OS, and architecture
- **Additional Details**: Link to Microsoft Support KB article

### Applications
- **Install Requirements**: Registry path checks for existing installations
- **Install Verification**: WQL queries or registry checks
- **Timeout**: Based on application complexity
- **Disk Space**: 3x download size (adjustable per application)

See [Tanium Deploy Package Metadata Specification](../../docs/Tanium-Deploy-Package-Metadata-Specification.md) for complete details.

## Metadata Specification

The module generates JSON metadata following the Tanium Deploy specification. Key fields:

```json
{
  "vendor": "Microsoft",
  "productName": "Cumulative Update for Windows 11",
  "productVersion": "KB5066835",
  "architecture": "x64",
  "diskSpaceMB": 12000,
  "memoryMB": 512,
  "downloadUrl": "https://...",
  "sha256": "abc123...",
  "additionalDetails": "https://support.microsoft.com/kb/5066835",
  "installOperation": { ... },
  "removeOperation": { ... },
  "selfService": { "name": "KB5066835 Win11 x64" },
  "installRequirements": "Registry Path exists \"HKLM\\Path\\Does\\Not\\Exist\"",
  "installVerification": "SELECT HotFixID FROM Win32_QuickFixEngineering WHERE HotFixID=\"KB5066835\""
}
```

For complete specification, see: [docs/Tanium-Deploy-Package-Metadata-Specification.md](../../docs/Tanium-Deploy-Package-Metadata-Specification.md)

## Module Design

For architecture and design details, see: [docs/TaniumDeployPackage-Module-Design.md](../../docs/TaniumDeployPackage-Module-Design.md)

## Roadmap

### Phase 1: Core Functionality (Current)
- ✅ File download with BITS support
- ✅ Metadata generation
- ✅ Script generation (install/remove)
- ✅ Helper functions
- ✅ Module structure and manifest

### Phase 2: Windows Update Catalog Integration (Planned)
- Refactor `Get-UpdateCatalogPackage.ps1` to use module
- Add `New-UpdateCatalogPackage` exported function
- MSCatalogLTS integration

### Phase 3: WinGet Integration (Planned)
- `New-WinGetPackage` function
- WinGet manifest parsing
- Automatic download URL resolution

### Phase 4: Manual Installer Support (Planned)
- `New-ManualInstallerPackage` function
- Interactive metadata wizard
- Template-based script generation

## Contributing

This module is part of the [tanium-powershell](https://github.com/jesse-slaton/tanium-powershell) repository.

## License

MIT License - see [LICENSE](../../LICENSE) for details

## Author

Jesse Slaton

## Version History

### 1.0.0 (2025-10-17)

Initial release of TaniumDeployPackage module.

**Features:**
- BITS-based file download with progress tracking and resume capability
- Automatic fallback to WebClient if BITS unavailable
- Reusable functions for Tanium Deploy package generation
- Support for Windows Update Catalog packages
- Follows Tanium Deploy best practices

**Exported Functions:**
- `Invoke-FileDownload`: Download files with BITS/WebClient and progress tracking

**Internal Functions:**
- `New-InstallScript`: Generate install wrapper scripts
- `New-RemoveScript`: Generate removal wrapper scripts
- `New-TaniumDeployMetadata`: Generate JSON metadata
- `New-PackageReadme`: Generate package documentation
- Helper functions for parsing (architecture, OS, sizes)

**References:**
- Tanium Deploy Package Metadata Specification
- MSCatalogLTS module integration

## References

- [Tanium Deploy Documentation](https://help.tanium.com/bundle/ug_deploy_cloud/page/deploy/managing_software.html)
- [MSCatalogLTS Module](https://github.com/kilasuit/MSCatalogLTS)
- [Tanium Deploy Best Practices](https://help.tanium.com/bundle/ug_deploy_cloud/page/deploy/best_practices.html)
