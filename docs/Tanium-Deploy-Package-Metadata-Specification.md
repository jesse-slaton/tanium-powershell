# Tanium Deploy Package Metadata Specification

This document defines the JSON metadata format for Tanium Deploy packages. This specification should be followed when creating automated package generation scripts or manually crafting package metadata.

**Version:** 1.0
**Last Updated:** 2025-10-17
**Applies To:** Tanium Deploy 2.x and later

## Overview

Tanium Deploy package metadata is stored as JSON and provides configuration for how packages should be installed, removed, and displayed in the Tanium console. This metadata follows Tanium's best practices for software deployment.

## JSON Structure

```json
{
  "vendor": "string",
  "productName": "string",
  "productVersion": "string",
  "architecture": "string",
  "diskSpaceMB": number,
  "memoryMB": number,
  "downloadUrl": "string",
  "sha256": "string",
  "additionalDetails": "string (URL)",
  "installOperation": {
    "command": "string",
    "timeout": number,
    "successCodes": [number, ...]
  },
  "removeOperation": {
    "command": "string",
    "timeout": number,
    "successCodes": [number, ...]
  },
  "osRequirements": {
    "editionId": "string or null",
    "productName": "string or null",
    "build": "string or null"
  },
  "selfService": {
    "name": "string (≤25 chars)",
    "icon": "string or null"
  },
  "installRequirements": "string (WQL-like expression)",
  "installVerification": "string (WQL query)",
  "updateDetection": "string or null"
}
```

## Field Definitions

### Top-Level Fields

#### `vendor`
- **Type:** String
- **Required:** Yes
- **Description:** The software vendor/publisher name
- **Example:** `"Microsoft"`, `"Adobe"`, `"Google"`
- **Best Practice:** Use consistent vendor naming across all packages

#### `productName`
- **Type:** String
- **Required:** Yes
- **Description:** The product name without version information
- **Example:** `"2025-10 Cumulative Update for Windows 11, version 25H2 for x64-based Systems"`, `"Adobe Acrobat Reader DC"`
- **Best Practice:** Keep concise but descriptive. Remove KB numbers or version strings from the name.

#### `productVersion`
- **Type:** String
- **Required:** Yes
- **Description:** The version or update identifier for the package
- **Example:** `"KB5066835"`, `"2024.001.20643"`, `"1.2.3"`
- **Best Practice:** Use vendor's official version format

#### `architecture`
- **Type:** String
- **Required:** Yes
- **Description:** Target processor architecture
- **Example:** `"x64"`, `"x86"`, `"ARM64"`, `"universal"`
- **Best Practice:** Use lowercase for consistency

#### `diskSpaceMB`
- **Type:** Number (integer)
- **Required:** Yes
- **Description:** Minimum free disk space required in megabytes
- **Example:** `500`, `1024`, `10240`
- **Best Practice:** Calculate as 3x the package size to account for extraction, temporary files, and installation. This provides adequate space for most installers.

#### `memoryMB`
- **Type:** Number (integer)
- **Required:** Yes
- **Description:** Minimum available memory required in megabytes
- **Example:** `512`, `1024`, `4096`
- **Best Practice:** Use 512 MB as default for most packages unless specific requirements exist

#### `downloadUrl`
- **Type:** String (URL)
- **Required:** No (but recommended)
- **Description:** Original download URL for the package source file
- **Example:** `"https://download.microsoft.com/download/..."`
- **Purpose:** Provides traceability and allows for re-downloading if needed
- **Best Practice:** Include the full, direct download URL

#### `sha256`
- **Type:** String (hexadecimal)
- **Required:** No (but strongly recommended)
- **Description:** SHA-256 hash of the primary package file for integrity verification
- **Example:** `"A1B2C3D4E5F67890..."`
- **Best Practice:** Always calculate and include for security and verification purposes
- **Format:** 64-character lowercase hexadecimal string

#### `additionalDetails`
- **Type:** String (URL)
- **Required:** No
- **Description:** URL to vendor documentation, release notes, or support article
- **Example:** `"https://support.microsoft.com/kb/5066835"`, `"https://helpx.adobe.com/acrobat/release-note.html"`
- **Purpose:** Provides users with quick access to product information and troubleshooting resources
- **Best Practice:** Link to official vendor pages when available

### installOperation Object

Defines how the package is installed.

#### `installOperation.command`
- **Type:** String
- **Required:** Yes
- **Description:** Command line to execute for installation
- **Example:** `"powershell.exe -ExecutionPolicy Bypass -File \".\Install-KB5066835.ps1\""`
- **Best Practice:**
  - Use full paths to executables when possible
  - Quote paths containing spaces
  - Use relative paths (`.\\`) for package files
  - For PowerShell scripts, always include `-ExecutionPolicy Bypass`

#### `installOperation.timeout`
- **Type:** Number (integer)
- **Required:** Yes
- **Description:** Maximum execution time in seconds before timing out
- **Example:** `300`, `1800`, `3600`
- **Best Practice:**
  - Small packages: 300-600 seconds (5-10 minutes)
  - Medium packages: 1800 seconds (30 minutes)
  - Large updates/cumulative updates: 3600 seconds (60 minutes)
  - Add buffer for slow systems

#### `installOperation.successCodes`
- **Type:** Array of Numbers
- **Required:** Yes
- **Description:** Exit codes that indicate successful installation
- **Example:** `[0, 3010]`, `[0]`
- **Common Codes:**
  - `0` - Success
  - `3010` - Success, reboot required
  - `1641` - Success, initiated reboot
  - `2359302` - Already installed (Windows Update)
- **Best Practice:** Include both 0 and 3010 for Windows installers

### removeOperation Object

Defines how the package is removed/uninstalled.

#### `removeOperation.command`
- **Type:** String
- **Required:** Yes
- **Description:** Command line to execute for removal
- **Example:** `"powershell.exe -ExecutionPolicy Bypass -File \".\Remove-KB5066835.ps1\""`
- **Best Practice:** Follow same guidelines as installOperation.command

#### `removeOperation.timeout`
- **Type:** Number (integer)
- **Required:** Yes
- **Description:** Maximum execution time in seconds for removal
- **Example:** `600`, `1800`
- **Best Practice:** Uninstalls typically faster than installs, use 1/2 to 2/3 of install timeout (1800 seconds / 30 minutes is common for cumulative updates)

#### `removeOperation.successCodes`
- **Type:** Array of Numbers
- **Required:** Yes
- **Description:** Exit codes indicating successful removal
- **Example:** `[0, 3010]`
- **Common Codes:**
  - `0` - Success
  - `3010` - Success, reboot required
  - `2359303` - Not installed (Windows Update)
- **Best Practice:** Include success codes even if removal isn't supported

### osRequirements Object

Specifies operating system requirements based on registry values. This is preferred over Tanium's "Restrict Operating Systems" feature.

#### `osRequirements.editionId`
- **Type:** String or null
- **Required:** No
- **Description:** Required Windows edition ID from registry
- **Registry Key:** `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\EditionID`
- **Example:** `"Professional"`, `"Enterprise"`, `"ServerStandard"`
- **Best Practice:** Use null unless specific edition required

#### `osRequirements.productName`
- **Type:** String or null
- **Required:** No
- **Description:** Required Windows product name
- **Registry Key:** `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName`
- **Example:** `"Windows 10 Pro"`, `"Windows 11 Enterprise"`
- **Best Practice:** Use null unless specific OS version required

#### `osRequirements.build`
- **Type:** String or null
- **Required:** No
- **Description:** Required minimum OS build number
- **Registry Key:** `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentBuild`
- **Example:** `"22631"`, `"19045"`
- **Best Practice:** Use null unless minimum build is required

### selfService Object

Defines how the package appears in Tanium Deploy's self-service interface.

#### `selfService.name`
- **Type:** String
- **Required:** Yes
- **Description:** Display name shown to end users
- **Max Length:** 25 characters (Tanium recommendation)
- **Example:** `"KB5066835 Win11 x64"`, `"Chrome v120 x64"`
- **Best Practice:**
  - Keep under 25 characters
  - Include key identifying information (version, OS, architecture)
  - Use abbreviations when needed: Win10, Win11, WinSvr2022

#### `selfService.icon`
- **Type:** String or null
- **Required:** No
- **Description:** Path or identifier for package icon
- **Example:** `null`, `"chrome.ico"`
- **Best Practice:** Use null if no custom icon available

### installRequirements

#### `installRequirements`
- **Type:** String
- **Required:** Yes
- **Description:** WQL-like expression that determines if installation should proceed
- **Example:** `'Registry Path exists "HKLM\\Path\\Does\\Not\\Exist"'`
- **Purpose:** For Windows Updates/Hotfixes, use a bogus registry path to ensure install always runs (Tanium best practice)
- **Common Patterns:**
  - **Always Install (Hotfix):** `'Registry Path exists "HKLM\\Path\\Does\\Not\\Exist"'`
  - **File Not Exists:** `'File "C:\\Program Files\\App\\app.exe" does not exist'`
  - **Registry Value Check:** `'Registry Value "HKLM\\Software\\Company\\Product\\Version" does not equal "1.2.3"'`
- **Best Practice:**
  - For hotfixes, use bogus path to always install
  - For applications, check for existing installation
  - Escape backslashes in paths (`\\`)

### installVerification

#### `installVerification`
- **Type:** String (WQL query)
- **Required:** Yes
- **Description:** WQL query to verify successful installation
- **Example:** `"SELECT HotFixID FROM Win32_QuickFixEngineering WHERE HotFixID=\"KB5066835\""`
- **Common Patterns:**
  - **Hotfix:** `"SELECT HotFixID FROM Win32_QuickFixEngineering WHERE HotFixID=\"KB{number}\""`
  - **Application:** `"SELECT Name FROM Win32_Product WHERE Name='Application Name' AND Version='1.2.3'"`
  - **File Exists:** `"SELECT Name FROM CIM_DataFile WHERE Name='C:\\Program Files\\App\\app.exe'"`
  - **Registry Value:** `"SELECT Name FROM Win32_Registry WHERE ..."`
- **Best Practice:**
  - Must return at least one row to indicate installed
  - Use appropriate WMI class for verification type
  - Escape quotes and backslashes properly

### updateDetection

#### `updateDetection`
- **Type:** String or null
- **Required:** No
- **Description:** Logic for detecting if an update is available
- **Example:** `null`
- **Best Practice:** Use null unless implementing custom update detection logic

## Complete Example: Windows Update Package

```json
{
  "vendor": "Microsoft",
  "productName": "2025-10 Cumulative Update for Windows 11, version 25H2 for x64-based Systems",
  "productVersion": "KB5066835",
  "architecture": "x64",
  "diskSpaceMB": 11802,
  "memoryMB": 512,
  "downloadUrl": "http://download.windowsupdate.com/c/msdownload/update/software/secu/2025/10/windows11.0-kb5066835-x64_a1b2c3d4.msu",
  "sha256": "a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890",
  "additionalDetails": "https://support.microsoft.com/kb/5066835",
  "installOperation": {
    "command": "powershell.exe -ExecutionPolicy Bypass -File \".\\Install-KB5066835.ps1\"",
    "timeout": 3600,
    "successCodes": [0, 3010]
  },
  "removeOperation": {
    "command": "powershell.exe -ExecutionPolicy Bypass -File \".\\Remove-KB5066835.ps1\"",
    "timeout": 1800,
    "successCodes": [0, 3010]
  },
  "osRequirements": {
    "editionId": null,
    "productName": null,
    "build": null
  },
  "selfService": {
    "name": "KB5066835 Win11 x64",
    "icon": null
  },
  "installRequirements": "Registry Path exists \"HKLM\\Path\\Does\\Not\\Exist\"",
  "installVerification": "SELECT HotFixID FROM Win32_QuickFixEngineering WHERE HotFixID=\"KB5066835\"",
  "updateDetection": null
}
```

## Complete Example: Application Package

```json
{
  "vendor": "Adobe",
  "productName": "Adobe Acrobat Reader DC",
  "productVersion": "24.001.20643",
  "architecture": "x64",
  "diskSpaceMB": 1024,
  "memoryMB": 512,
  "downloadUrl": "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2400120643/AcroRdrDC2400120643_en_US.exe",
  "sha256": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
  "additionalDetails": "https://helpx.adobe.com/acrobat/release-note/release-notes-acrobat-reader.html",
  "installOperation": {
    "command": "AcroRdrDC2400120643_en_US.exe /sAll /rs /msi EULA_ACCEPT=YES",
    "timeout": 900,
    "successCodes": [0, 3010]
  },
  "removeOperation": {
    "command": "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-AC0F074E4100} /qn /norestart",
    "timeout": 600,
    "successCodes": [0, 3010, 1605]
  },
  "osRequirements": {
    "editionId": null,
    "productName": null,
    "build": null
  },
  "selfService": {
    "name": "Adobe Reader DC 24.1",
    "icon": null
  },
  "installRequirements": "File \"C:\\Program Files\\Adobe\\Acrobat DC\\Acrobat\\Acrobat.exe\" does not exist OR Registry Value \"HKLM\\SOFTWARE\\Adobe\\Acrobat Reader\\DC\\Installer\\Version\" does not equal \"24.001.20643\"",
  "installVerification": "SELECT Name FROM Win32_Product WHERE Name LIKE 'Adobe Acrobat Reader%' AND Version='24.001.20643'",
  "updateDetection": null
}
```

## Tanium Deploy Best Practices Reference

### For Hotfixes/Windows Updates

1. **Install Requirements**: Use bogus registry path `"HKLM\\Path\\Does\\Not\\Exist"` to ensure install always runs
2. **Install Verification**: Use `Win32_QuickFixEngineering` WMI class
3. **OS Requirements**: Use registry values instead of "Restrict Operating Systems" feature
4. **Self-Service Name**: Include KB number, OS abbreviation, and architecture

### For Applications

1. **Install Requirements**: Check if application exists or version is outdated
2. **Install Verification**: Use `Win32_Product` or file existence checks
3. **Success Codes**: Include 1605 (not installed) for uninstall operations
4. **Disk Space**: Calculate as 3x installer size

### General Guidelines

1. Always include SHA-256 hashes for security
2. Include download URLs for traceability
3. Link to vendor documentation via additionalDetails
4. Keep self-service names under 25 characters
5. Use consistent vendor naming across packages
6. Test both install and remove operations
7. Include appropriate timeout values
8. Calculate disk space as 3x package size (extraction + temp files + installation)
9. Document any special requirements in package README

## Related Documentation

- [Tanium Deploy User Guide](https://help.tanium.com/bundle/ug_deploy_cloud/page/deploy/managing_software.html)
- [Get-UpdateCatalogPackage.ps1](../Admin/Software/UpdateCatalogPackage/Get-UpdateCatalogPackage.ps1) - Reference implementation

## Version History

- **1.0** (2025-10-17): Initial specification
  - Defined all required and optional fields
  - Added examples for Windows Updates and applications
  - Documented Tanium best practices
  - Added field-by-field reference guide

---

**License:** MIT
**Maintained By:** Jesse Slaton
**Repository:** https://github.com/jesse-slaton/tanium-powershell
