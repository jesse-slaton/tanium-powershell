function Get-TaniumClientPatchDeploymentResult {
    [CmdletBinding()]
    param(
        [string]$Id
    )
    if ($Id) {
        Get-TaniumClientPatchData -DataType deployment-results | Where-Object -FilterScript { $_.id -eq $Id }
    }
    else {
        Get-TaniumClientPatchData -DataType deployment-results
    }   
}