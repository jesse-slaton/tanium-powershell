function Enable-TaniumClientDeploy {
    [cmdletbinding()]
    param (
        [switch]$RestartCx
    )
    Write-Verbose 'Disabling Tanium Client Deploy'
    Set-TaniumClientSetting -Setting DisableExtension_software_manager -Value 0
    if ($RestartCx) {
        Write-Verbose 'Restarting Tanium Client Cx'
        Restart-TaniumClientCx
    }
}