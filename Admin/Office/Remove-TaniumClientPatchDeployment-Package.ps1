function Remove-TaniumClientPatchDeployment {
    [CmdletBinding()]
    param (
        [parameter(mandatory = $true)]
        [string]$Id
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchDeploymentFile = "$TaniumClientPatchDirectory\deployments\configurations\deployment-$Id.xml"
    if (Test-Path -Path $TaniumClientPatchDeploymentFile) {
        Write-Verbose "Found $TaniumClientPatchDeploymentFile - Deleting now"
        Remove-Item -Path $TaniumClientPatchDeploymentFile
    }
    else {
        Write-Verbose "Unable to find $TaniumClientPatchDeploymentFile - Skipping"
    }
}