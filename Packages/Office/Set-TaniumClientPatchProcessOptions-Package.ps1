function Set-TaniumClientPatchProcessOptions {
    [CmdletBinding()]
    param(
        [ValidateSet('ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE')]
        [string]$LogLevel = 'DEBUG'
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientSettingsFile = "$TaniumClientPatchDirectory\settings-file"
    $LogLevelOptions = @{
        'ERROR' = '1'
        'WARN'  = '2'
        'INFO'  = '3'
        'DEBUG' = '4'
        'TRACE' = '5'
    }
    [xml]$TaniumClientSettings = "<log-settings><logLevel>4</logLevel><maxLogSizeInMb>10</maxLogSizeInMb><numberOfLogsToKeep>10</numberOfLogsToKeep><sleepIntervalInMinutes>1</sleepIntervalInMinutes><execTimeoutInSeconds>45</execTimeoutInSeconds></log-settings>"
    $TaniumClientSettings.'log-settings'.logLevel = $LogLevelOptions[$LogLevel]
    Set-Content -Path $TaniumClientSettingsFile -Value $TaniumClientSettings.'log-settings'.OuterXml -Force | Out-Null
    Write-Verbose "Tanium Client Patch process options set at $TaniumClientSettingsFile."
}