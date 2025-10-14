function Set-TaniumClientSettingCli {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]$Setting,
        $Value
    )
    Write-Verbose "Setting $Setting via CLI"
    $TaniumClient = Get-TaniumClient
    if ($TaniumClient) {
        Invoke-Command -ScriptBlock { & $TaniumClient config set $Setting $Value 2>&1 }
        Get-TaniumClientSetting -Setting $Setting
    }
    else {
        Write-Warning 'Unable to find the Tanium Client binary'
    }
}