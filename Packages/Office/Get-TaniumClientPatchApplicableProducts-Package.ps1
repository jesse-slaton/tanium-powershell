function Get-TaniumClientPatchApplicableProducts {
    [CmdletBinding()]
    param()
    Get-TaniumClientPatchProductScanResults | Where-Object -FilterScript {$_.Applicable -eq $true}
}