
function Get-TaniumClientPatchScanPriorities {
    [CmdletBinding()]
    param()
    Get-TaniumClientPatchData -DataType scan-configuration-priorities
}