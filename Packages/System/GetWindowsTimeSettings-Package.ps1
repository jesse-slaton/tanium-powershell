#Requires -Version 5.1

<#
.SYNOPSIS
    Reports the Windows Time NTP server, poll interval and service status as one pipe-delimited line.

.DESCRIPTION
    Reads NtpServer from HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters and
    SpecialPollInterval from
    HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient, and the
    status of the w32time service. Read-only: this script does not change any of these
    values.

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
    emits the row with an empty value for that column. Works in Windows PowerShell 5.1
    and PowerShell 7.
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

# Read the configured time server. A missing value yields an empty column, not an error.
$NtpServerValue = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name NtpServer -ErrorAction SilentlyContinue).NtpServer

# Read the configured poll interval (seconds) and convert it to a friendly string. A
# missing value yields an empty column rather than "0 seconds" or a Get-ItemProperty error.
$SpecialPollInterval = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient -Name SpecialPollInterval -ErrorAction SilentlyContinue).SpecialPollInterval
$Interval = if ($null -ne $SpecialPollInterval) { ConvertToFriendlyTime -Seconds $SpecialPollInterval } else { '' }
$ServiceStatus = (Get-Service -Name w32time).Status

# The NtpServer value can list several peers separated by spaces, each "host,flags". Split on
# whitespace first and take only the first peer, so the Flags column holds just that peer's
# flags instead of the next peer's host. A missing value yields empty columns, not an error.
$FirstPeer = if ($NtpServerValue) { ($NtpServerValue -split '\s+')[0] } else { '' }
$NtpServer = if ($FirstPeer -match ',') { $FirstPeer.Split(',')[0] } else { $FirstPeer }
$Flags = if ($FirstPeer -match ',') { $FirstPeer.Split(',')[1] } else { '' }

Write-Output "$NtpServer|$Flags|$Interval|$ServiceStatus"
