function New-Download {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]$Uri,
        [parameter(Mandatory = $true)]
        [string]$Path,
        [string]$FileName,
        [ValidateSet('web', 'bits', 'tanium')]
        [string]$Method = 'web',
        [int]$DownloadTimeout = 900,
        [int]$SleepIntervalInSeconds = 60
    )
    function Write-TimestampMessage {
        param (
            [Parameter(Mandatory = $true,
                ValueFromPipelineByPropertyName = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$Message
        )
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Output "$FormattedDate INFO: $Message"
    }
    if (Test-Path -Path $Path) {
        Write-Verbose "Found $Path"
        if ($FileName) {
            Write-Verbose "FileName parameter specified: $FileName"
        }
        else {
            Write-Verbose "FileName parameter not specified. Using existing download name $($Uri.Split('/')[-1])"
            $FileName = $Uri.Split('/')[-1]
        }
        Write-TimeStampMessage -Message "Beginning download of $Uri to $Path\$FileName using $Method"
        switch ($Method) {
            'web' {
                # Use Invoke-WebRequest
                # Disabling Progress display to download at full speed
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $Uri -OutFile "$Path\$Filename" -UseBasicParsing
                # Re-enabling Progress display
                $ProgressPreference = 'Continue'
                Write-TimeStampMessage -Message "Completed downloaded saved to $Path\$FileName"
            }
            'bits' {
                # Use Background Intelligent Transfer Service (BITS)
                $Download = Start-BitsTransfer -DisplayName $Uri -Source $Uri -Destination "$Path\$FileName" -Asynchronous -Priority Normal
                $DownloadComplete = $false
                $DownloadStartTime = Get-Date
                $DownloadEndTime = $DownloadStartTime.AddSeconds($DownloadTimeout)
                do {
                    Write-Verbose "Checking Download Status"
                    Write-TimeStampMessage -Message "$FileName is $($Download.JobState)"
                    if ($Download.JobState -eq 'Transferred') {
                        $DownloadComplete = $true
                        Write-Verbose "$FileName is $($Download.JobState)"
                        Write-Verbose "Moving $FileName to $Path"
                        $Download | Complete-BitsTransfer
                        Write-TimeStampMessage -Message "Completed downloaded saved to $Path\$FileName"
                    }
                    else {
                        Write-Verbose "$FileName is $($Download.JobState)"
                        if ((Get-Date) -ge $DownloadEndTime) {
                            Write-Verbose "Download Timeout Expired: $DownloadTimeout seconds"
                            $DownloadTimeoutExpired = $true
                            $Download | Remove-BitsTransfer
                            Write-Output "Download timed out for $Uri. Cancelled download."
                        }
                        else {
                            [int]$DownloadTimeRemaining = (New-TimeSpan -Start (Get-Date) -End $DownloadEndTime).TotalSeconds
                            Write-Verbose "Download timeout ($DownloadTimeout seconds) has not expired. $DownloadTimeRemaining seconds remaining."
                        }
                        Start-Sleep -Seconds $SleepIntervalInSeconds
                    }
                } Until ($DownloadComplete -or $DownloadTimeoutExpired)
            }
            'tanium' {
                # Use Tanium Client API
                $TaniumClientDirectory = Get-TaniumClientDirectory
                $Download = New-TaniumClientApiDownload -Url $Uri -Filename $FileName
                $DownloadComplete = $false
                $DownloadStartTime = Get-Date
                $DownloadEndTime = $DownloadStartTime.AddSeconds($DownloadTimeout)
                do {
                    Write-Verbose "Checking Download Status"
                    $Download = Get-TaniumClientApiDownload -File $FileName -Url $Uri
                    if ($Download) {
                        Write-TimeStampMessage -Message "$($Download.url) is $($Download.status)"
                        if ($Download.Status -eq 'Completed') {
                            $DownloadComplete = $true
                            Write-Verbose "$($Download.url) is $($Download.status)"
                            Write-Verbose "Copying $($Download.name) to $Path"
                            Copy-Item -Path "$TaniumClientDirectory\Downloads\$FileName" -Destination "$Path\$FileName" -Force
                            $Download = Stop-TaniumClientApiDownload -File $FileName -Url $Uri
                            Write-TimeStampMessage -Message "Completed downloaded saved to $Path\$FileName"
                        }
                        else {
                            Write-Verbose "$($Download.url) is $($Download.status)"
                            if ((Get-Date) -ge $DownloadEndTime) {
                                Write-Verbose "Download Timeout Expired: $DownloadTimeout seconds"
                                $DownloadTimeoutExpired = $true
                                $Download = Stop-TaniumClientApiDownload -File $FileName -Url $Uri
                                Write-Output "Download timed out for $Uri. Cancelled download."
                            }
                            else {
                                [int]$DownloadTimeRemaining = (New-TimeSpan -Start (Get-Date) -End $DownloadEndTime).TotalSeconds
                                Write-Verbose "Download timeout ($DownloadTimeout seconds) has not expired. $DownloadTimeRemaining seconds remaining."
                            }
                            Start-Sleep -Seconds $SleepIntervalInSeconds
                        }
                    }
                    else {
                        Write-Verbose "Unable to retreive Tanium Client download status. Retrying in $SleepIntervalInSeconds seconds."
                    }
                } Until ($DownloadComplete -or $DownloadTimeoutExpired)
            }
        }
    }
    else {
        Write-Warning "Unable to find $Path"
    }
}