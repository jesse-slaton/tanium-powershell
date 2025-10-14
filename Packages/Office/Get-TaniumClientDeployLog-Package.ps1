function Get-TaniumClientDeployLog {
    [CmdletBinding()]
    param(
        [int]$Last,
        [Alias('Tail')]
        [switch]$Wait,
        [string]$Filter
    )
    $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
    $DeployLog = "`"$TaniumClientDeployDirectory\logs\software-management.log`""
    $Command = "Get-Content -Path $DeployLog"
    if ($Last) {
        $Command = $Command + " -Last $Last"
    }
    if ($Wait.IsPresent) {
        $Command = $Command + " -Wait"
    }
    if ($Filter) {
        $Command = $Command + " | Select-String -Pattern `"$Filter`""
    }
    Write-Verbose "Executing $Command"
    Invoke-Expression $Command
}