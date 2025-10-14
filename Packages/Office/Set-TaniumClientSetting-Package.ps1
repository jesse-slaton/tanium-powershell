function Set-TaniumClientSetting {
    [cmdletbinding()]
    param(
        [string]$Setting,
        $Value
    )
    $PowerShellType = Get-PowerShellType
    if ($PowerShellType -like '*Windows') {
        $TaniumClientRegistryPath = Get-TaniumClientRegistryPath
        try {
            if ($Setting -match '\.') {
                # Split the string and change . to \
                $DottedSetting = $Setting.Split('.')
                $DottedSettingLength = $DottedSetting.Length
                $DottedSettingName = $DottedSetting[$DottedSettingLength - 1]

                for ($i = 0; $i -le $DottedSettingLength - 2; $i++) {
                    $Path += "$($DottedSetting[$i])\"
                }
                Write-Verbose "Setting Registry setting $DottedSettingName from $TaniumClientRegistryPath\$Path"
                Set-ItemProperty -Path "$TaniumClientRegistryPath\$Path" -Name $DottedSettingName -Value $Value -ErrorAction Stop | Out-Null
            }
            else {
                Write-Verbose "Setting Registry setting $Setting from $TaniumClientRegistryPath"
                Set-ItemProperty -Path $TaniumClientRegistryPath -Name $Setting -Value $Value -ErrorAction Stop | Out-Null
            }
        }
        catch {
            Write-Verbose "Unable to set Tanium client setting $Setting"
        }
        finally {
            $Setting = Get-TaniumClientSetting -Setting $Setting
            $Setting
        }
    }
    else {
        Set-TaniumClientSettingCli -Setting $Setting -Value $Value
    }
}