function Search-TaniumClientDeployLog {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Filter,
        [switch]$AllLogs
    )
    $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
    if ($AllLogs.IsPresent) {
        $DeployLog = "$TaniumClientDeployDirectory\logs\software-management.log*"
    }
    else {
        $DeployLog = "$TaniumClientDeployDirectory\logs\software-management.log"
    }
    Select-String -Path $DeployLog -Pattern $Filter
}