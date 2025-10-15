function Remove-TaniumClientPatchScanResults {
    [CmdletBinding()]
    param( )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchScanResults = "$TaniumClientPatchDirectory\scans\patch-scan-results.txt"
    if (Test-Path $TaniumClientPatchScanResults) {
        Write-Verbose "Found scan results file, removing."
        Remove-Item -Path $TaniumClientPatchScanResults | Out-Null
    }
    else {
        Write-Verbose "patch-scan-results.txt file not found. Skipping removal."
    }
}