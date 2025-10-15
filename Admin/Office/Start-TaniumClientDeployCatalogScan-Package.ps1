function Start-TaniumClientDeployCatalogScan {
    [cmdletbinding()]
    param ()
    begin {}
    process {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $TaniumClientTpython = Get-TaniumClientTpython
        if ($TaniumClientTpython) {
            Write-Verbose 'Found Tpython'
            $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
            if ($TaniumClientDeployDirectory) {
                Write-Verbose 'Found Tanium client Deploy directory'
                # Assuming Deploy 2 at this point
                Enable-TaniumClientTpythonDebug | Out-Null
                Write-Verbose 'Starting Tanium Client Deploy catalog scan'
                Write-Verbose "Executing $TaniumClientTPython $TaniumClientDeployDirectory\py\swmgr\main.py catalog scan"
                Start-Process -FilePath "$TaniumClientTpython" -ArgumentList "`"$TaniumClientDeployDirectory\py\swmgr\main.py`"", 'catalog', 'scan' -WorkingDirectory $TaniumClientDirectory -Wait -WindowStyle Hidden
                Write-Verbose 'Tanium Client Deploy catalog scan completed'
                Disable-TaniumClientTpythonDebug | Out-Null
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