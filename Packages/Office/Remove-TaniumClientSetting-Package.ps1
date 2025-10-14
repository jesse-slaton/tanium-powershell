function Remove-TaniumClientSetting {
    [cmdletbinding()]
    param(
        $Setting,
        $Value
    )
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
            Write-Verbose "Removing Registry setting $DottedSettingName from $TaniumClientRegistryPath\$Path"
            Remove-ItemProperty -Path "$TaniumClientRegistryPath\$Path" -Name $DottedSettingName -ErrorAction Stop | Out-Null
        }
        else {
            Write-Verbose "Removing Registry setting $Setting from $TaniumClientRegistryPath"
            Remove-ItemProperty -Path $TaniumClientRegistryPath -Name $Setting -ErrorAction Stop | Out-Null
        }
    }
    catch {
        Write-Verbose "Unable to remove Tanium client setting $Setting"
    }
    finally {
        $Setting = Get-TaniumClientSetting -Setting $Setting
        $Setting
    }
}