function Get-TaniumClientDeployMaintenanceWindow {
    [cmdletbinding()]
    param(
        [string]$Name,
        [int]$Id
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT * FROM maintenance_windows WHERE product = 'Deploy'"
        if ($Name) {
            $Query += " AND name LIKE '%$Name%'"
        }
        if ($Id) {
            $Query += " AND id = $Id"
        }
        $TaniumClientDeployDbPath = Get-TaniumClientDeployDbFile
        $TaniumClientDeployMaintenanceWindow = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbPath -Query $Query
        $TaniumClientDeployMaintenanceWindow
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}