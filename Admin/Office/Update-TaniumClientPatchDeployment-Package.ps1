function Update-TaniumClientPatchDeployment {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Id,
        [parameter(Mandatory=$true)]
        [int]$DeploymentLengthInHours,
        [switch]$OverrideMaintenanceWindows,
        [switch]$OverrideDistributeOverTime
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $ConfigurationFilePath = "$TaniumClientPatchDirectory\deployments\configurations\deployment-$Id.xml"
    $TaniumClientPatchConfiguration = Read-XmlFile -Path $ConfigurationFilePath
    if ($TaniumClientPatchConfiguration) {
        $EndTime = (Get-Date ((Get-Date).AddHours($DeploymentLengthInHours)) -format "yyyy-MM-dd HH:mm:ss").toString()
        Write-Verbose "Setting deployment $Id end time to $Endtime"
        $TaniumClientPatchConfiguration.Deployment.endTime = $EndTime
        if ($OverrideMaintenanceWindows.IsPresent) {
            Write-Verbose "Overriding maintenance windows for deployment $Id"
            $TaniumClientPatchConfiguration.Deployment.overrideMaintenanceWindows = 'true'
        }
        if ($OverrideDistributeOverTime.IsPresent) {
            Write-Verbose "Overriding distribute over time for deployment $Id"
            $TaniumClientPatchConfiguration.Deployment.distributeOverTimeMinutes = '0'
        }
        Write-Verbose "Updating Deployment $Id."
        Set-Content -Path $ConfigurationFilePath -Value $TaniumClientPatchConfiguration.Deployment.OuterXml -Force | Out-Null
        # Remove-TaniumClientPatchDeploymentStatus -Id $Id
    }
    else {
        Write-Warning "Unable to find deployment $Id at $ConfigurationFilePath"
    }
}