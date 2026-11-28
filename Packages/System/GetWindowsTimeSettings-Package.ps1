<#
.SYNOPSIS
    Reports the Windows Time NTP server, poll interval and service status as one pipe-delimited line.

.DESCRIPTION
    Reads NtpServer from HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters and
    SpecialPollInterval from
    HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient, and the
    status of the w32time service. The inline comments describe setting these values,
    but this script only reads them.

    The internal ConvertToFriendlyTime function turns the poll interval (seconds) into
    a rounded string such as "15 minutes", "1 hour" or "7 days".

    Outputs one line in this form:
    <NtpServer>|<Flags>|<Interval>|<ServiceStatus>
    where NtpServer and Flags are the parts of the NtpServer value before and after
    the first comma (only the first server is shown when several are listed). Changes
    nothing.

.EXAMPLE
    .\GetWindowsTimeSettings-Package.ps1

    Outputs a line such as time.windows.com|0x9|15 minutes|<ServiceStatus> on a
    computer configured by EnableNTPClient.ps1.

.NOTES
    No admin rights needed. If NtpServer or SpecialPollInterval is missing, the script
    writes errors. Works in Windows PowerShell 5.1 and PowerShell 7.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/Network/GetWindowsTimeSettings-Package.ps1.
#>


function ConvertToFriendlyTime {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Seconds
    )

    $TimeSpan = New-TimeSpan -Seconds $Seconds
    $OutputString = ""

    if ($TimeSpan.Days -gt 0) {
        $OutputString = "{0} {1}" -f $TimeSpan.Days, $(if ($TimeSpan.Days -eq 1) {"day"} else {"days"})
    } elseif ($TimeSpan.Hours -gt 0) {
        $OutputString = "{0} {1}" -f $TimeSpan.Hours, $(if ($TimeSpan.Hours -eq 1) {"hour"} else {"hours"})
    } elseif ($TimeSpan.Minutes -gt 0) {
        $OutputString = "{0} {1}" -f $TimeSpan.Minutes, $(if ($TimeSpan.Minutes -eq 1) {"minute"} else {"minutes"})
    } else {
        $OutputString = "{0} {1}" -f $TimeSpan.Seconds, $(if ($TimeSpan.Seconds -eq 1) {"second"} else {"seconds"})
    }

    # Round to the nearest day, hour, or minute
    switch ($OutputString) {
        { $_ -match "day" } { $OutputString = "{0} {1}" -f ([math]::Round($TimeSpan.TotalDays)), $(if ([math]::Round($TimeSpan.TotalDays) -eq 1) {"day"} else {"days"}) }
        { $_ -match "hour" } { $OutputString = "{0} {1}" -f ([math]::Round($TimeSpan.TotalHours)), $(if ([math]::Round($TimeSpan.TotalHours) -eq 1) {"hour"} else {"hours"}) }
        { $_ -match "minute" } { $OutputString = "{0} {1}" -f ([math]::Round($TimeSpan.TotalMinutes)), $(if ([math]::Round($TimeSpan.TotalMinutes) -eq 1) {"minute"} else {"minutes"}) }
    }

    return $OutputString
}

# Set the time server to time.windows.com
$NTPServer = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name NtpServer).NtpServer

# Configure the time service to start automatically and sync every 15 minutes
$Interval = ConvertToFriendlyTime -Seconds $(Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient -Name SpecialPollInterval).SpecialPollInterval 
$ServiceStatus = (Get-Service -Name w32time).Status

Write-Output "$($NTPServer.Split(',')[0])|$($NTPServer.Split(',')[1])|$($Interval)|$($ServiceStatus)"