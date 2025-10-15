function Get-TaniumClientDeployDbTable {
    [cmdletbinding()]
    param(
        [string]$Table
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        if ($Table) {
            $Query = "SELECT * from $Table"
        }
        else {
            $Query = "SELECT name FROM sqlite_master WHERE type = 'table'"
        }
        
        $TaniumClientDeployDbFile = Get-TaniumClientDeployDbFile
        $Results = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbFile -Query $Query
        $Results
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}