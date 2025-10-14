function Get-TaniumClientHardening {
    [cmdletbinding()]
    param(
        [ValidateSet('ControlPanel', 'Service', 'FileSystem')]
        [string[]]$Configuration = @('ControlPanel', 'Service', 'FileSystem')
    )
    switch ($Configuration) {
        'ControlPanel' {
            Write-Verbose "Checking $Configuration hardening"
            $UninstallRegistryPath = Get-TaniumClientUninstallRegistry
            try {
                $Setting = 'SystemComponent'
                $RegistrySetting = Get-ItemProperty -Path $UninstallRegistryPath -Name $Setting -ErrorAction Stop
                if ($RegistrySetting.$Setting -eq 1) {
                    $ControlPanelHardening = $true
                }
                else {
                    $ControlPanelHardening = $false
                }
            }
            catch {
                Write-Verbose "Control Panel Hardening registry key not found."
                $ControlPanelHardening = $false
            }
            $TaniumClientHardeningProperties += @{
                ControlPanel = $ControlPanelHardening
            }
        }
        'Service' {
            try {
                $TaniumClientService = Get-Service -Name 'Tanium Client' -ErrorAction Stop
                if ($TaniumClientService) {
                    $cmd = "sc.exe sdshow 'Tanium Client'"
                    $TaniumClientServicePermissions = (Invoke-Expression $cmd)[1]
                    Write-Verbose "Service permissions $TaniumClientServicePermissions"
                    switch ($TaniumClientServicePermissions) {
                        "D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" {
                            Write-Verbose "Service Control Restricted to Administrators"
                            $ServiceHardening = "Service Control Restricted to Administrators"
                        }
                        "D:(A;;CCDCLCSWRPWPDTLOCRSDRCWO;;;SY)(A;;CCLCSWLOCRRC;;;AU)" {
                            Write-Verbose "Service Control Restricted to Local SYSTEM"
                            $ServiceHardening = "Service Control Restricted to Local SYSTEM"
                        }
                        "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCLCSWLOCRRC;;;AU)" {
                            Write-Verbose "Service Control Restricted to Local SYSTEM (Deprecated)"
                            $ServiceHardening = "Service Control Restricted to Local SYSTEM (Deprecated)"
                        }
                        "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)" {
                            Write-Verbose "Service Control is set to default permissions"
                            $ServiceHardening = "Service Control is set to default permissions"
                        }
                        default {
                            Write-Verbose "Unknown Service Control Permissions"
                            $ServiceHardening = "Unknown Service Control Permissions"
                        }
                    }
                }
                else {
                    Write-Warning 'Unable to find the Tanium Client Service'
                    $ServiceHardening = 'Unknown'
                }
            }
            catch {
                Write-Warning 'Unable to find the Tanium Client service'
                $ServiceHardening = 'Unknown'
            }
            
            $TaniumClientHardeningProperties += @{
                Service = $ServiceHardening
            }
        }
        'FileSystem' {
            Write-Warning "$Configuration hardening code not built yet"
            $TaniumClientDirectory = Get-TaniumClientDirectory
            $TaniumClientDirectoryAccess = Test-TaniumClientDirectoryAccess
            if ($TaniumClientDirectoryAccess) {
                $cmd = "icacls.exe `"$TaniumClientDirectory`""
                $cmdoutput = (Invoke-Expression $cmd)
                # Cleanup output
                $FileSystemPermissions = @()
                foreach ($Line in $cmdoutput) {
                    Write-Verbose "Processing $($Line.trim())"
                    if ($Line -like '*:*') {
                        Write-Verbose 'Found ACL'
                        $FileSystemPermissions += $Line.TrimStart($TaniumClientDirectory).Trim()
                    }
                    else {
                        Write-Verbose 'Line does not contain ACL'
                    }
                }
                if ($FileSystemPermissions) {
                    Write-Verbose 'Found permissions for Tanium client directory.'
                    Write-Verbose "File systems permissions DACL contains $($FileSystemPermissions.Count) ACL's"
                    foreach ($Permission in $FileSystemPermissions) {
                        Write-Verbose $Permission
                    }
                    if ($FileSystemPermissions.Count -eq 1) {
                        $FileSystemPermissionsUser = $FileSystemPermissions.split(':')[0]
                        Write-Verbose "File Permissions user is $FileSystemPermissionsUser"
                        if ($FileSystemPermissionsUser -eq 'NT AUTHORITY\SYSTEM') {
                            $FileSystemHardening = 'Restricted'
                        }
                        else {
                            $FileSystemHardening = "Restricted - $FileSystemPermissionsUser"
                        }
                    }
                    else {
                        $FileSystemHardening = 'Not Restricted'
                    }
                }
                else {
                    Write-Warning 'Unable to find permissions for Tanium client directory.'
                }
            }
            else {
                $FileSystemHardening = 'Restricted'
            }
            
            $TaniumClientHardeningProperties += @{
                FileSystem = $FileSystemHardening
            }
        }
    }
    $TaniumClientHardening = New-Object -Type PSObject -Property $TaniumClientHardeningProperties
    $TaniumClientHardening
}