function Get-TaniumClientPatchApplicablePatches {
    [CmdletBinding()]
    param()
    Get-TaniumClientPatchScanResults | Where-Object -FilterScript {$_.IsInstalled -eq $false}
}