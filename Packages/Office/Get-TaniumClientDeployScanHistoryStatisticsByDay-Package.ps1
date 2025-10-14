function Get-TaniumClientDeployScanHistoryStatisticsByDay {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [int]$Id
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT * FROM scan_history"
        if ($Id) {
            $Query += " WHERE id = $Id"
        }
        $TaniumClientDeployDbFile = Get-TaniumClientDeployDbFile
        $ScanHistoryResults = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbFile -Query $Query
        $ScanHistoryResults.start_time | Get-Date -Format 'yyyy-MM-dd' | Group-Object | Select-Object -Property Name,Count
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}