function Get-TaniumClientDeployScanHistory {
    [cmdletbinding()]
    param(
        [int]$Id,
        [switch]$LastScan
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT * FROM scan_history"
        if ($Id) {
            $Query += " WHERE id = $Id"
        }
        if ($LastScan.IsPresent) {
            $Query += " ORDER BY id DESC LIMIT 1"
        }
        $TaniumClientDeployDbFile = Get-TaniumClientDeployDbFile
        $result = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbFile -Query $Query
        $result
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}