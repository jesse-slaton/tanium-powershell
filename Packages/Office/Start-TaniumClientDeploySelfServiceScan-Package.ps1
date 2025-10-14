function Start-TaniumClientDeploySelfServiceScan {
    [cmdletbinding()]
    param ()
    begin {
        $TaniumClientDeployJson = @"
{"action_type": "scan_now", "action_data": {"scan_type": "software_package_scan"}}
"@
    }
    process {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $TaniumClientTpython = Get-TaniumClientTpython
        if ($TaniumClientTpython) {
            Write-Verbose 'Found Tpython'
            $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
            if ($TaniumClientDeployDirectory) {
                Write-Verbose 'Found Tanium client Deploy directory'
                # Assuming Deploy 2 at this point
                
                Write-Verbose 'Enabling Tpython Debug mode'
                Enable-TaniumClientTpythonDebug | Out-Null
                Write-Verbose 'Starting Tanium Client Deploy self-service scan'
                Write-Verbose "Executing $TaniumClientTPython $TaniumClientDeployDirectory\py\swmgr\main.py euss update-catalog"
                Start-Process -FilePath "$TaniumClientTpython" -ArgumentList "`"$TaniumClientDeployDirectory\py\swmgr\main.py`"", 'euss', 'update-catalog' -WorkingDirectory $TaniumClientDirectory -Wait -WindowStyle Hidden
                Write-Verbose 'Tanium Client Deploy self-service scan initiated'
                Write-Verbose 'Disabling Tpython Debug mode'
                Disable-TaniumClientTpythonDebug | Out-Null
                
                <#
                Write-Verbose "Generating scan instructions"
                $TaniumClientDeployJson | Set-Content -Path "$TaniumClientDeployDirectory\data\actions\software_package_scan_now.json" -Force
                #>
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