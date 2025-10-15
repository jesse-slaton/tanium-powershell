function Get-TaniumClientPatchScanStatistics {
    [cmdletbinding()]
    param (
        [string]$Path,
        [switch]$AllLogs
    )
    if ($Path) {
        $TaniumClientPatchLog = $Path
    }
    else {
        $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
        $TaniumClientPatchLog = "$TaniumClientPatchDirectory\patch0.log"
    }
    
    if (Test-Path -Path $TaniumClientPatchLog) {
        Write-Verbose 'Found Tanium client patch log'
        $TaniumClientPatchScanHistoryRaw = Select-String -Path $TaniumClientPatchLog -Pattern 'Scan completed in \d* seconds' | ForEach-Object { $_.Matches } | Select-Object -ExpandProperty Value
    }

    if ($AllLogs.IsPresent) {
        Write-Verbose 'Checking all patch logs'
        $TaniumClientPatchScanHistoryRaw = Search-TaniumClientPatchLog -Filter 'Scan completed in \d* seconds' -AllLogs  | ForEach-Object { $_.Matches } | Select-Object -ExpandProperty Value
    }

    if ($TaniumClientPatchScanHistoryRaw) {
        Write-Verbose "Found $($TaniumClientPatchScanHistoryRaw.Count) Patch scans"
        $TaniumClientPatchScanHistory = $TaniumClientPatchScanHistoryRaw | ForEach-Object { $_.Split()[3] }
        $TaniumClientPatchScanStatistics = $TaniumClientPatchScanHistory | Measure-Object -Sum -Average -Maximum -Minimum
        $TaniumClientPatchScanStatistics
    } 
    else {
        Write-Verbose 'No Tanium client Patch scan statistics found.'
    }
}