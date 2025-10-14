<#
To Do:
 * check registry first with Windows, but then attempt CLI
#>
function Get-TaniumClientSetting {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        $Setting
    )
    $PowerShellType = Get-PowerShellType
    if ($PowerShellType -like '*Windows') {
        $TaniumClientRegistryPath = Get-TaniumClientRegistryPath
        if ($TaniumClientRegistryPath) {
            Write-Verbose "Attempting TaniumClient Registry to get $Setting"
            try {
                if ($Setting -match '\.') {
                    # Split the string and change . to \
                    $DottedSetting = $Setting.Split('.')
                    $DottedSettingLength = $DottedSetting.Length
                    $DottedSettingName = $DottedSetting[$DottedSettingLength - 1]

                    for ($i = 0; $i -le $DottedSettingLength - 2; $i++) {
                        $Path += "$($DottedSetting[$i])\"
                    }
                    Write-Verbose "Getting Registry setting $DottedSettingName from $TaniumClientRegistryPath\$Path"
                    $RegistrySetting = Get-ItemProperty -Path "$TaniumClientRegistryPath\$Path" -Name $DottedSettingName -ErrorAction Stop
                    $SettingProperties = @{
                        Setting = $Setting
                        Value   = $RegistrySetting.$DottedSettingName
                    }
                }
                else {
                    Write-Verbose "Getting Registry setting $Setting from $TaniumClientRegistryPath"
                    $RegistrySetting = Get-ItemProperty -Path $TaniumClientRegistryPath -Name $Setting -ErrorAction Stop
                    $SettingProperties = @{
                        Setting = $Setting
                        Value   = $RegistrySetting.$Setting
                    }
                }
            }
            catch {
                Write-Verbose "Unable to get Tanium client setting $Setting"
                $SettingProperties = @{
                    'Setting' = $Setting
                    'Value'   = 'Not Set'
                }
            }
            finally {
                $Setting = New-Object -TypeName PSObject -Property $SettingProperties
                $Setting
            }
        }
        else {
            Write-Warning 'Unable to find Tanium Client registry.'
        }
    }
    else {
        Write-Verbose "Attempting TaniumClient CLI to get $Setting"
        Get-TaniumClientSettingCli -Setting $Setting
    }
}