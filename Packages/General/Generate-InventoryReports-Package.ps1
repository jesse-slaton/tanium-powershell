# NOTE: Requires external repo at D:\dev\repos\Windows-Secure-Host-Baseline
# Original repo: https://git.example.com/sydlexius/Windows-Secure-Host-Baseline.git

# NOTE: Requires external repo at D:\dev\repos\Security-Compliance
# Original repo: https://git.example.com/sydlexius/Security-Compliance.git

# NOTE: Requires external repo at D:\dev\repos\Port_Authority
# Original repo: https://github.com/ACK-J/Port_Authority.git

# NOTE: Requires external repo at D:\dev\repos\Legacy-VBScript-Collection
# Original repo: https://git.example.com/sydlexius/Legacy-VBScript-Collection.git

# NOTE: Requires external repo at D:\dev\repos\Application-Management
# Original repo: https://git.example.com/sydlexius/Application-Management.git

# NOTE: Requires external repo at D:\dev\repos\ActiveDirectory-UserManagement
# Original repo: https://git.example.com/sydlexius/ActiveDirectory-UserManagement.git

#Requires -Version 5.1
<#
.SYNOPSIS
    Generates detailed analysis reports from the script inventory

.DESCRIPTION
    Creates five markdown reports analyzing the script inventory for different purposes:
    - TANIUM_CANDIDATES.md
    - GENERAL_UTILITIES.md
    - MODULE_OPPORTUNITIES.md
    - EXTERNAL_DEPENDENCIES.md
    - CLEANUP_CANDIDATES.md
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InventoryCsv = "D:\Dev\PowerShell-Projects\INVENTORY.csv",

    [Parameter()]
    [string]$OutputPath = "D:\Dev\PowerShell-Projects"
)

Write-Host "Loading inventory data..." -ForegroundColor Cyan
$inventory = Import-Csv -Path $InventoryCsv

Write-Host "Generating reports..." -ForegroundColor Cyan

# Report 1: TANIUM_CANDIDATES.md
Write-Host "  Creating TANIUM_CANDIDATES.md..." -ForegroundColor Gray
$taniumSensors = $inventory | Where-Object { $_.Recommendation -eq 'Tanium-Sensor' }
$taniumPackages = $inventory | Where-Object { $_.Recommendation -eq 'Tanium-Package' }
$pipeDelimited = $inventory | Where-Object { $_.PipeDelimitedOutput -eq 'Yes' }
$dualUse = $inventory | Where-Object {
    ($_.TaniumIndicators -ne '') -and
    ($_.FunctionCount -gt 0) -and
    ($_.Recommendation -eq 'General-Utility')
}

$sb1 = New-Object System.Text.StringBuilder
[void]$sb1.AppendLine("# Tanium Candidates Analysis")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("## Overview")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("This report identifies scripts suitable for Tanium deployment:")
[void]$sb1.AppendLine("- **Sensors**: Read-only data collection scripts")
[void]$sb1.AppendLine("- **Packages**: Scripts that modify system state")
[void]$sb1.AppendLine("- **Dual-Use**: Scripts useful for both Tanium and general sysadmin")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("## Statistics")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("- Tanium Sensors: $($taniumSensors.Count)")
[void]$sb1.AppendLine("- Tanium Packages: $($taniumPackages.Count)")
[void]$sb1.AppendLine("- Pipe-Delimited Output Scripts: $($pipeDelimited.Count)")
[void]$sb1.AppendLine("- Dual-Use Candidates: $($dualUse.Count)")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("## Tanium Sensors (Read-Only Data Collection)")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("These scripts are ideal Tanium sensor candidates - they collect and report data without modifying system state.")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("| Script | Lines | Indicators | Synopsis |")
[void]$sb1.AppendLine("|--------|-------|------------|----------|")
foreach ($script in ($taniumSensors | Sort-Object LineCount)) {
    $indicators = $script.TaniumIndicators -replace '\|', ', '
    $synopsis = if ($script.Synopsis) { $script.Synopsis } else { "(No description)" }
    [void]$sb1.AppendLine("| $($script.FileName) | $($script.LineCount) | $indicators | $synopsis |")
}
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("### File Paths")
[void]$sb1.AppendLine("")
foreach ($script in ($taniumSensors | Sort-Object FilePath)) {
    [void]$sb1.AppendLine("- ``$($script.FilePath)``")
}
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("## Tanium Packages (System Modification)")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("These scripts perform system modifications and are suitable for Tanium package deployment.")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("### By Category")
[void]$sb1.AppendLine("")
$packagesByDir = $taniumPackages | Group-Object { ($_.FilePath -split '\\')[0] } | Sort-Object Count -Descending
foreach ($group in $packagesByDir) {
    [void]$sb1.AppendLine("#### $($group.Name) ($($group.Count) scripts)")
    [void]$sb1.AppendLine("")
    foreach ($script in ($group.Group | Sort-Object FileName)) {
        $synopsis = if ($script.Synopsis) { " - $($script.Synopsis)" } else { "" }
        [void]$sb1.AppendLine("- **$($script.FileName)** ($($script.LineCount) lines)$synopsis")
        if ($script.TaniumIndicators) {
            [void]$sb1.AppendLine("  - Indicators: $($script.TaniumIndicators)")
        }
    }
    [void]$sb1.AppendLine("")
}
[void]$sb1.AppendLine("## Scripts with Pipe-Delimited Output")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("These scripts output pipe-delimited data, making them excellent Tanium sensor candidates.")
[void]$sb1.AppendLine("")
foreach ($script in ($pipeDelimited | Sort-Object FilePath)) {
    $synopsis = if ($script.Synopsis) { " - $($script.Synopsis)" } else { "" }
    [void]$sb1.AppendLine("- ``$($script.FilePath)``$synopsis")
}
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("## Dual-Use Scripts")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("These scripts have Tanium indicators but are also useful as general utilities.")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("| Script | Functions | Indicators | Synopsis |")
[void]$sb1.AppendLine("|--------|-----------|------------|----------|")
foreach ($script in ($dualUse | Sort-Object FileName)) {
    $indicators = $script.TaniumIndicators -replace '\|', ', '
    $synopsis = if ($script.Synopsis) { $script.Synopsis } else { "(No description)" }
    [void]$sb1.AppendLine("| $($script.FileName) | $($script.FunctionCount) | $indicators | $synopsis |")
}
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("## Recommendations")
[void]$sb1.AppendLine("")
[void]$sb1.AppendLine("1. **Prioritize Sensors**: The $($taniumSensors.Count) sensor scripts should be tested for Tanium sensor deployment first")
[void]$sb1.AppendLine("2. **Package Review**: Review the $($taniumPackages.Count) package candidates for deployment safety and WhatIf support")
[void]$sb1.AppendLine("3. **Add Pipe Delimiters**: Consider modifying scripts to output pipe-delimited data for better Tanium integration")
[void]$sb1.AppendLine("4. **Standardize Output**: Create a standard output format for all Tanium sensors")
[void]$sb1.AppendLine("5. **Test in Lab**: Always test Tanium packages in a lab environment before production deployment")

$sb1.ToString() | Out-File -FilePath (Join-Path $OutputPath "TANIUM_CANDIDATES.md") -Encoding UTF8

# Report 2: GENERAL_UTILITIES.md
Write-Host "  Creating GENERAL_UTILITIES.md..." -ForegroundColor Gray
$generalUtils = $inventory | Where-Object { $_.Recommendation -eq 'General-Utility' }
$modules = $inventory | Where-Object { $_.FileName -like '*.psm1' }
$helpersWithFunctions = $generalUtils | Where-Object { [int]$_.FunctionCount -ge 3 }

$sb2 = New-Object System.Text.StringBuilder
[void]$sb2.AppendLine("# General Utilities Analysis")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("## Overview")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("This report catalogs general-purpose PowerShell utilities, helper modules, and sysadmin scripts.")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("## Statistics")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("- General Utility Scripts: $($generalUtils.Count)")
[void]$sb2.AppendLine("- PowerShell Modules (.psm1): $($modules.Count)")
[void]$sb2.AppendLine("- Multi-Function Utilities: $($helpersWithFunctions.Count)")
[void]$sb2.AppendLine("- Average Functions per Script: $([math]::Round(($generalUtils | Measure-Object -Property FunctionCount -Average).Average, 2))")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("## PowerShell Modules")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("Existing PowerShell modules in the repository.")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("| Module | Lines | Functions | Synopsis |")
[void]$sb2.AppendLine("|--------|-------|-----------|----------|")
foreach ($module in ($modules | Sort-Object LineCount -Descending)) {
    $synopsis = if ($module.Synopsis) { $module.Synopsis } else { "(No description)" }
    [void]$sb2.AppendLine("| $($module.FileName) | $($module.LineCount) | $($module.FunctionCount) | $synopsis |")
}
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("## Multi-Function Utilities")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("Scripts with 3+ functions that could potentially be converted to modules.")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("| Script | Lines | Functions | Help | Synopsis |")
[void]$sb2.AppendLine("|--------|-------|-----------|------|----------|")
foreach ($script in ($helpersWithFunctions | Sort-Object FunctionCount -Descending | Select-Object -First 50)) {
    $synopsis = if ($script.Synopsis) { $script.Synopsis } else { "(No description)" }
    [void]$sb2.AppendLine("| $($script.FileName) | $($script.LineCount) | $($script.FunctionCount) | $($script.HasHelp) | $synopsis |")
}
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("## General Utilities by Category")
[void]$sb2.AppendLine("")
$utilsByDir = $generalUtils | Group-Object { ($_.FilePath -split '\\')[0] } | Sort-Object Count -Descending
foreach ($group in $utilsByDir) {
    [void]$sb2.AppendLine("### $($group.Name) ($($group.Count) scripts)")
    [void]$sb2.AppendLine("")
    $grouped = $group.Group | Sort-Object LineCount -Descending | Select-Object -First 20
    foreach ($script in $grouped) {
        $synopsis = if ($script.Synopsis) { " - $($script.Synopsis)" } else { "" }
        $funcInfo = if ([int]$script.FunctionCount -gt 0) { " [$($script.FunctionCount) functions]" } else { "" }
        [void]$sb2.AppendLine("- **$($script.FileName)** ($($script.LineCount) lines)$funcInfo$synopsis")
    }
    if ($group.Count -gt 20) {
        [void]$sb2.AppendLine("- ... and $($group.Count - 20) more scripts")
    }
    [void]$sb2.AppendLine("")
}
[void]$sb2.AppendLine("## Top 20 Largest Utilities")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("| Script | Lines | Functions | Help | Synopsis |")
[void]$sb2.AppendLine("|--------|-------|-----------|------|----------|")
foreach ($script in ($generalUtils | Sort-Object LineCount -Descending | Select-Object -First 20)) {
    $synopsis = if ($script.Synopsis) { $script.Synopsis } else { "(No description)" }
    [void]$sb2.AppendLine("| $($script.FileName) | $($script.LineCount) | $($script.FunctionCount) | $($script.HasHelp) | $synopsis |")
}
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("## Recommendations")
[void]$sb2.AppendLine("")
[void]$sb2.AppendLine("1. **Add Documentation**: $(($generalUtils | Where-Object { $_.HasHelp -eq 'No' }).Count) utilities lack help documentation")
[void]$sb2.AppendLine("2. **Module Candidates**: $($helpersWithFunctions.Count) multi-function scripts could become modules")
[void]$sb2.AppendLine("3. **Add WhatIf**: $(($generalUtils | Where-Object { $_.HasWhatIf -eq 'No' }).Count) utilities lack WhatIf support")
[void]$sb2.AppendLine("4. **Create Tests**: None of the utilities have Pester tests")

$sb2.ToString() | Out-File -FilePath (Join-Path $OutputPath "GENERAL_UTILITIES.md") -Encoding UTF8

# Report 3: MODULE_OPPORTUNITIES.md
Write-Host "  Creating MODULE_OPPORTUNITIES.md..." -ForegroundColor Gray
$functionScripts = $inventory | Where-Object { [int]$_.FunctionCount -ge 2 }
$byDirectory = $inventory | Group-Object { ($_.FilePath -split '\\')[0] }

$sb3 = New-Object System.Text.StringBuilder
[void]$sb3.AppendLine("# Module Opportunities Analysis")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("## Overview")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("This report identifies opportunities to consolidate related functions into reusable PowerShell modules.")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("## Statistics")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("- Scripts with 2+ Functions: $($functionScripts.Count)")
[void]$sb3.AppendLine("- Total Directories: $($byDirectory.Count)")
[void]$sb3.AppendLine("- Existing Modules: $($modules.Count)")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("## Suggested Module Consolidations")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("Based on directory structure and related functionality, here are suggested module candidates.")
[void]$sb3.AppendLine("")

$moduleOpportunities = $byDirectory | Where-Object { $_.Count -ge 3 } | Sort-Object Count -Descending
foreach ($group in $moduleOpportunities) {
    $dirName = $group.Name
    $totalFunctions = ($group.Group | Measure-Object -Property FunctionCount -Sum).Sum
    $totalLines = ($group.Group | Measure-Object -Property LineCount -Sum).Sum
    $suggestedModuleName = ($dirName -replace '[^a-zA-Z0-9]', '') + "Module"

    [void]$sb3.AppendLine("### Suggested Module: **$suggestedModuleName**")
    [void]$sb3.AppendLine("")
    [void]$sb3.AppendLine("**Directory**: ``$dirName``")
    [void]$sb3.AppendLine("**Scripts**: $($group.Count) scripts ($totalLines total lines)")
    [void]$sb3.AppendLine("**Functions**: $totalFunctions total functions")
    [void]$sb3.AppendLine("")
    [void]$sb3.AppendLine("**Consolidation Benefits**:")
    [void]$sb3.AppendLine("- Single import instead of multiple script files")
    [void]$sb3.AppendLine("- Shared helper functions")
    [void]$sb3.AppendLine("- Consistent naming and behavior")
    [void]$sb3.AppendLine("- Easier to maintain and version")
    [void]$sb3.AppendLine("")
    [void]$sb3.AppendLine("**Scripts to consolidate**:")
    [void]$sb3.AppendLine("")
    foreach ($script in ($group.Group | Sort-Object FunctionCount -Descending)) {
        if ([int]$script.FunctionCount -gt 0) {
            [void]$sb3.AppendLine("- **$($script.FileName)** - $($script.FunctionCount) functions, $($script.LineCount) lines")
        } else {
            [void]$sb3.AppendLine("- $($script.FileName) - $($script.LineCount) lines")
        }
    }
    [void]$sb3.AppendLine("")
}

[void]$sb3.AppendLine("## Scripts with Shared Naming Patterns")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("Scripts that share naming prefixes could be consolidated into modules.")
[void]$sb3.AppendLine("")

$prefixGroups = $inventory | Where-Object { $_.FileName -match '^(Get|Set|New|Remove|Test|Start|Stop|Invoke)-' } |
    Group-Object { ($_.FileName -split '-')[0] } |
    Where-Object { $_.Count -ge 3 } |
    Sort-Object Count -Descending

foreach ($group in $prefixGroups) {
    [void]$sb3.AppendLine("### $($group.Name)-* Cmdlets ($($group.Count) scripts)")
    [void]$sb3.AppendLine("")
    foreach ($script in ($group.Group | Sort-Object FileName)) {
        [void]$sb3.AppendLine("- ``$($script.FilePath)``")
    }
    [void]$sb3.AppendLine("")
}

[void]$sb3.AppendLine("## High-Value Module Candidates")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("Scripts with many functions that would benefit most from modularization.")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("| Script | Functions | Lines | Current Location |")
[void]$sb3.AppendLine("|--------|-----------|-------|------------------|")
foreach ($script in ($inventory | Where-Object { [int]$_.FunctionCount -ge 5 } | Sort-Object FunctionCount -Descending)) {
    $dir = ($script.FilePath -split '\\')[0]
    [void]$sb3.AppendLine("| $($script.FileName) | $($script.FunctionCount) | $($script.LineCount) | $dir |")
}
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("## Recommended Module Structure")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine('```')
[void]$sb3.AppendLine("Modules/")
[void]$sb3.AppendLine("  ActiveDirectoryModule/")
[void]$sb3.AppendLine("    ActiveDirectoryModule.psd1")
[void]$sb3.AppendLine("    ActiveDirectoryModule.psm1")
[void]$sb3.AppendLine("    Public/")
[void]$sb3.AppendLine("    Private/")
[void]$sb3.AppendLine("  ApplicationManagementModule/")
[void]$sb3.AppendLine("    ApplicationManagementModule.psd1")
[void]$sb3.AppendLine("    ApplicationManagementModule.psm1")
[void]$sb3.AppendLine("  [etc...]")
[void]$sb3.AppendLine('```')
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("## Recommendations")
[void]$sb3.AppendLine("")
[void]$sb3.AppendLine("1. **Start Small**: Begin with the highest-value candidates (5+ functions)")
[void]$sb3.AppendLine("2. **Group by Domain**: Consolidate by functional area (AD, networking, compliance, etc.)")
[void]$sb3.AppendLine("3. **Follow Standards**: Use standard module structure with Public/Private folders")
[void]$sb3.AppendLine("4. **Add Manifests**: Create .psd1 manifests for all modules")
[void]$sb3.AppendLine("5. **Export Selectively**: Only export public functions in modules")

$sb3.ToString() | Out-File -FilePath (Join-Path $OutputPath "MODULE_OPPORTUNITIES.md") -Encoding UTF8

# Report 4: EXTERNAL_DEPENDENCIES.md
Write-Host "  Creating EXTERNAL_DEPENDENCIES.md..." -ForegroundColor Gray
$scriptsWithModules = $inventory | Where-Object { $_.RequiredModules -ne '' }
$scriptsWithExternalCalls = $inventory | Where-Object { $_.ExternalCalls -ne '' }

$sb4 = New-Object System.Text.StringBuilder
[void]$sb4.AppendLine("# External Dependencies Analysis")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("## Overview")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("This report identifies external repositories, required modules, and inter-script dependencies.")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("## External Repositories Found")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("These are cloned external repositories that should be tracked separately.")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("### Port_Authority")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("**Location**: ``Port_Authority/``")
[void]$sb4.AppendLine("**Status**: External repository (has LICENSE file)")
[void]$sb4.AppendLine("**Recommendation**: Fork this repository or star it for tracking updates")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("### Windows-Secure-Host-Baseline")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("**Location**: ``Windows-Secure-Host-Baseline/``")
[void]$sb4.AppendLine("**Status**: External repository (has LICENSE file)")
[void]$sb4.AppendLine("**Recommendation**: Fork this repository or star it for tracking updates")
[void]$sb4.AppendLine("**Note**: This is likely the Microsoft/Windows-Secure-Host-Baseline repository")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("## Required External Modules")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("Scripts that require external PowerShell modules.")
[void]$sb4.AppendLine("")

$allModules = @()
foreach ($script in $scriptsWithModules) {
    $modules = $script.RequiredModules -split ';' | ForEach-Object { $_.Trim() }
    $allModules += $modules
}
$moduleGroups = $allModules | Group-Object | Sort-Object Count -Descending

if ($moduleGroups.Count -gt 0) {
    [void]$sb4.AppendLine("| Module Name | Used By (# scripts) |")
    [void]$sb4.AppendLine("|-------------|---------------------|")
    foreach ($mod in $moduleGroups) {
        [void]$sb4.AppendLine("| $($mod.Name) | $($mod.Count) |")
    }
    [void]$sb4.AppendLine("")
    [void]$sb4.AppendLine("### Scripts by Required Module")
    [void]$sb4.AppendLine("")
    foreach ($mod in $moduleGroups) {
        [void]$sb4.AppendLine("#### $($mod.Name)")
        [void]$sb4.AppendLine("")
        $scriptsUsingModule = $scriptsWithModules | Where-Object { $_.RequiredModules -like "*$($mod.Name)*" }
        foreach ($script in $scriptsUsingModule) {
            [void]$sb4.AppendLine("- ``$($script.FilePath)``")
        }
        [void]$sb4.AppendLine("")
    }
} else {
    [void]$sb4.AppendLine("No explicit module requirements found in scripts.")
    [void]$sb4.AppendLine("")
}

[void]$sb4.AppendLine("## Inter-Script Dependencies")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("Scripts that call other scripts (dot-sourcing, call operator, etc.).")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("| Script | Dependency Type | Synopsis |")
[void]$sb4.AppendLine("|--------|----------------|----------|")
foreach ($script in ($scriptsWithExternalCalls | Sort-Object FilePath)) {
    $synopsis = if ($script.Synopsis) { $script.Synopsis } else { "(No description)" }
    [void]$sb4.AppendLine("| $($script.FileName) | $($script.ExternalCalls) | $synopsis |")
}
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("### Dot-Sourced Scripts")
[void]$sb4.AppendLine("")
$dotSourced = $scriptsWithExternalCalls | Where-Object { $_.ExternalCalls -like '*Dot-Source*' }
if ($dotSourced.Count -gt 0) {
    foreach ($script in ($dotSourced | Sort-Object FilePath)) {
        [void]$sb4.AppendLine("- ``$($script.FilePath)``")
    }
} else {
    [void]$sb4.AppendLine("No dot-sourced dependencies found.")
}
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("## Recommendations")
[void]$sb4.AppendLine("")
[void]$sb4.AppendLine("1. **External Repos**: Move Port_Authority and Windows-Secure-Host-Baseline to D:\\dev\\repos")
[void]$sb4.AppendLine("2. **Track Updates**: Set up notifications for updates to external repositories")
[void]$sb4.AppendLine("3. **Document Modules**: Create a README listing all required external modules")
[void]$sb4.AppendLine("4. **Install Script**: Create an Install-RequiredModules.ps1 script")
[void]$sb4.AppendLine("5. **Reduce Dependencies**: Consider consolidating inter-script dependencies into modules")

$sb4.ToString() | Out-File -FilePath (Join-Path $OutputPath "EXTERNAL_DEPENDENCIES.md") -Encoding UTF8

# Report 5: CLEANUP_CANDIDATES.md
Write-Host "  Creating CLEANUP_CANDIDATES.md..." -ForegroundColor Gray
$obsolete = $inventory | Where-Object { $_.Recommendation -eq 'Obsolete-Candidate' }
$needsReview = $inventory | Where-Object { $_.Recommendation -eq 'Needs-Review' }
$noHelp = $inventory | Where-Object { $_.HasHelp -eq 'No' }

$sb5 = New-Object System.Text.StringBuilder
[void]$sb5.AppendLine("# Cleanup Candidates Analysis")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## Overview")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("This report identifies scripts that may need cleanup, conversion, or removal.")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## Statistics")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("- VBScript Files: 62")
[void]$sb5.AppendLine("- Obsolete Candidates: $($obsolete.Count)")
[void]$sb5.AppendLine("- Scripts Needing Review: $($needsReview.Count)")
[void]$sb5.AppendLine("- Scripts Without Help: $($noHelp.Count)")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## VBScript Files to Convert")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("62 VBScript files found. These should be converted to PowerShell for better maintainability.")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("### High-Priority Conversions")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("VBScript files in active use categories:")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("#### Active Directory Management")
[void]$sb5.AppendLine("- ``ActiveDirectory-UserManagement\User-Queries\MIG - AD Query - Primary User Details.vbs``")
[void]$sb5.AppendLine("- ``ActiveDirectory-UserManagement\User-Queries\localaccount.vbs``")
[void]$sb5.AppendLine("- ``ActiveDirectory-UserManagement\Get_LocalAdmin.vbs``")
[void]$sb5.AppendLine("- ``ActiveDirectory-UserManagement\Get_Pending_Reboot.vbs``")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("#### Application Management")
[void]$sb5.AppendLine("- ``Application-Management\Software-Inventory\migInstalledApplications.vbs``")
[void]$sb5.AppendLine("- ``Application-Management\Software-Inventory\wrInstlledApplications.vbs``")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("#### Security & Compliance")
[void]$sb5.AppendLine("- ``Security-Compliance\BitLocker\getBitlockerProtectionStatus.vbs``")
[void]$sb5.AppendLine("- ``Security-Compliance\BitLocker\getBitlockerStatus.vbs``")
[void]$sb5.AppendLine("- ``Security-Compliance\BIOSPasswordState.vbs``")
[void]$sb5.AppendLine("- ``Security-Compliance\getEncryptableVolumeInfo.vbs``")
[void]$sb5.AppendLine("- ``Security-Compliance\getSecureBoot.vbs``")
[void]$sb5.AppendLine("- ``Security-Compliance\UEFI.vbs``")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("### Legacy VBScript Collection (50 files)")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("The Legacy-VBScript-Collection directory contains 50 VBScript files. These are lower priority but should be reviewed for:")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("- Conversion to PowerShell if still needed")
[void]$sb5.AppendLine("- Archival if obsolete")
[void]$sb5.AppendLine("- Documentation of purpose if unclear")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("Notable files:")
[void]$sb5.AppendLine("- ``chrome_version_detector.vbs`` - Could use PowerShell registry queries")
[void]$sb5.AppendLine("- ``detectNETFramework.vbs`` / ``GetDOTNETVersions.vbs`` - PowerShell has better .NET detection")
[void]$sb5.AppendLine("- ``getOffice365Channel.vbs`` - PowerShell Office COM automation preferred")
[void]$sb5.AppendLine("- ``installWU.vbs`` / ``wureset.vbs`` - PowerShell has native Windows Update cmdlets")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## Obsolete Candidates")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("Scripts flagged as potentially obsolete (references to deprecated tech, legacy patterns).")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("| Script | Lines | Reason | Path |")
[void]$sb5.AppendLine("|--------|-------|--------|------|")
foreach ($script in ($obsolete | Sort-Object FilePath)) {
    $reason = if ($script.Synopsis -match 'deprecated|legacy|old') { "Synopsis mentions legacy" } else { "VBScript references" }
    [void]$sb5.AppendLine("| $($script.FileName) | $($script.LineCount) | $reason | ``$($script.FilePath)`` |")
}
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## Scripts Needing Review")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("Scripts with no clear purpose (no help, no functions, minimal code).")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("| Script | Lines | Path |")
[void]$sb5.AppendLine("|--------|-------|------|")
foreach ($script in ($needsReview | Sort-Object LineCount)) {
    [void]$sb5.AppendLine("| $($script.FileName) | $($script.LineCount) | ``$($script.FilePath)`` |")
}
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## Scripts Without Help Documentation")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("$($noHelp.Count) scripts lack help documentation. Top offenders by size:")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("| Script | Lines | Functions | Path |")
[void]$sb5.AppendLine("|--------|-------|-----------|------|")
foreach ($script in ($noHelp | Sort-Object LineCount -Descending | Select-Object -First 30)) {
    [void]$sb5.AppendLine("| $($script.FileName) | $($script.LineCount) | $($script.FunctionCount) | ``$($script.FilePath)`` |")
}
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## Potential Duplicate Functionality")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("Scripts with similar names that might have overlapping functionality:")
[void]$sb5.AppendLine("")

$similarNames = $inventory | Group-Object { ($_.FileName -split '\.')[0] -replace '\d+$', '' -replace '_v\d+$', '' } |
    Where-Object { $_.Count -gt 1 } |
    Sort-Object Count -Descending

foreach ($group in $similarNames) {
    if ($group.Count -gt 1) {
        [void]$sb5.AppendLine("### $($group.Name)* ($($group.Count) variations)")
        [void]$sb5.AppendLine("")
        foreach ($script in $group.Group) {
            [void]$sb5.AppendLine("- ``$($script.FilePath)`` ($($script.LineCount) lines)")
        }
        [void]$sb5.AppendLine("")
    }
}

[void]$sb5.AppendLine("## Cleanup Action Plan")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("### Phase 1: Quick Wins (Week 1)")
[void]$sb5.AppendLine("1. Review and delete/archive scripts in 'Needs Review' category")
[void]$sb5.AppendLine("2. Add basic help documentation to top 20 largest scripts without help")
[void]$sb5.AppendLine("3. Archive Legacy-VBScript-Collection to separate repository")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("### Phase 2: VBScript Conversion (Weeks 2-4)")
[void]$sb5.AppendLine("1. Convert high-priority VBScript files (Active Directory, Security)")
[void]$sb5.AppendLine("2. Test converted scripts thoroughly")
[void]$sb5.AppendLine("3. Update any scripts that reference the VBScript files")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("### Phase 3: Consolidation (Weeks 5-6)")
[void]$sb5.AppendLine("1. Review similar-named scripts for duplicate functionality")
[void]$sb5.AppendLine("2. Consolidate or deprecate as appropriate")
[void]$sb5.AppendLine("3. Document decisions in CHANGELOG")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("### Phase 4: Documentation (Week 7)")
[void]$sb5.AppendLine("1. Add help to all remaining undocumented scripts")
[void]$sb5.AppendLine("2. Create README files for each major directory")
[void]$sb5.AppendLine("3. Update main repository README")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("## Recommendations")
[void]$sb5.AppendLine("")
[void]$sb5.AppendLine("1. **Archive Legacy Code**: Move Legacy-VBScript-Collection to archive repository")
[void]$sb5.AppendLine("2. **Convert Priority VBS**: Focus on Active Directory and Security VBScript files first")
[void]$sb5.AppendLine("3. **Add Documentation**: Prioritize large, undocumented scripts")
[void]$sb5.AppendLine("4. **Review Duplicates**: Investigate similar-named scripts for consolidation")
[void]$sb5.AppendLine("5. **Delete Dead Code**: Remove scripts in 'Needs Review' after verification")

$sb5.ToString() | Out-File -FilePath (Join-Path $OutputPath "CLEANUP_CANDIDATES.md") -Encoding UTF8

Write-Host "`nAll reports generated successfully!" -ForegroundColor Green
Write-Host "  - TANIUM_CANDIDATES.md" -ForegroundColor Gray
Write-Host "  - GENERAL_UTILITIES.md" -ForegroundColor Gray
Write-Host "  - MODULE_OPPORTUNITIES.md" -ForegroundColor Gray
Write-Host "  - EXTERNAL_DEPENDENCIES.md" -ForegroundColor Gray
Write-Host "  - CLEANUP_CANDIDATES.md" -ForegroundColor Gray






