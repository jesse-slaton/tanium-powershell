function Get-TaniumClientSensorHistoryStatistics {
    [cmdletbinding()]
    param (
        [string]$Path,
        [string]$SensorName,
        [switch]$GroupBySensorName,
        [switch]$ShowSourceSensorName
    )
    if ($Path) {
        $TaniumClientSensorHistoryLog = $Path
    }
    else {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $TaniumClientSensorHistoryLog = "$TaniumClientDirectory\Logs\sensor-history0.txt"
    }
    
    if (Test-Path -Path $TaniumClientSensorHistoryLog) {
        Write-Verbose 'Found Tanium client sensor history log'
        $TaniumClientSensorHistory = Select-String -Path $TaniumClientSensorHistoryLog -Pattern '{.*}' -AllMatches | ForEach-Object { $_.Matches } | Select-Object -ExpandProperty Value | ConvertFrom-Json

        if ($ShowSourceSensorName.IsPresent) {
            $TaniumClientSensorHistory | ForEach-Object {
                Write-Verbose "Replacing tempsensor name $($_.name) with source sensor name $($_.source_name)"
                if ($_.name -like 'tempsensor_*') {
                    $_.name = $_.source_name
                }
            }
        }
        if ($SensorName) {
            Write-Verbose "Getting sensor history statistics for $SensorName"
            $TaniumClientSensorHistory = $TaniumClientSensorHistory | Where-Object { $_.name -like "$SensorName" }
        }
        if ($GroupBySensorName.IsPresent) {
            $TaniumClientSensorsbyGroup = $TaniumClientSensorHistory | Group-Object -Property 'name'
            foreach ($TaniumClientSensor in $TaniumClientSensorsbyGroup) {
                $TaniumClientSensorStatistics = $TaniumClientSensor | Select-Object -ExpandProperty Group | Measure-Object -Property 'real_ms' -Sum -Average -Maximum -Minimum
                $TaniumClientSensorHistoryStatisticsProperties = @{
                    'Name'    = $TaniumClientSensor.name
                    'Count'   = $TaniumClientSensorStatistics.Count
                    'Average' = $TaniumClientSensorStatistics.Average
                    'Sum'     = $TaniumClientSensorStatistics.Sum
                    'Maximum' = $TaniumClientSensorStatistics.Maximum
                    'Minimum' = $TaniumClientSensorStatistics.Minimum
                }
                $TaniumClientSensorHistoryStatistics = New-Object -TypeName PSObject -Property $TaniumClientSensorHistoryStatisticsProperties
                $TaniumClientSensorHistoryStatistics
            }
        }
        else {
            $TaniumClientSensorHistoryStatistics = $TaniumClientSensorHistory | Measure-Object -Property 'real_ms' -Sum -Average -Maximum -Minimum
            $TaniumClientSensorHistoryStatistics
        }
    }
}