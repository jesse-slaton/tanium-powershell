function Set-TaniumClientDeployLogLevel {
    [cmdletbinding()]
    param (
        [ValidateSet('DEBUG','INFO', 'WARNING','ERROR','CRITICAL')]
        $LogLevel = 'INFO'
    )

    # Begin 
    $TaniumClientDirectory = Get-TaniumClientDirectory
    $File = 'Tools\SoftwareManagement\py\swmgr\log\configure.py'
    if ($TaniumClientDirectory) {
        $DeployLogLevelFilePath = "$TaniumClientDirectory\$File"
        try {
            if ($DeployLogLevelFilePath) {
                Write-Verbose "Found $DeployLogLevelFilePath"
                $Find = '\s{4}log\.setLevel\(logging\..*\)'
                $Replace = "    log.setLevel(logging.$LogLevel)"
                Write-Verbose "Setting Deploy log level to $LogLevel"
                (Get-Content -Path $DeployLogLevelFilePath) -replace $Find, $Replace | Set-Content -Path $DeployLogLevelFilePath -ErrorAction Stop
            }
            else {
                Write-Warning "Unable to find $DeployLogLevelFilePath"
            }
        }
        catch {
            Write-Warning "Unable to update $DeployLogLevelFilePath"
        }
    }
    # End
}