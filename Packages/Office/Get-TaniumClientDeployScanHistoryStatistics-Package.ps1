function Get-TaniumClientDeployScanHistoryStatistics {
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
        $ScanLengthTimes = @()
        foreach ($ScanHistory in $ScanHistoryResults) {
            $ScanLength = (New-TimeSpan -Start $ScanHistory.start_time -End $ScanHistory.end_time) | Select-Object -ExpandProperty 'TotalSeconds'
            Write-Verbose "Scan Id $($ScanHistory.id) started at $($ScanHistory.start_time)"
            Write-Verbose "Scan Id $($ScanHistory.id) ended at $($ScanHistory.end_time)"
            Write-Verbose "Scan Id $($ScanHistory.id) took $ScanLength seconds."
            $ScanLengthTimes += $ScanLength
        }
        $ScanLengthStatistics = $ScanLengthTimes | Measure-Object -Minimum -Maximum -Average
        $ScanHistoryStatisticsProperties = @{
            MinimumScanLength = [int]$ScanLengthStatistics.Minimum
            MaximumScanLength = [int]$ScanLengthStatistics.Maximum
            AverageScanLength = [int]$ScanLengthStatistics.Average
        }
        $ScanHistoryStatistics = New-Object -TypeName PSCustomObject -Property $ScanHistoryStatisticsProperties
        $ScanHistoryStatistics
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}