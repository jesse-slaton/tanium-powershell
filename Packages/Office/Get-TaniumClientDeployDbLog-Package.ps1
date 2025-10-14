function Get-TaniumClientDeployDbLog {
    [cmdletbinding()]
    param()
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT * FROM logs"
        $TaniumClientDeployDbFile = Get-TaniumClientDeployDbFile
        $TaniumClientDeployDbLog = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbFile -Query $Query
        $TaniumClientDeployDbLog
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}