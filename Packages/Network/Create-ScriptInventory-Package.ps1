#Requires -Version 5.1
<#
.SYNOPSIS
    Creates a comprehensive inventory of PowerShell scripts in the repository

.DESCRIPTION
    This script analyzes all PowerShell scripts (.ps1, .psm1, .psd1) in the repository
    and generates a detailed inventory CSV with metadata, analysis, and recommendations.

.PARAMETER RootPath
    The root directory to analyze (default: D:\Dev\PowerShell-Projects)

.PARAMETER OutputCsv
    Path to the output CSV file (default: INVENTORY.csv in root)

.PARAMETER SummaryOutput
    Path to the summary markdown file (default: INVENTORY-SUMMARY.md in root)

.EXAMPLE
    .\Create-ScriptInventory.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RootPath = "D:\Dev\PowerShell-Projects",

    [Parameter()]
    [string]$OutputCsv = "D:\Dev\PowerShell-Projects\INVENTORY.csv",

    [Parameter()]
    [string]$SummaryOutput = "D:\Dev\PowerShell-Projects\INVENTORY-SUMMARY.md"
)

function Get-ScriptHelp {
    param([string]$Content)
    if ($Content -match '(?s)<#.*?\.SYNOPSIS.*?#>') {
        if ($Content -match '(?s)\.DESCRIPTION\s+(.*?)(?=\s*\.|#>)') {
            return 'Yes'
        }
        return 'Partial'
    }
    return 'No'
}

function Get-HasWhatIf {
    param([string]$Content)
    if ($Content -match '\[CmdletBinding\([^\)]*SupportsShouldProcess') {
        return 'Yes'
    }
    if ($Content -match 'param\s*\([^)]*\[switch\]\s*\$WhatIf') {
        return 'Yes'
    }
    return 'No'
}

function Get-HasPesterTests {
    param([string]$FilePath)
    $directory = Split-Path $FilePath -Parent
    $fileName = Split-Path $FilePath -Leaf
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $testPatterns = @(
        "$baseName.Tests.ps1",
        "$baseName.Test.ps1",
        "Tests\$baseName.Tests.ps1",
        "Test\$baseName.Tests.ps1"
    )
    foreach ($pattern in $testPatterns) {
        if (Test-Path (Join-Path $directory $pattern)) {
            return 'Yes'
        }
    }
    return 'No'
}

function Get-FunctionCount {
    param([string]$Content)
    $functionMatches = [regex]::Matches($Content, '^\s*function\s+[\w-]+', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    return $functionMatches.Count
}

function Get-ExternalCalls {
    param([string]$Content)
    $externalCalls = @()
    if ($Content -match '\.\s+[''"]?\.?[\\/]?([^\s''"]+\.ps1)[''"]?') {
        $externalCalls += 'Dot-Source'
    }
    if ($Content -match '&\s+[''"]?\.?[\\/]?([^\s''"]+\.ps1)[''"]?') {
        $externalCalls += 'Call-Operator'
    }
    if ($Content -match 'Invoke-Expression|iex\s') {
        $externalCalls += 'Invoke-Expression'
    }
    if ($Content -match 'Start-Process|Start-Job') {
        $externalCalls += 'Process/Job'
    }
    return ($externalCalls | Select-Object -Unique) -join '; '
}

function Get-RequiredModules {
    param([string]$Content)
    $modules = @()
    if ($Content -match '#Requires\s+-Modules?\s+([\w\.,\s]+)') {
        $modules += $Matches[1].Split(',').Trim()
    }
    $importMatches = [regex]::Matches($Content, 'Import-Module\s+[''"]?(\w+)[''"]?')
    foreach ($match in $importMatches) {
        $modules += $match.Groups[1].Value
    }
    return ($modules | Select-Object -Unique) -join '; '
}

function Get-PipeDelimitedOutput {
    param([string]$Content)
    if ($Content -match 'Write-Output.*\|' -or $Content -match '".*\|.*"' -or $Content -match "'.* \| .*'") {
        return 'Yes'
    }
    if ($Content -match 'Export-Csv.*-Delimiter\s+[''"]?\|') {
        return 'Yes'
    }
    return 'No'
}

function Get-TaniumIndicators {
    param([string]$Content)
    $indicators = @()
    if ($Content -match 'NT AUTHORITY\\SYSTEM' -or $Content -match 'SYSTEM\s+context') {
        $indicators += 'SYSTEM-Context'
    }
    if ($Content -match 'WOW64|Sysnative|Wow6432Node') {
        $indicators += 'WOW64-Handling'
    }
    if ($Content -match 'Tanium') {
        $indicators += 'Tanium-Named'
    }
    if ($Content -match 'Get-ItemProperty.*HKLM|Registry::HKEY') {
        $indicators += 'Registry-Read'
    }
    if (($Content -match 'Write-Output|Write-Host') -and ($Content -notmatch 'Set-|New-|Remove-|Write-') -and ($Content.Length -lt 5000)) {
        $indicators += 'Simple-Sensor'
    }
    $getCmdlets = ([regex]::Matches($Content, '\bGet-\w+')).Count
    $setCmdlets = ([regex]::Matches($Content, '\b(Set-|New-|Remove-)\w+')).Count
    if ($getCmdlets -gt 3 -and $setCmdlets -eq 0) {
        $indicators += 'Sensor-Pattern'
    }
    return ($indicators | Select-Object -Unique) -join '; '
}

function Get-ScriptSynopsis {
    param([string]$Content)
    if ($Content -match '(?s)\.SYNOPSIS\s+(.*?)(?=\s*\.|\s*#>)') {
        $synopsis = $Matches[1].Trim() -replace '\s+', ' '
        if ($synopsis.Length -gt 200) {
            $synopsis = $synopsis.Substring(0, 197) + '...'
        }
        return $synopsis
    }
    return ''
}

function Get-Recommendation {
    param([string]$Content, [string]$TaniumIndicators, [int]$FunctionCount, [string]$Synopsis)
    if ($TaniumIndicators -match 'Tanium-Named|Tanium-Registry') {
        if ($TaniumIndicators -match 'Sensor-Pattern|Simple-Sensor') {
            return 'Tanium-Sensor'
        }
        return 'Tanium-Package'
    }
    if ($FunctionCount -ge 3) {
        return 'General-Utility'
    }
    if ($Content -match 'Export-ModuleMember|\.psm1') {
        return 'Module'
    }
    if ($Synopsis -eq '' -and $FunctionCount -eq 0 -and $Content.Length -lt 500) {
        return 'Needs-Review'
    }
    if ($Content -match 'VBScript|\.vbs|WScript' -or $Synopsis -match 'deprecated|legacy|old') {
        return 'Obsolete-Candidate'
    }
    return 'General-Utility'
}

Write-Host "Starting PowerShell script inventory..." -ForegroundColor Cyan
Write-Host "Root path: $RootPath" -ForegroundColor Gray

Write-Host "`nScanning for PowerShell files..." -ForegroundColor Cyan
$psFiles = Get-ChildItem -Path $RootPath -Include *.ps1,*.psm1,*.psd1 -Recurse -File -ErrorAction SilentlyContinue
Write-Host "Found $($psFiles.Count) PowerShell files" -ForegroundColor Green

Write-Host "`nScanning for VBScript files..." -ForegroundColor Cyan
$vbsFiles = Get-ChildItem -Path $RootPath -Include *.vbs,*.vbe -Recurse -File -ErrorAction SilentlyContinue
Write-Host "Found $($vbsFiles.Count) VBScript files" -ForegroundColor Green

Write-Host "`nIdentifying cloned external repositories..." -ForegroundColor Cyan
$externalRepos = @()
$gitDirs = Get-ChildItem -Path $RootPath -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName ".git") }

foreach ($gitDir in $gitDirs) {
    $hasLicense = Test-Path (Join-Path $gitDir.FullName "LICENSE*")
    if ($hasLicense) {
        $externalRepos += [PSCustomObject]@{
            Repository = $gitDir.Name
            FullPath = $gitDir.FullName
        }
    }
}

Write-Host "Found $($externalRepos.Count) potential external repositories" -ForegroundColor Green

Write-Host "`nAnalyzing PowerShell scripts..." -ForegroundColor Cyan
$inventory = @()
$processedCount = 0

foreach ($file in $psFiles) {
    $processedCount++
    if ($processedCount % 50 -eq 0) {
        Write-Host "  Processed $processedCount / $($psFiles.Count) files..." -ForegroundColor Gray
    }
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        $lineCount = (Get-Content $file.FullName -ErrorAction Stop).Count
        $relativePath = $file.FullName.Replace($RootPath, '').TrimStart('\')

        $taniumIndicators = Get-TaniumIndicators -Content $content
        $functionCount = Get-FunctionCount -Content $content
        $synopsis = Get-ScriptSynopsis -Content $content

        $inventory += [PSCustomObject]@{
            FilePath = $relativePath
            FileName = $file.Name
            LineCount = $lineCount
            HasHelp = Get-ScriptHelp -Content $content
            HasWhatIf = Get-HasWhatIf -Content $content
            HasPesterTests = Get-HasPesterTests -FilePath $file.FullName
            FunctionCount = $functionCount
            ExternalCalls = Get-ExternalCalls -Content $content
            RequiredModules = Get-RequiredModules -Content $content
            PipeDelimitedOutput = Get-PipeDelimitedOutput -Content $content
            TaniumIndicators = $taniumIndicators
            Synopsis = $synopsis
            Recommendation = Get-Recommendation -Content $content -TaniumIndicators $taniumIndicators -FunctionCount $functionCount -Synopsis $synopsis
        }
    }
    catch {
        Write-Host "  Error processing $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Host "`nExporting inventory to CSV..." -ForegroundColor Cyan
$inventory | Sort-Object FilePath | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
Write-Host "Inventory exported to: $OutputCsv" -ForegroundColor Green

Write-Host "`nGenerating summary statistics..." -ForegroundColor Cyan
$stats = @{
    TotalScripts = $inventory.Count
    TotalLines = ($inventory | Measure-Object -Property LineCount -Sum).Sum
    WithHelp = ($inventory | Where-Object { $_.HasHelp -eq 'Yes' }).Count
    WithWhatIf = ($inventory | Where-Object { $_.HasWhatIf -eq 'Yes' }).Count
    WithTests = ($inventory | Where-Object { $_.HasPesterTests -eq 'Yes' }).Count
    TaniumSensors = ($inventory | Where-Object { $_.Recommendation -eq 'Tanium-Sensor' }).Count
    TaniumPackages = ($inventory | Where-Object { $_.Recommendation -eq 'Tanium-Package' }).Count
    GeneralUtilities = ($inventory | Where-Object { $_.Recommendation -eq 'General-Utility' }).Count
    NeedsReview = ($inventory | Where-Object { $_.Recommendation -eq 'Needs-Review' }).Count
    ObsoleteCandidates = ($inventory | Where-Object { $_.Recommendation -eq 'Obsolete-Candidate' }).Count
    VBScriptFiles = $vbsFiles.Count
    ExternalRepos = $externalRepos.Count
}

$duplicates = $inventory | Group-Object -Property FileName | Where-Object { $_.Count -gt 1 }

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# PowerShell Script Inventory Summary")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Overview Statistics")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Total PowerShell Scripts: $($stats.TotalScripts)")
[void]$sb.AppendLine("Total Lines of Code: $($stats.TotalLines)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Documentation Coverage")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Scripts with Help: $($stats.WithHelp)")
[void]$sb.AppendLine("Scripts with WhatIf Support: $($stats.WithWhatIf)")
[void]$sb.AppendLine("Scripts with Pester Tests: $($stats.WithTests)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Script Categories")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Tanium Sensors: $($stats.TaniumSensors)")
[void]$sb.AppendLine("Tanium Packages: $($stats.TaniumPackages)")
[void]$sb.AppendLine("General Utilities: $($stats.GeneralUtilities)")
[void]$sb.AppendLine("Needs Review: $($stats.NeedsReview)")
[void]$sb.AppendLine("Obsolete Candidates: $($stats.ObsoleteCandidates)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Other Files")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("VBScript Files: $($stats.VBScriptFiles)")
[void]$sb.AppendLine("External Repositories: $($stats.ExternalRepos)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## VBScript Files")
[void]$sb.AppendLine("")
if ($vbsFiles.Count -gt 0) {
    foreach ($vbsFile in $vbsFiles) {
        [void]$sb.AppendLine("- $($vbsFile.FullName.Replace($RootPath, '').TrimStart('\'))")
    }
} else {
    [void]$sb.AppendLine("No VBScript files found.")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## External Repositories")
[void]$sb.AppendLine("")
if ($externalRepos.Count -gt 0) {
    foreach ($repo in $externalRepos) {
        [void]$sb.AppendLine("- $($repo.Repository): $($repo.FullPath.Replace($RootPath, '').TrimStart('\'))")
    }
} else {
    [void]$sb.AppendLine("No external repositories identified.")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Potential Duplicates")
[void]$sb.AppendLine("")
if ($duplicates.Count -gt 0) {
    foreach ($dup in $duplicates) {
        [void]$sb.AppendLine("$($dup.Name) found $($dup.Count) times:")
        foreach ($item in $dup.Group) {
            [void]$sb.AppendLine("  - $($item.FilePath)")
        }
    }
} else {
    [void]$sb.AppendLine("No duplicate script names found.")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Top 10 Largest Scripts")
[void]$sb.AppendLine("")
$top10 = $inventory | Sort-Object -Property LineCount -Descending | Select-Object -First 10
foreach ($script in $top10) {
    [void]$sb.AppendLine("$($script.FileName) - $($script.LineCount) lines")
}

$sb.ToString() | Out-File -FilePath $SummaryOutput -Encoding UTF8
Write-Host "Summary exported to: $SummaryOutput" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "INVENTORY SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Scripts: $($stats.TotalScripts)" -ForegroundColor White
Write-Host "Total Lines: $($stats.TotalLines)" -ForegroundColor White
Write-Host "With Help: $($stats.WithHelp)" -ForegroundColor White
Write-Host "With WhatIf: $($stats.WithWhatIf)" -ForegroundColor White
Write-Host "With Tests: $($stats.WithTests)" -ForegroundColor White
Write-Host "`nCategories:" -ForegroundColor Yellow
Write-Host "  Tanium Sensors: $($stats.TaniumSensors)" -ForegroundColor White
Write-Host "  Tanium Packages: $($stats.TaniumPackages)" -ForegroundColor White
Write-Host "  General Utilities: $($stats.GeneralUtilities)" -ForegroundColor White
Write-Host "  Needs Review: $($stats.NeedsReview)" -ForegroundColor White
Write-Host "  Obsolete Candidates: $($stats.ObsoleteCandidates)" -ForegroundColor White
Write-Host "`nOther Files:" -ForegroundColor Yellow
Write-Host "  VBScript Files: $($stats.VBScriptFiles)" -ForegroundColor White
Write-Host "  External Repos: $($stats.ExternalRepos)" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "Inventory generation complete!" -ForegroundColor Green
Write-Host "  CSV: $OutputCsv" -ForegroundColor Gray
Write-Host "  Summary: $SummaryOutput" -ForegroundColor Gray
