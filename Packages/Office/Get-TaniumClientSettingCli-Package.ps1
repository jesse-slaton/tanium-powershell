function Get-TaniumClientSettingCli {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]$Setting
    )
    Write-Verbose "Getting $Setting via CLI"
    $TaniumClient = Get-TaniumClient
    if ($TaniumClient) {
        $TaniumClientSettingCli = Invoke-Command -ScriptBlock { & $TaniumClient config get $Setting 2>&1 }
        $TaniumClientSettingProperty = @{
            'Setting' = $Setting
            'Value'   = $TaniumClientSettingCli
        }
        $TaniumClientSetting = New-Object -TypeName PSObject -Property $TaniumClientSettingProperty
        $TaniumClientSetting
    }
    else {
        Write-Warning 'Unable to find the Tanium Client binary'
    }
}