function Get-TaniumClientPatchScanAge {
    [cmdletbinding()]
    param ()
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchScanResultsAge = Get-TaniumClientFileModificationTime -Path "$TaniumClientPatchDirectory\scans\patch-scan-results.txt"
    if ($TaniumClientPatchScanResultsAge) {
        $TaniumClientPatchScanAgeProperties = @{
            'LastScanTime' = $TaniumClientPatchScanResultsAge
            'Days'         = [int]((Get-Date) - $TaniumClientPatchScanResultsAge).TotalDays
        }
        $TaniumClientPatchScanAge = New-Object -TypeName PSObject -Property $TaniumClientPatchScanAgeProperties
        $TaniumClientPatchScanAge
    }
    else {
        Write-Warning "No Patch scan results exists."
    }
}