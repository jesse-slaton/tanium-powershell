#Requires -Version 3.0

<#
.SYNOPSIS
    Checks Network Connectivity Status Indicator (NCSI) probes and writes a one-line summary.

.DESCRIPTION
    Reads the NCSI settings under
    HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet and:

    - resolves ActiveWebProbeHost and ActiveDnsProbeHost as DNS A records
      (Resolve-DnsName -DnsOnly)
    - requests http://<ActiveWebProbeHost>/<ActiveWebProbePath> and compares the
      content with ActiveWebProbeContent. The result is True on a match and False if
      the request throws; on a mismatch without an error it stays empty.
    - reads the IP-enabled adapters from Win32_NetworkAdapterConfiguration and computes
      the network address of each adapter's first IP address. Only the last adapter
      processed is kept.

    Writes one line with Write-Host:

        <ProbeHostName>, <ProbeIPs joined by |>, <ProbeResult>, <DnsProbeHostName>, <DnsProbeIP>, <Network>

    Makes no changes.

.EXAMPLE
    .\ncsidiag-Package.ps1

    Writes the NCSI probe summary for this computer.

.NOTES
    Needs network access to the NCSI probe hosts (plain HTTP). Requires the DnsClient
    module (Resolve-DnsName, Windows 8 / Server 2012 or later). Uses the CIM cmdlets;
    runs on Windows PowerShell 5.1 and PowerShell 7. Invoke-WebRequest is called without
    -UseBasicParsing. No admin rights needed.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/General/ncsidiag-Package.ps1.
#>
$NCSIProbeHost = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeHost
$NCSIDNSAddress = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveDnsProbeHost
$ResolvedNCSIProbeHost = Resolve-DnsName -Name $NCSIProbeHost -DnsOnly -Type A
$ResolvedNCSIProbeHostname = $ResolvedNCSIProbeHost.Name[0]
$NCSIIPAddresses = $ResolvedNCSIProbeHost.ipaddress -join "|"

$ResolvedDNSHost = Resolve-DnsName -Name $NCSIDNSAddress -DnsOnly -Type A
$ResolvedDNSHostname = $ResolvedDNSHost.Name
$ResolvedDNSIPAddress = $ResolvedDNSHost.ipaddress

try {
    if ( (Invoke-Webrequest ("http://{0}/{1}" -f (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeHost,
                (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbePath)
        ).Content -eq (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeContent ) { 

        # IP4 web request was successful
        
        Write-Verbose 'IP4 web probe succeeded.'
        
        $ProbeResults = $true 

    }
}
catch {
    # Ignore errors

    Write-Verbose 'IP4 web probe failed.'
    $ProbeResults = $false 

}

Try {
    $Networks = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration `
        -ErrorAction Stop | Where-Object { $_.IPEnabled }
}
Catch {
    Write-Warning "Error occurred while querying."
    Continue
}
foreach ($Network in $Networks) {
    [ipaddress] $IPAddress = $Network.IpAddress[0]
    [ipaddress] $SubnetMask = $Network.IPSubnet[0]
    [ipaddress] $NetAddr = ($IPAddress.Address -band $SubnetMask.Address)
    $RouteCostMetric = $Network.GatewayCostMetric
    $OutputObj = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
    $OutputObj | Add-Member -MemberType NoteProperty -Name Network -Value $NetAddr
    $OutputObj | Add-Member -MemberType NoteProperty -Name RouteCostMetric -Value $RouteCostMetric
}
$PrimaryIP = $OutputObj | Sort-Object -Property RouteCostMetric | Select-Object -First 1

Write-Host "$ResolvedNCSIProbeHostname, $NCSIIPAddresses, $ProbeResults, $ResolvedDNSHostname, $ResolvedDNSIPAddress, $($PrimaryIP.Network)"