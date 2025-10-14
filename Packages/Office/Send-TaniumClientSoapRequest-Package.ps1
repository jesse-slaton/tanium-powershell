function Send-TaniumClientSoapRequest {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$SoapUrl,
        [Parameter(Mandatory=$true)]
        [xml]$TaniumClientApiSoapRequest,
        [int]$Retries = 3,
        [int]$SleepinSeconds = 10
    )
    Write-Verbose "Sending SOAP Request to $SoapUrl"
    $Counter = 1
    do {
        try {
            # Disabling Progress display to download at full speed
            $ProgressPreference = 'SilentlyContinue'
            $SoapData = Invoke-WebRequest -Uri $SoapUrl -Method Post -Body $TaniumClientApiSoapRequest -ContentType 'application/xml' -UseBasicParsing -ErrorAction Stop
            # Re-enabling Progress display
            $ProgressPreference = 'Continue'
            # Validate SoapData contains valid date
            if (Test-SoapData -SoapData $SoapData) {
                Write-Verbose 'Valid Tanium Client API download response.'
                $SoapData
            }
            else {
                Write-Warning 'Invalid Tanium Client API download response. Try again.'
                $SoapData = $null
            }
        }
        catch {
            Write-Warning "Unable to communicate with Tanium Client API. Retry in $SleepinSeconds seconds"
            Start-Sleep -Seconds $SleepinSeconds
            $Counter++
        }
    } while ($null -eq $SoapData -and $Counter -le $Retries)
}