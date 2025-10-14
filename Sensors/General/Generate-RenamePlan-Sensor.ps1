#Requires -Version 5.1
<#
.SYNOPSIS
    Generates a rename plan for Tanium scripts following the new naming convention

.DESCRIPTION
    Analyzes existing Tanium scripts and proposes new names following the standard:
    - Sensors: Get-<Noun>-Sensor.ps1 or Test-<Noun>-Sensor.ps1
    - Packages: <Verb>-<Noun>-Package.ps1
    - Client Management: <Verb>-TaniumClient<Noun>-<Type>.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InventoryCsv = "D:\Dev\PowerShell-Projects\INVENTORY.csv",

    [Parameter()]
    [string]$OutputCsv = "D:\Dev\PowerShell-Projects\RENAME_PLAN.csv"
)

Write-Host "Loading inventory data..." -ForegroundColor Cyan
$inventory = Import-Csv -Path $InventoryCsv

Write-Host "Analyzing Tanium scripts..." -ForegroundColor Cyan

# Get all Tanium-related scripts
$taniumScripts = $inventory | Where-Object {
    $_.Recommendation -eq 'Tanium-Sensor' -or
    $_.Recommendation -eq 'Tanium-Package' -or
    ($_.TaniumIndicators -ne '' -and $_.TaniumIndicators -ne $null)
}

Write-Host "Found $($taniumScripts.Count) Tanium-related scripts" -ForegroundColor Green

$renamePlan = @()

function Get-ProposedName {
    param(
        [string]$CurrentName,
        [string]$Recommendation,
        [string]$TaniumIndicators,
        [string]$Synopsis,
        [int]$FunctionCount
    )

    # Remove .ps1 extension for processing
    $baseName = $CurrentName -replace '\.ps1$', ''

    # Check if it's managing Tanium Client itself
    $isTaniumClient = $baseName -match '^(Get|Set|Start|Stop|Restart|Enable|Disable|New|Remove|Test|Update|Sync|Read|Write|Search|Send|Invoke|Add|Disable|Enable|Save)-TaniumClient'

    # Determine if it's a sensor or package
    $isSensor = $Recommendation -eq 'Tanium-Sensor'
    $isPackage = $Recommendation -eq 'Tanium-Package'

    # If unclear, use indicators and name patterns
    if (-not $isSensor -and -not $isPackage) {
        if ($TaniumIndicators -match 'Sensor-Pattern|Simple-Sensor') {
            $isSensor = $true
        } elseif ($baseName -match '^(Get|Test|Find|Measure|Read|Search)-' -and $TaniumIndicators -notmatch 'SYSTEM-Context') {
            # Read-only verbs suggest sensor
            $isSensor = $true
        } else {
            # State-changing or unclear - assume package
            $isPackage = $true
        }
    }

    # Extract verb and noun from current name
    if ($baseName -match '^(Get|Set|Start|Stop|Restart|Test|Enable|Disable|Install|Remove|Uninstall|Update|New|Invoke|Add|Clear|Copy|Move|Find|Measure|Read|Write|Export|Import|Send|Receive|Search|Sync|Save|Watch|Repair)-(.+)') {
        $verb = $Matches[1]
        $noun = $Matches[2]
    } else {
        # No standard verb - keep original name but add suffix
        # Don't try to add a verb to names that don't have one
        $needsSuffix = if ($isSensor) { '-Sensor' } else { '-Package' }
        return "$baseName$needsSuffix.ps1"
    }

    # Clean up the noun
    # Remove existing Tanium suffixes/prefixes that are redundant
    $noun = $noun -replace '^Tanium', ''
    $noun = $noun -replace 'Tanium$', ''
    $noun = $noun -replace 'ForTanium$', ''
    $noun = $noun -replace 'ToTanium$', ''

    # Special handling for TaniumClient scripts
    if ($isTaniumClient) {
        # Already has TaniumClient in name, just add suffix
        $suffix = if ($isSensor) { '-Sensor' } else { '-Package' }

        # Check if it already has the suffix
        if ($baseName -notmatch '-(Sensor|Package)$') {
            return "$baseName$suffix.ps1"
        } else {
            return $CurrentName  # Already correct
        }
    }

    # Adjust verb for sensors (must be Get or Test)
    if ($isSensor) {
        if ($verb -notin @('Get', 'Test', 'Find', 'Measure', 'Read', 'Search')) {
            # Change action verbs to Get for sensors
            if ($verb -in @('Start', 'Stop', 'Restart', 'Enable', 'Disable', 'Set', 'Install', 'Remove', 'Update')) {
                $verb = 'Get'
            }
        }
    }

    # Build proposed name
    $suffix = if ($isSensor) { '-Sensor' } else { '-Package' }

    # Check if already has correct suffix
    if ($baseName -match '-(Sensor|Package)$') {
        # Already has a suffix
        $existingSuffix = $Matches[1]
        if (($existingSuffix -eq 'Sensor' -and $isSensor) -or ($existingSuffix -eq 'Package' -and $isPackage)) {
            return $CurrentName  # Already correct
        } else {
            # Wrong suffix, replace it
            $baseWithoutSuffix = $baseName -replace '-(Sensor|Package)$', ''
            return "$baseWithoutSuffix$suffix.ps1"
        }
    }

    # Construct new name
    $proposedName = "$verb-$noun$suffix.ps1"

    return $proposedName
}

function Get-RenameReason {
    param(
        [string]$CurrentName,
        [string]$ProposedName
    )

    if ($CurrentName -eq $ProposedName) {
        return "Already follows convention"
    }

    $reasons = @()

    # Check for missing suffix
    if ($CurrentName -notmatch '-(Sensor|Package)\.ps1$' -and $ProposedName -match '-(Sensor|Package)\.ps1$') {
        $suffix = if ($ProposedName -match '-Sensor\.ps1$') { 'Sensor' } else { 'Package' }
        $reasons += "Add -$suffix suffix"
    }

    # Check for wrong suffix
    if ($CurrentName -match '-Sensor\.ps1$' -and $ProposedName -match '-Package\.ps1$') {
        $reasons += "Change Sensor to Package suffix"
    }
    if ($CurrentName -match '-Package\.ps1$' -and $ProposedName -match '-Sensor\.ps1$') {
        $reasons += "Change Package to Sensor suffix"
    }

    # Check for Tanium in name
    if ($CurrentName -match 'Tanium' -and $ProposedName -notmatch 'TaniumClient' -and $ProposedName -match 'Tanium' -eq $false) {
        $reasons += "Remove redundant 'Tanium' from name"
    }

    # Check for verb change
    $currentVerb = if ($CurrentName -match '^([A-Z][a-z]+)-') { $Matches[1] } else { $null }
    $proposedVerb = if ($ProposedName -match '^([A-Z][a-z]+)-') { $Matches[1] } else { $null }

    if ($currentVerb -and $proposedVerb -and $currentVerb -ne $proposedVerb) {
        $reasons += "Change verb from $currentVerb to $proposedVerb"
    }

    # Check for missing verb
    if (-not $currentVerb -and $proposedVerb) {
        $reasons += "Add standard verb prefix"
    }

    if ($reasons.Count -eq 0) {
        return "Improve naming clarity"
    }

    return ($reasons -join '; ')
}

function Get-RenamePriority {
    param(
        [string]$CurrentName,
        [string]$ProposedName,
        [int]$FunctionCount,
        [string]$HasHelp
    )

    if ($CurrentName -eq $ProposedName) {
        return "None"
    }

    # High priority: No suffix, wrong suffix, or commonly used
    if ($CurrentName -notmatch '-(Sensor|Package)\.ps1$') {
        return "High"
    }

    if (($CurrentName -match '-Sensor\.ps1$' -and $ProposedName -match '-Package\.ps1$') -or
        ($CurrentName -match '-Package\.ps1$' -and $ProposedName -match '-Sensor\.ps1$')) {
        return "High"
    }

    # Medium priority: Has documentation or multiple functions
    if ($HasHelp -eq 'Yes' -or $FunctionCount -gt 2) {
        return "Medium"
    }

    return "Low"
}

Write-Host "Generating rename proposals..." -ForegroundColor Cyan

foreach ($script in $taniumScripts) {
    $currentName = $script.FileName
    $proposedName = Get-ProposedName -CurrentName $currentName -Recommendation $script.Recommendation -TaniumIndicators $script.TaniumIndicators -Synopsis $script.Synopsis -FunctionCount ([int]$script.FunctionCount)

    $reason = Get-RenameReason -CurrentName $currentName -ProposedName $proposedName
    $priority = Get-RenamePriority -CurrentName $currentName -ProposedName $proposedName -FunctionCount ([int]$script.FunctionCount) -HasHelp $script.HasHelp

    $renamePlan += [PSCustomObject]@{
        Priority = $priority
        CurrentName = $currentName
        ProposedName = $proposedName
        CurrentPath = $script.FilePath
        ProposedPath = $script.FilePath -replace [regex]::Escape($currentName), $proposedName
        Type = $script.Recommendation
        NeedsRename = if ($currentName -eq $proposedName) { 'No' } else { 'Yes' }
        Reason = $reason
        LineCount = $script.LineCount
        FunctionCount = $script.FunctionCount
        HasHelp = $script.HasHelp
        Synopsis = $script.Synopsis
    }
}

Write-Host "Exporting rename plan..." -ForegroundColor Cyan
$renamePlan | Sort-Object Priority, CurrentName | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

# Generate statistics
$needsRename = ($renamePlan | Where-Object { $_.NeedsRename -eq 'Yes' }).Count
$alreadyCorrect = ($renamePlan | Where-Object { $_.NeedsRename -eq 'No' }).Count
$highPriority = ($renamePlan | Where-Object { $_.Priority -eq 'High' }).Count
$mediumPriority = ($renamePlan | Where-Object { $_.Priority -eq 'Medium' }).Count
$lowPriority = ($renamePlan | Where-Object { $_.Priority -eq 'Low' }).Count

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RENAME PLAN SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tanium Scripts: $($renamePlan.Count)" -ForegroundColor White
Write-Host "Need Rename: $needsRename" -ForegroundColor Yellow
Write-Host "Already Correct: $alreadyCorrect" -ForegroundColor Green
Write-Host "`nRename Priority:" -ForegroundColor Yellow
Write-Host "  High Priority: $highPriority" -ForegroundColor Red
Write-Host "  Medium Priority: $mediumPriority" -ForegroundColor Yellow
Write-Host "  Low Priority: $lowPriority" -ForegroundColor White
Write-Host "  No Rename Needed: $alreadyCorrect" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Rename plan exported to: $OutputCsv" -ForegroundColor Green

# Show some examples
Write-Host "`nExample High-Priority Renames:" -ForegroundColor Cyan
$renamePlan | Where-Object { $_.Priority -eq 'High' } | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.CurrentName) -> $($_.ProposedName)" -ForegroundColor Yellow
}
