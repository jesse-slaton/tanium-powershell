function Get-TaniumClientActionHistoryStatistics {
    [cmdletbinding()]
    param (
        [string]$Path,
        [string]$ActionName,
        [switch]$GroupByActionName
    )
    if ($Path) {
        $TaniumClientActionHistoryLog = $Path
    }
    else {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $TaniumClientActionHistoryLog = "$TaniumClientDirectory\Logs\action-history0.txt"
    }
    
    if (Test-Path -Path $TaniumClientActionHistoryLog) {
        Write-Verbose 'Found Tanium client action history log'
        $TaniumClientActionHistory = @()
        $TaniumClientActionHistoryRaw = (Select-String -Path $TaniumClientActionHistoryLog -Pattern '\s\[.*\]: completed in .*$' | ForEach-Object { $_.Matches } | Select-Object -ExpandProperty Value).trim()
        foreach ($TaniumClientActionHistoryEntry in $TaniumClientActionHistoryRaw) {
            Write-Verbose "Processing log entry $TaniumClientActionHistoryEntry"
            $TaniumClientActionHistoryName = $TaniumClientActionHistoryEntry.Split(']:')[0].trimstart('[')
            Write-Verbose $TaniumClientActionHistoryName
            $TaniumClientActionTiming = ($TaniumClientActionHistoryEntry | Select-String -Pattern '\d*\.\d* seconds' | ForEach-Object { $_.Matches } | Select-Object -ExpandProperty Value).Split(' ')[0]
            $TaniumClientActionHistoryItemProperties = @{
                'Name' = $TaniumClientActionHistoryName
                'Seconds' = $TaniumClientActionTiming
            }
            $TaniumClientActionHistoryItem = New-Object -TypeName PSObject -Property $TaniumClientActionHistoryItemProperties
            $TaniumClientActionHistory += $TaniumClientActionHistoryItem
        }
        if ($ActionName) {
            Write-Verbose "Getting action history statistics for $ActionName"
            $TaniumClientActionHistory = $TaniumClientActionHistory | Where-Object { $_.Name -like "$ActionName" }
        }
        if ($GroupByActionName.IsPresent) {
            $TaniumClientActionsbyGroup = $TaniumClientActionHistory | Group-Object -Property 'name'
            foreach ($TaniumClientAction in $TaniumClientActionsbyGroup) {
                $TaniumClientActionStatistics = $TaniumClientAction | Select-Object -ExpandProperty Group | Measure-Object -Property 'Seconds' -Sum -Average -Maximum -Minimum
                $TaniumClientActionHistoryStatisticsProperties = @{
                    'Name'    = $TaniumClientAction.Name
                    'Count'   = $TaniumClientActionStatistics.Count
                    'Average' = $TaniumClientActionStatistics.Average
                    'Sum'     = $TaniumClientActionStatistics.Sum
                    'Maximum' = $TaniumClientActionStatistics.Maximum
                    'Minimum' = $TaniumClientActionStatistics.Minimum
                }
                $TaniumClientActionHistoryStatistics = New-Object -TypeName PSObject -Property $TaniumClientActionHistoryStatisticsProperties
                $TaniumClientActionHistoryStatistics
            }
        }
        else {
            $TaniumClientActionHistoryStatistics = $TaniumClientActionHistory | Measure-Object -Property 'Seconds' -Sum -Average -Maximum -Minimum
            $TaniumClientActionHistoryStatistics
        }
    }
}