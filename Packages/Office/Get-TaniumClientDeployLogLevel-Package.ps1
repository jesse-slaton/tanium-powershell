function Get-TaniumClientDeployLogLevel {
    [cmdletbinding()]
    param()
    
    # Begin 
    $TaniumClientDirectory = Get-TaniumClientDirectory
    $File = 'Tools\SoftwareManagement\py\swmgr\log\configure.py'
    if ($TaniumClientDirectory) {
        $DeployLogLevelFilePath = "$TaniumClientDirectory\$File"
        try {
            if ($DeployLogLevelFilePath) {
                Write-Verbose "Found $DeployLogLevelFilePath"
                $Find = '\s{4}log\.setLevel\(logging\..*\)'
                Write-Verbose "Getting Deploy log level to $LogLevel"
                $DeployLogLevelRaw = Select-String -Path $DeployLogLevelFilePath -Pattern $Find
                $DeployLogLevel = ($DeployLogLevelRaw.Matches | Select-Object -ExpandProperty Value).Split('.')[2].TrimEnd(')')
                Write-Output $DeployLogLevel
            }
            else {
                Write-Warning "Unable to find $DeployLogLevelFilePath"
            }
        }
        catch {
            Write-Warning "Unable to read $DeployLogLevelFilePath"
        }
    }
    # End
}