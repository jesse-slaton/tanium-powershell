function Get-TaniumClientPatchDeploymentStatus {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$Id
    )
    if ($Id) {
        Get-TaniumClientPatchData -DataType deployment-statuses | Where-Object -FilterScript {$_.id -eq $Id}
    }
    else {
        Get-TaniumClientPatchData -DataType deployment-statuses
    }
}