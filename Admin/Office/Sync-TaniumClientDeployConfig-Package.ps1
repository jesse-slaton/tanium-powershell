function Sync-TaniumClientDeployConfig {
    [cmdletbinding()]
    param ()
    begin {}
    process {
        $SyncTaniumDeployPython = @"
import swmgr.endpoint_config.get_configs
swmgr.endpoint_config.get_configs.sync_all_deploy_configs()
"@
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $TaniumClientTpython = Get-TaniumClientTpython
        if ($TaniumClientTpython) {
            Write-Verbose 'Found Tpython'
            $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
            if ($TaniumClientDeployDirectory) {
                Write-Verbose 'Found Tanium client Deploy directory'
                # Assuming Deploy 2 at this point
                $SyncTaniumDeployPythonTempFileName = "$Env:TEMP\sync-tanium-deploy.py"
                Set-Content -Path $SyncTaniumDeployPythonTempFileName -Value $SyncTaniumDeployPython -Force | Out-Null
                if (Test-Path -Path $SyncTaniumDeployPythonTempFileName) {
                    Write-Verbose "Found $SyncTaniumDeployPythonTempFileName"
                    Enable-TaniumClientTpythonDebug | Out-Null
                    Write-Verbose 'Syncing Tanium Client Deploy Configurations with CX'
                    Write-Verbose "Executing $TaniumClientTPython $SyncTaniumDeployPythonTempFileName"
                    Start-Process -FilePath "$TaniumClientTpython" -ArgumentList $SyncTaniumDeployPythonTempFileName -WorkingDirectory $TaniumClientDirectory -WindowStyle Hidden -Wait
                    Write-Verbose 'Tanium Client Deploy sync completed.'
                    Disable-TaniumClientTpythonDebug | Out-Null
                    Remove-Item -Path $SyncTaniumDeployPythonTempFileName -Force
                }
                else {
                    Write-Warning "Unable to find $SyncTaniumDeployPythonTempFileName. Exiting."
                    return
                }
            }
            else {
                Write-Warning 'Aborting. Unable to find Tanium client deploy directory.'
            }
        }
        else {
            Write-Warning 'Aborting. Unable to find Tpython'
        }
    }
    end {}
}