#Requires -Version 5.1

<#
.SYNOPSIS
    Tests for an internet connection.

.DESCRIPTION
    Tests for an internet connection using the same method Windows uses for the
    Network Connection Status icon. If an internet connection is detected, $true is
    returned; otherwise $false is returned. The two web probes are bounded to a
    two-second timeout each; the two DNS lookups (Resolve-DnsName -DnsOnly) have no
    timeout, and -DnsOnly only skips LLMNR and NetBIOS, so an offline run can still
    block on an unbounded DNS lookup before returning $false.

.EXAMPLE
    Test internet connection

    PS C:\> Test-InternetConnection

.EXAMPLE
    Show results of testing internet connection

    PS C:\> Test-InternetConnection -Verbose

.EXAMPLE
    Internet connection required for a script

    PS C:\> if(Test-InternetConnection) { ... }

.INPUTS

.OUTPUTS
    System.Boolean

.NOTES
    See https://technet.microsoft.com/en-us/library/ee126135(v=ws.10).aspx and
        http://blogs.technet.com/b/networking/archive/2012/12/20/the-network-connection-status-icon.aspx and
        HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet
    for the description of the mechanism.
    When offline, the worst case is two web requests bounded to two seconds each, then
    two DNS lookups that are not bounded (Resolve-DnsName has no timeout and -DnsOnly
    only skips LLMNR and NetBIOS).
    VERSION 1.0.0, 7.2.2016
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/General/Test-InternetConnection-Sensor.ps1.

.LINK
    about_functions_advanced

.LINK
    about_comment_based_help

#>


function Test-InternetConnection {
    [cmdletbinding()]
    Param()

    # Web request test with IP4

    try {
        if ( (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri ("http://{0}/{1}" -f (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeHost,
                    (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbePath)
            ).Content -eq (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeContent ) {

            # IP4 web request was successful

            Write-Verbose 'IP4 web probe succeeded.'

            return $true

        }
    }
    catch {
        # Ignore errors; a failure is reported as a failed probe, not thrown.

        Write-Verbose 'IP4 web probe failed.'
    }

    # Web request test with IP6

    try {
        if ( (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri ("http://{0}/{1}" -f (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeHostV6,
                    (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbePathV6)
            ).Content -eq (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeContentV6 ) {

            # IP6 web request was successful

            Write-Verbose 'IP6 web probe succeeded.'

            return $true

        }
    }
    catch {
        # Ignore errors; a failure is reported as a failed probe, not thrown.

        Write-Verbose 'IP6 web probe failed.'
    }

    # DNS resolution test with IP4

    try {
        $dnsAnswer = Resolve-DnsName -Name (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveDnsProbeHost -DnsOnly -Type A -ErrorAction Stop
        if ($dnsAnswer.IPAddress -eq (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveDnsProbeContent) {

            # IP4 name resolution was successful

            Write-Verbose 'IP4 name resolution succeeded.'

            return $true

        }
        Write-Verbose 'IP4 name resolution failed.'
    }
    catch {
        # A DNS failure is a defined failed probe, not an unbounded wait or an error.

        Write-Verbose 'IP4 name resolution failed.'
    }

    # DNS resolution test with IP6

    try {
        $dnsAnswer = Resolve-DnsName -Name (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveDnsProbeHostV6 -DnsOnly -Type AAAA -ErrorAction Stop
        if ($dnsAnswer.IPAddress -eq (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveDnsProbeContentV6) {

            # IP6 name resolution was successful

            Write-Verbose 'IP6 name resolution succeeded.'

            return $true

        }
        Write-Verbose 'IP6 name resolution failed.'
    }
    catch {
        # A DNS failure is a defined failed probe, not an unbounded wait or an error.

        Write-Verbose 'IP6 name resolution failed.'
    }

    # Everything failed, thus there is no internet connection
    return $false
}

Test-InternetConnection
