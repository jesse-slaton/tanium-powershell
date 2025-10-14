function Get-TaniumClientPatchSetting {
    [CmdletBinding()]
    param()
    $TaniumClientPatchSetting = Get-TaniumClientPatchData -DataType settings-file
    if ($TaniumClientPatchSetting) {
        Write-Verbose 'Found Tanium Patch settings-file'
        Write-Output $TaniumClientPatchSetting
    }
    else {
        Write-Verbose 'Tanium Patch settings-file not present. Assume default settings.'
        $TaniumClientPatchSetting = @{
            logLevel               = 3
            maxLogSizeInMb         = 1
            numberOfLogsToKeep     = 10
            sleepIntervalInMinutes = 1
            execTimeoutInSeconds   = 45
        }
        Write-Output $TaniumClientPatchSetting
    }
}