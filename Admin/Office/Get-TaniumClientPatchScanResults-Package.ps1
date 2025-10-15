function Get-TaniumClientPatchScanResults {
    [CmdletBinding()]
    param()
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchScanResultsFile = "$TaniumClientPatchDirectory\scans\patch-scan-results.txt"
    if (Test-Path $TaniumClientPatchScanResultsFile) {
        Write-Verbose "Tanium Client Patch scan results exists"
        # Skip first line
        $TaniumClientPatchScanResults = Get-Content -Path $TaniumClientPatchScanResultsFile | Select-Object -Skip 1
        # Process header
        $Header = ($TaniumClientPatchScanResults | Select-Object -First 1).Replace('###scan-info###','').Split('|')
        $TaniumClientPatchScanResults = $TaniumClientPatchScanResults | Select-Object -Skip 1 | ConvertFrom-Csv -Delimiter '|' -Header $Header
        $TaniumClientPatchScanResults
    }
    else {
        Write-Warning "Tanium Client Patch scan results do not exist"
    }
}