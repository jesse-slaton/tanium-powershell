function Get-TaniumClientApiToken {
    [cmdletbinding()]
    param (
        [int]$Retries = 3,
        [int]$SleepIntervalInSeconds = 10
    )

    $TaniumClientDirectory = Get-TaniumClientDirectory
    if ($TaniumClientDirectory) {
        $Counter = 1
        do {
            if (Test-Path -Path "$TaniumClientDirectory\soap_session") {
                [string]$TaniumClientApiToken = Get-Content -Path "$TaniumClientDirectory\soap_session"
                $TaniumClientApiToken
            }
            else {
                Write-Warning "No Tanium Client API token exists. Retrying in $SleepIntervalInSeconds seconds."
                $Counter++
                Start-Sleep -Seconds $SleepIntervalInSeconds
            }
        } while ($null -eq $TaniumClientApiToken -and $Counter -le $Retries)
        if ($null -eq $TaniumClientApiToken) {
            Write-Warning 'Unable to get Tanium Client Api Token. Verify the Tanium Client is running.'
        }
    }
    else {
        Write-Warning 'Unable to get Tanium Client Api Token. Verify the Tanium Client is installed.'
    }
}