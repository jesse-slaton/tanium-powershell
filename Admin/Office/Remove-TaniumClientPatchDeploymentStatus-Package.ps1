function Remove-TaniumClientPatchDeploymentStatus {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Id
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchDeploymentStatusesFile = "$TaniumClientPatchDirectory\deployments\deployment-statuses"
    $TaniumClientPatchDeploymentStatuses = Read-XmlFile -Path $TaniumClientPatchDeploymentStatusesFile
    if ($TaniumClientPatchDeploymentStatuses) {
        Write-Verbose "Found deployment-statuses file."
        $Deployment = $TaniumClientPatchDeploymentStatuses.DeploymentStatuses.Deployment | Where-Object -Filterscript {$_.Id -eq $Id}
        if ($Deployment) {
            $TaniumClientPatchDeploymentStatuses.DeploymentStatuses.RemoveChild($Deployment) | Out-Null
            Set-Content -Path $TaniumClientPatchDeploymentStatusesFile -Value $TaniumClientPatchDeploymentStatuses.DeploymentStatuses.OuterXml -Force | Out-Null
            Write-Verbose "Removed Patch deployment status for ID $Id"
        }
        else {
            Write-Verbose "Unable to find deployment status for ID $Id"
        }
        
    }
    else {
        Write-Verbose "Deployment-statuses file not found. Skipping removal."
    }
}