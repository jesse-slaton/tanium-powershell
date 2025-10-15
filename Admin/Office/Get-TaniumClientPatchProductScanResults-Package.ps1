function Get-TaniumClientPatchProductScanResults {
    [CmdletBinding()]
    param()
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchProductScanResultsFile = "$TaniumClientPatchDirectory\scans\tsw-product-applicability-results.txt"
    if (Test-Path $TaniumClientPatchProductScanResultsFile) {
        Write-Verbose "Tanium Client Patch product scan results exists"
        $TaniumClientPatchProductScanResults = Import-CSV -Path $TaniumClientPatchProductScanResultsFile -Delimiter '|'
        $TaniumClientPatchProductScanResults
    }
    else {
        Write-Warning "Tanium Client Patch product scan results do not exist"
    }
}