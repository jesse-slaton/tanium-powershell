function Get-TaniumClientLog {
    [CmdletBinding()]
    param(
        [int]$Last,
        [Alias('Tail')]
        [switch]$Wait,
        [string]$Filter,
        [ValidateSet('client','action-history','extensions','sensor-history','file-staging')]
        [string]$Log = 'client'
    )
    $TaniumClientDirectory = Get-TaniumClientDirectory
    switch ($Log) {
        'client' {
            $LogName = 'log0.txt'
        }
        'action-history' {
            $LogName = 'action-history0.txt'
        }
        'extensions' {
            $LogName = 'extensions0.txt'
        }
        'sensor-history' {
            $LogName = 'sensor-history0.txt'
        }
        'file-staging' {
            $LogName = 'file-staging0.txt'
        }
    }
    $LogPath = "`"$TaniumClientDirectory\Logs\$LogName`""
    $Command = "Get-Content -Path $LogPath"
    if ($Last) {
        $Command = $Command + " -Last $Last"
    }
    if ($Wait.IsPresent) {
        $Command = $Command + " -Wait"
    }
    if ($Filter) {
        $Command = $Command + " | Select-String -Pattern `"$Filter`""
    }
    Write-Verbose "Executing $Command"
    Invoke-Expression $Command
}