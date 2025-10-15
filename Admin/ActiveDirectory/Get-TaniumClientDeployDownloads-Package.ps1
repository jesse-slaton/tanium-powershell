function Get-TaniumClientDeployDownloads {
    [cmdletbinding()]
    param()
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT * FROM downloads WHERE product = 'Deploy'"
        $TaniumClientDeployDbPath = Get-TaniumClientDeployDbFile
        $TaniumClientDeployProductInstallId = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbPath -Query $Query
        $TaniumClientDeployProductInstallId
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}