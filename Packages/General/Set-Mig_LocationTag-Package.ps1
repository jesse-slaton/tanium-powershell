$CSV = '.\ComputerLocations2.txt'
$Paths = @("SOFTWARE\\Tanium\\Tanium Client\\Sensor Data\\Tags", "SOFTWARE\\WOW6432Node\\Tanium\\Tanium Client\\Sensor Data\\Tags")

If (Test-Path -Path $CSV) {
    $ScopeArray = (Import-Csv -Path $CSV -Delimiter ';')

    Try {
        $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration `
            -ErrorAction Stop | Where-Object {$_.IPEnabled}
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
    $LocationData = $ScopeArray | Where-Object {$_.ScopeID -match $PrimaryIP.Network.IPAddressToString} | `
        Select-Object Location, Specific
}

$Paths = @("SOFTWARE\\Tanium\\Tanium Client\\Sensor Data\\Tags", "SOFTWARE\\WOW6432Node\\Tanium\\Tanium Client\\Sensor Data\\Tags")
$LocationTagName = 'MIG_Location'
$LocationTagValue = If ($LocationData.Location) {$LocationData.Location} Else {
    If ($PrimaryIP.Network.IPAddressToString -match '166.*|100.*') {'Air Card/Tethering'}
    ElseIf ($PrimaryIP.Network.IPAddressToString -match '11.*') {'Department of Defense?'}
    Else {'Off Network'}
}
$SpecificTagName = 'MIG_SpecificLocation'
$SpecificTagValue = If ($LocationData.Specific) {$LocationData.Specific} Else {
    $publicip = (Invoke-WebRequest https://api.ipify.org).Content.Trim()
    $baseUrl = 'https://tools.wmflabs.org/whois'
    $url = "$baseurl/$publicip/lookup/json"
    $r = (Invoke-RestMethod -uri $url)
    ($r | Select-Object -ExpandProperty nets).description
}
$CIDR = IF ($r.asn_cidr) {$r.asn_cidr } Else {$NetAddr}
#  Create an instance of the Registry Object and open the HKLM base key
Try {
    $reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64')
}
Catch {
    Write-Error $_
    Continue
}

ForEach ($Path in $Paths) {
    Write-Verbose  "Checking Path: $Path"

    Try {
        $regkey = $reg.OpenSubKey($Path, $True)

        Try {
            $regkey.SetValue($LocationTagName, $LocationTagValue) 
            $regkey.SetValue($SpecificTagName, $SpecificTagValue)
            $regkey.SetValue('MIG_NetworkAddress', $CIDR)
        }  
        Catch {}
    } 
    Catch {}

    $reg.Close()
}