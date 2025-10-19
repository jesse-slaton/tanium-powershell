# TaniumDeployPackage Module Design

**Status:** Proposed
**Version:** 1.0 (Draft)
**Date:** 2025-10-17

## Overview

This document outlines the design for a PowerShell module to standardize Tanium Deploy package generation across multiple sources (Microsoft Update Catalog, WinGet, manual installers, etc.).

## Motivation

Current state:
- `Get-UpdateCatalogPackage.ps1` successfully generates Tanium Deploy packages from Microsoft Update Catalog
- Future work includes WinGet manifest-based package generation
- Common functionality exists: downloads, metadata generation, wrapper script creation

Proposed state:
- Centralized module with reusable functions
- Consistent package structure across all sources
- Reduced code duplication
- Easier maintenance and testing

## Module Structure

```
Modules/
└── TaniumDeployPackage/
    ├── TaniumDeployPackage.psd1          # Module manifest
    ├── TaniumDeployPackage.psm1          # Module loader
    ├── Classes/
    │   └── PackageMetadata.Class.ps1     # Metadata object class
    ├── Public/
    │   ├── New-TaniumDeployPackage.ps1   # Main package creation orchestrator
    │   ├── Get-UpdateCatalogPackage.ps1  # MS Update Catalog source
    │   ├── Get-WinGetPackage.ps1         # WinGet manifest source (future)
    │   └── Invoke-FileDownload.ps1       # Public download function
    ├── Private/
    │   ├── New-PackageMetadata.ps1       # Metadata generation
    │   ├── New-InstallScript.ps1         # Install script template
    │   ├── New-RemoveScript.ps1          # Remove script template
    │   ├── New-PackageReadme.ps1         # README generation
    │   ├── Test-PackageStructure.ps1     # Validation
    │   └── Get-ArchitectureFromString.ps1 # Helper functions
    └── Templates/
        ├── Install-Template.ps1           # Base install script
        ├── Remove-Template.ps1            # Base remove script
        └── README-Template.md             # Base README
```

## Public Functions

### `New-TaniumDeployPackage`
Core orchestration function for creating packages from various sources.

```powershell
New-TaniumDeployPackage -Source "UpdateCatalog" -KB KB5066835 -OperatingSystem "Windows 11" -OutputPath "C:\Packages"
New-TaniumDeployPackage -Source "WinGet" -PackageId "Microsoft.PowerToys" -Version "0.75.1" -OutputPath "C:\Packages"
New-TaniumDeployPackage -Source "Manual" -InstallerPath "C:\installer.msi" -ProductName "MyApp" -Version "1.0"
```

### `Get-UpdateCatalogPackage`
Specialized function for Microsoft Update Catalog (current implementation).

```powershell
Get-UpdateCatalogPackage -KB KB5066835 -OperatingSystem "Windows 11" -Architecture x64 -OSRelease 25H2
```

### `Get-WinGetPackage`
Future: Generate packages from WinGet manifests.

```powershell
Get-WinGetPackage -PackageId "Microsoft.PowerToys" -Version "0.75.1" -Architecture x64
```

### `Invoke-FileDownload`
BITS/WebClient download with progress tracking (reusable).

```powershell
Invoke-FileDownload -Url "https://example.com/file.msi" -Destination "C:\temp\file.msi" -UseBits $true
```

## Private Functions (Reusable Core)

### `New-PackageMetadata`
Generates Tanium Deploy JSON metadata following the specification.

```powershell
$metadata = New-PackageMetadata -PackageInfo @{
    Vendor = "Microsoft"
    ProductName = "PowerToys"
    Version = "0.75.1"
    Architecture = "x64"
    InstallerPath = "C:\temp\installer.exe"
    DownloadUrl = "https://github.com/..."
    InstallCommand = ".\installer.exe /silent"
    RemoveCommand = ".\uninstall.exe /silent"
}
```

### `New-InstallScript`
Creates PowerShell install wrapper scripts.

**Parameters:**
- `InstallerFile` - Name of installer file
- `InstallCommand` - Command to execute
- `ProductName` - For logging
- `SuccessCodes` - Array of success exit codes

**Features:**
- Logging via Start-Transcript
- Exit code handling
- Error handling
- Reboot detection

### `New-RemoveScript`
Creates PowerShell removal wrapper scripts.

**Parameters:**
- `UninstallCommand` - Command to execute
- `ProductName` - For logging
- `ProductId` - For registry lookups
- `SuccessCodes` - Array of success exit codes

**Features:**
- Multiple uninstall methods (MSI GUID, registry, executable)
- Logging
- Error handling

### `New-PackageReadme`
Generates package documentation.

**Contents:**
- Package information
- Installation instructions
- Removal instructions
- Requirements
- Tanium Deploy best practices
- Generation metadata

### Helper Functions

- `Get-ArchitectureFromString` - Parse architecture from strings
- `Get-OSFromString` - Parse OS name from strings
- `Get-SizeInMB` - Convert size strings to MB
- `Get-CompactOSName` - Generate abbreviated OS names (Win10, Win11, etc.)
- `Test-PackageStructure` - Validate package directory structure

## PackageMetadata Class

```powershell
class PackageMetadata {
    [string]$Vendor
    [string]$ProductName
    [string]$ProductVersion
    [string]$Architecture
    [int]$DiskSpaceMB
    [int]$MemoryMB
    [string]$DownloadUrl
    [string]$SHA256
    [string]$AdditionalDetails
    [hashtable]$InstallOperation
    [hashtable]$RemoveOperation
    [hashtable]$OsRequirements
    [hashtable]$SelfService
    [string]$InstallRequirements
    [string]$InstallVerification
    [string]$UpdateDetection

    [hashtable] ToHashtable() {
        # Convert to hashtable for JSON export
    }

    [void] Validate() {
        # Validate required fields
    }
}
```

## Configuration Schema

Module should support configuration file for defaults:

```json
{
  "defaultTimeout": {
    "install": 3600,
    "remove": 1800
  },
  "defaultMemoryMB": 512,
  "diskSpaceMultiplier": 3,
  "defaultSuccessCodes": [0, 3010],
  "outputPath": "C:\\TaniumPackages",
  "useBits": true,
  "taniumBestPractices": {
    "useBogusPatchForHotfixes": true,
    "bogusRegistryPath": "HKLM\\Path\\Does\\Not\\Exist"
  }
}
```

## Usage Examples

### Example 1: Windows Update Package
```powershell
Import-Module TaniumDeployPackage

Get-UpdateCatalogPackage -KB KB5066835 `
    -OperatingSystem "Windows 11" `
    -Architecture x64 `
    -OSRelease 25H2 `
    -OutputPath "C:\Packages"
```

### Example 2: WinGet Package (Future)
```powershell
Import-Module TaniumDeployPackage

Get-WinGetPackage -PackageId "Microsoft.PowerToys" `
    -Version "0.75.1" `
    -Architecture x64 `
    -OutputPath "C:\Packages"
```

### Example 3: Manual Package Creation
```powershell
Import-Module TaniumDeployPackage

New-TaniumDeployPackage -Source Manual `
    -ProductName "Custom Application" `
    -Vendor "Acme Corp" `
    -Version "2.5.1" `
    -Architecture "x64" `
    -InstallerPath "C:\Installers\app.msi" `
    -InstallCommand "msiexec.exe /i app.msi /qn" `
    -RemoveCommand "msiexec.exe /x {GUID} /qn" `
    -OutputPath "C:\Packages"
```

### Example 4: Reusable Download Function
```powershell
Import-Module TaniumDeployPackage

# Download with BITS and progress
Invoke-FileDownload -Url "https://example.com/large-file.zip" `
    -Destination "C:\Downloads\file.zip" `
    -UseBits $true
```

## Benefits

1. **Code Reuse**: Common functions shared across package types
2. **Consistency**: All packages follow same structure and best practices
3. **Maintainability**: Single source of truth for package generation logic
4. **Extensibility**: Easy to add new package sources (WinGet, Chocolatey, custom)
5. **Testing**: Centralized functions easier to unit test
6. **Documentation**: Module help integrated with Get-Help

## Migration Path

### Phase 1: Extract Core Functions
1. Create module structure
2. Move reusable functions to Private/
3. Create PackageMetadata class
4. Add Pester tests

### Phase 2: Refactor Existing Script
1. Convert `Get-UpdateCatalogPackage.ps1` to use module functions
2. Move to Public/ directory
3. Maintain backward compatibility

### Phase 3: Add New Sources
1. Implement `Get-WinGetPackage` using module functions
2. Add other sources as needed

### Phase 4: Advanced Features
1. Add validation functions
2. Implement configuration file support
3. Add logging framework
4. Create package comparison/update detection

## Implementation Considerations

### Backward Compatibility
- Existing `Get-UpdateCatalogPackage.ps1` should continue to work
- Can be wrapper around module functions
- No breaking changes for current users

### Error Handling
- Consistent error handling across all functions
- Meaningful error messages
- Write-Error for non-terminating errors
- Throw for terminating errors

### Progress Reporting
- Write-Verbose for detailed operations
- Write-Progress for long operations
- Consistent progress bar format

### Security
- SHA-256 verification for all downloads
- Certificate validation
- No execution of untrusted code

### Performance
- BITS for large downloads
- Parallel downloads when multiple files needed
- Efficient file operations

## Testing Strategy

### Unit Tests
- Test each private function independently
- Mock external dependencies (web requests, file system)
- Validate metadata generation

### Integration Tests
- Test full package generation workflow
- Validate generated package structure
- Test install/remove scripts (in test environment)

### Validation Tests
- Validate JSON metadata against specification
- Test with various input scenarios
- Edge case handling

## Documentation Requirements

1. Module help (Get-Help TaniumDeployPackage)
2. Function-level help for all public functions
3. Examples in help documentation
4. README.md in module directory
5. Reference to Tanium Deploy Package Metadata Specification

## Future Enhancements

1. **Package Repository Integration**
   - Push packages to network share
   - Integrate with Tanium Deploy API
   - Version management

2. **Update Detection**
   - Check for newer versions
   - Compare installed vs available
   - Automatic update package generation

3. **Package Validation**
   - Pre-deployment validation
   - Test install/remove in isolated environment
   - Compatibility checks

4. **Reporting**
   - Package inventory
   - Generation history
   - Success/failure tracking

5. **GUI Frontend**
   - Windows Forms or WPF interface
   - Package wizard
   - Batch operations

## References

- [Tanium Deploy Package Metadata Specification](./Tanium-Deploy-Package-Metadata-Specification.md)
- [Tanium Deploy User Guide](https://help.tanium.com/bundle/ug_deploy_cloud/page/deploy/managing_software.html)
- [MSCatalogLTS Module](https://github.com/Marco-online/MSCatalogLTS)
- [WinGet CLI](https://github.com/microsoft/winget-cli)

---

**Status:** Draft - Pending Approval
**Next Steps:**
1. Review design with stakeholders
2. Create module skeleton
3. Begin Phase 1 implementation
