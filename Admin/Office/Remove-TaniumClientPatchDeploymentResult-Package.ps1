function Remove-TaniumClientPatchDeploymentResult {
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]$Id
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchDeploymentResultsFile = "$TaniumClientPatchDirectory\deployments\deployment-results"
    $TaniumClientPatchDeploymentResults = Read-XmlFile -Path $TaniumClientPatchDeploymentResultsFile
    if ($TaniumClientPatchDeploymentResults) {
        Write-Verbose "Found deployment-Results file."
        $Deployment = $TaniumClientPatchDeploymentResults.DeploymentResults.Deployment | Where-Object -Filterscript { $_.Id -eq $Id }
        if ($Deployment) {
            $TaniumClientPatchDeploymentResults.DeploymentResults.RemoveChild($Deployment) | Out-Null
            Set-Content -Path $TaniumClientPatchDeploymentResultsFile -Value $TaniumClientPatchDeploymentResults.DeploymentResults.OuterXml -Force | Out-Null
            Write-Verbose "Removed Patch deployment results for ID $Id"
        }
        else {
            Write-Verbose "Unable to find deployment results for ID $Id"
        }
    }
    else {
        Write-Verbose "Deployment-Results file not found. Skipping removal."
    }
}