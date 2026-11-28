#Requires -Version 5.1

<#
.SYNOPSIS
    Checks Network Connectivity Status Indicator (NCSI) probes and writes a one-line summary.

.DESCRIPTION
    Reads the NCSI settings under
    HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet and:

    - resolves ActiveWebProbeHost and ActiveDnsProbeHost as DNS A records
      (Resolve-DnsName -DnsOnly); a failed lookup is reported as an empty column
    - requests http://<ActiveWebProbeHost>/<ActiveWebProbePath> with a five-second
      timeout and compares the content with ActiveWebProbeContent. The result is True
      on a match and False when the request throws or the content differs (for example
      a captive portal)
    - reads the IP-enabled adapters from Win32_NetworkAdapterConfiguration and computes
      the network address of each IPv4 adapter's first address, then keeps the adapter
      with the lowest GatewayCostMetric. Adapters with no IPv4 address or no default
      gateway are skipped.

    Writes one line:

        <ProbeHostName>, <ProbeIPs joined by |>, <ProbeResult>, <DnsProbeHostName>, <DnsProbeIP>, <Network>

    Makes no changes.

.EXAMPLE
    .\ncsidiag-Package.ps1

    Writes the NCSI probe summary for this computer.

.NOTES
    Needs network access to the NCSI probe hosts (plain HTTP). Requires the DnsClient
    module (Resolve-DnsName, Windows 8 / Server 2012 or later). Uses the CIM cmdlets;
    runs on Windows PowerShell 5.1 and PowerShell 7. Invoke-WebRequest is called with
    -UseBasicParsing and a five-second timeout. No admin rights needed.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/General/ncsidiag-Package.ps1.
#>
$NCSIProbeHost = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeHost
$NCSIDNSAddress = (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveDnsProbeHost

try {
    $ResolvedNCSIProbeHost = Resolve-DnsName -Name $NCSIProbeHost -DnsOnly -Type A -ErrorAction Stop
    $ResolvedNCSIProbeHostname = @($ResolvedNCSIProbeHost)[0].Name
    $NCSIIPAddresses = $ResolvedNCSIProbeHost.ipaddress -join "|"
}
catch {
    # A failed DNS lookup still yields defined (empty) columns, not a crash or a blank row.
    $ResolvedNCSIProbeHostname = ''
    $NCSIIPAddresses = ''
}

try {
    $ResolvedDNSHost = Resolve-DnsName -Name $NCSIDNSAddress -DnsOnly -Type A -ErrorAction Stop
    $ResolvedDNSHostname = $ResolvedDNSHost.Name
    $ResolvedDNSIPAddress = $ResolvedDNSHost.ipaddress
}
catch {
    # A failed DNS lookup still yields defined (empty) columns, not a crash or a blank row.
    $ResolvedDNSHostname = ''
    $ResolvedDNSIPAddress = ''
}

try {
    if ( (Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri ("http://{0}/{1}" -f (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeHost,
                (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbePath)
        ).Content -eq (Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet).ActiveWebProbeContent ) { 

        # IP4 web request was successful
        
        Write-Verbose 'IP4 web probe succeeded.'
        
        $ProbeResults = $true 

    }
    else {
        # A content mismatch (for example a captive portal) is a defined False, not empty.
        Write-Verbose 'IP4 web probe content did not match.'
        $ProbeResults = $false
    }
}
catch {
    # Ignore errors

    Write-Verbose 'IP4 web probe failed.'
    $ProbeResults = $false 

}

$Networks = @()
try {
    $Networks = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -ErrorAction Stop |
        Where-Object { $_.IPEnabled }
}
catch {
    Write-Warning "Error occurred while querying."
}
$OutputObj = @()
foreach ($Network in $Networks) {
    $IPv4Addresses = @($Network.IpAddress) | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' }
    if (-not $IPv4Addresses) {
        # No IPv4 address on this adapter: there is no network to compute.
        continue
    }
    [ipaddress] $IPAddress = $IPv4Addresses[0]
    $IPv4Subnet = @($Network.IPSubnet) | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' } | Select-Object -First 1
    if (-not $IPv4Subnet) {
        # No IPv4 subnet to pair with the address: skip rather than compute a wrong mask.
        continue
    }
    [ipaddress] $SubnetMask = $IPv4Subnet
    [ipaddress] $NetAddr = ($IPAddress.Address -band $SubnetMask.Address)
    $GatewayMetric = @($Network.GatewayCostMetric)[0]
    if ($null -eq $GatewayMetric) {
        # No default gateway on this adapter: it cannot be the primary route.
        continue
    }
    $RouteCostMetric = [int]$GatewayMetric
    $OutputObj += [pscustomobject]@{
        IPAddress       = $IPAddress
        SubnetMask      = $SubnetMask
        Network         = $NetAddr
        RouteCostMetric = $RouteCostMetric
    }
}
$PrimaryIP = $OutputObj | Sort-Object -Property RouteCostMetric | Select-Object -First 1

Write-Output "$ResolvedNCSIProbeHostname, $NCSIIPAddresses, $ProbeResults, $ResolvedDNSHostname, $ResolvedDNSIPAddress, $($PrimaryIP.Network)"
