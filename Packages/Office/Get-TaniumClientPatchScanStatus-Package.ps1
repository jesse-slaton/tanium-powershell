function Get-TaniumClientPatchScanStatus {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$Id
    )
    if ($Id) {
        Get-TaniumClientPatchData -DataType scan-statuses | Where-Object -FilterScript {$_.id -eq $Id}
    }
    else {
        Get-TaniumClientPatchData -DataType scan-statuses
    }
}