function GetTaniumDir {
  # Return Tanium Client Path from the Registry or $null
  $Error.Clear()
  $TaniumDir = $null
  if ($TaniumDir -eq $null) { if ((Test-Path 'HKLM:\Software\Tanium\Tanium Client')) {$TaniumDir = (Get-ItemProperty 'HKLM:\Software\Tanium\Tanium Client' | Select-Object -ExpandProperty Path)}}
  if ($TaniumDir -eq $null) { if ((Test-Path 'HKLM:\Software\Wow6432Node\Tanium\Tanium Client')) {$TaniumDir = (Get-ItemProperty 'HKLM:\Software\Wow6432Node\Tanium\Tanium Client' | Select-Object -ExpandProperty Path)}}
  if ($TaniumDir -eq $null) { if ((Test-Path 'HKLM:\Software\McAfee\Real Time')) {$TaniumDir = (Get-ItemProperty 'HKLM:\Software\McAfee\Real Time' | Select-Object -ExpandProperty Path)}}
  if ($TaniumDir -eq $null) { if ((Test-Path 'HKLM:\Software\Wow6432Node\McAfee\Real Time')) {$TaniumDir = (Get-ItemProperty 'HKLM:\Software\Wow6432Node\McAfee\Real Time' | Select-Object -ExpandProperty Path)}}
  if ($TaniumDir -eq $null -and $Error) {
    $Message = "Failed to find Tanium Client directory."
    Write-Log -Message $Message -Level "Fatal"
    Write-Log -Message $Error[0].Message -Level 'Fatal'
    if ($logging -eq 'Log to share (default)') {
      MoveLog
    }
    throw "${Message} Error: $_"
  }
  $Error.Clear()
  $TaniumDir
} # End GetTaniumDir
Function Write-Log() {
    <#
    .SYNOPSIS
    Writes out passed error messages to errors.log in the current execution directory.
    .DESCRIPTION
    This function applies a timestamp and sets a passed error description into a defined error.log file in the
    current scripts execution directory.  Message type 1 is informational, type 2 is for errors.  Default exit
    behavior is $False.
    Usage: Write-Log 'Some text about the issue.' 2 $True
    Output: 8/26/2017 12:27:55 AM: Some text about the issue.
    #>

    Param(
        [String]
        $Message,

        [Int]
        $Type,

        [Boolean]
        $Exit = $False
    )

    Filter Log-Time {"$(Get-Date -Format G): $_"}
    $LogName = (get-location).Path + "\" + "GatherExchData.log"

    Switch ($Type){
        1 { Write-Output "Info: $Message" | Log-Time >> "$LogName"}
        2 { Write-Output "ERROR: $Message" | Log-Time >> "$LogName" }
    }

    If($Exit){
        Exit
    }
}
Function Write-ExchServerInfo() {
    Param(
        [String]
        $DataOutput


    )


    $ExchDataFile = (GetTaniumDir) + "\Tools\MSExchData\Exch.conf"

    If (!(get-item ((GetTaniumDir) + "\Tools\MSExchData") -ErrorAction SilentlyContinue))
     {
        Write-Log -Message "Creating Tools\MSExchData Directory" -Type 1
        New-Item -ItemType Directory -Path ((GetTaniumDir) + "\Tools\MSExchData") | Out-Null
        }
    If (get-item $ExchDataFile -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -le (get-date).AddMinutes(-10)}) {
        Write-Log -Message "Removing Old ExchOutput File" -Type 1
        Remove-Item $ExchDataFile -Force -ErrorAction SilentlyContinue


        }

    write-output $DataOutput | out-file $ExchDataFile -Append
    Write-Log $DataOutput
}
Function Write-ExchData() {
    Param(
        [String]
        $DataOutput


    )


    $ExchDataFile = (GetTaniumDir) + "\Tools\MSExchData\ExchData.dat"

    If (!(get-item ((GetTaniumDir) + "\Tools\MSExchData") -ErrorAction SilentlyContinue))
     {
        Write-Log -Message "Creating Tools\MSExchData Directory" -Type 1
        New-Item -ItemType Directory -Path ((GetTaniumDir) + "\Tools\MSExchData") | Out-Null
        }
    If (get-item $ExchDataFile -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -ge (get-date).AddMinutes(-10)}) {
        Write-Log -Message "Removing Old ExchData File" -Type 1
        Remove-Item $ExchDataFile -Force -ErrorAction SilentlyContinue


        }

    write-output $DataOutput | out-file $ExchDataFile -Encoding unicode -Force
    Write-Log $DataOutput -Type 1
}
Function Check-IsExchangeServer {

    If (get-service -Name "MSExchangeServiceHost" -ErrorAction SilentlyContinue)
        {
            Write-log -Message "Found MSExchangeServiceHost, continuing process" -Type 1
            write-output $True
        }
    Else {  Write-output $False
    }
    }
function Get-ExchFromAD {


    [OutputType([psobject])]
    param ()

    BEGIN
    {

        $DefaultErr = 'Unable to get the Exchange Information from the Active Directory!'
        $ErrorAction = 'SilentlyContinue'
        $STOP = 'Stop'


        try
        {
            $LDAPQRY = (New-Object -TypeName adsisearcher -ArgumentList ([adsi]"LDAP://$(([adsi]'LDAP://rootdse').configurationNamingContext)"), '(&(objectclass=msExchPowerShellVirtualDirectory)(msexchinternalhostname=*))')
        }
        catch
        {

            Write-Output "No Data from Active Directory"

        }

        if (-not ($LDAPQRY))
        {



            Write-Output "No Data from Active Directory"

        }


        $Data = @()
    }

    PROCESS
    {
        try
        {
            $LDAPQRY.findall() | Sort-Object -Descending -Property {
                $_.properties.msexchversion[0]
            } | ForEach-Object -Process {

                $SPACE = ' '
                $COMMA = ','

                if ($_.properties.msexchinternalhostname[0])
                {
                    if ($_.properties.distinguishedname[0])
                    {
                        $LDAPPath = ($_.properties.distinguishedname[0] -split $COMMA)[3 .. 100] -join $COMMA

                        try
                        {
                            $ExchServerObject = [adsi]"LDAP://$LDAPPath"
                        }
                        catch
                        {
                            $ExchServerObject = $null
                        }

                        if ($ExchServerObject)
                        {
                            if ($ExchServerObject.serialnumber[0])
                            {
                                $ExchAdminVersion = $ExchServerObject.serialnumber[0]
                            }
                            else
                            {
                                $ExchAdminVersion = $null
                            }

                            if (($ExchServerObject.serialNumber -split $SPACE)[1])
                            {
                                $ExchVersion = ($ExchServerObject.serialNumber -split $SPACE)[1]
                            }
                            else
                            {
                                $ExchVersion = $null
                            }

                            if ($ExchServerObject.name[0])
                            {
                                $ExchServer = $ExchServerObject.name[0]
                            }
                            else
                            {
                                $ExchServer = $null
                            }


                        }

                        if ($_.properties.msexchinternalhostname[0])
                        {
                            If ($_.properties.msexchinternalhostname[0].GetType().Name -like "*byte*"){$httpURI = [System.Text.Encoding]::ASCII.GetString($_.properties.msexchinternalhostname[0])}
                            Else {$httpURI = $_.properties.msexchinternalhostname[0]}

                            $outputObject = @{
                                TypeName = 'psobject'
                                Property = @{
                                    path    = $httpURI
                                    server  = $ExchServer
                                    version = $ExchVersion
                                    Fullver = $ExchAdminVersion
                                }
                            }

                            $ExchInfo = (New-Object @outputObject)
                            write-output $ExchInfo
                            write-log -Message $ExchInfo -Type 1
                            $Data = $ExchInfo




                        }
                    }
                }
            }
        }
        catch
        {

           Write-output "No Data from Active Directory"
        }
    }

    END
    {

        if ($Data)
        {

        }
        else
        {



            Write-output "No Data from Active Directory"

        }
    }
} # End Get-ExchFromAD
Function Pre-Work {
If (Check-IsExchangeServer -eq $True){

$FailureMessage = "No Data from Active Directory"

Try {
    $serverinfo = Get-ExchFromAD
    }
Catch {
    Write-Log $FailureMessage -Type 2
    }
Finally {


If ($serverinfo.GetType().Name -eq "PSCustomObject"){


    Write-ExchServerInfo ($serverInfo.path + ";" + $serverinfo.server + ";" + $serverinfo.version)
}
ElseIf ($serverinfo.GetType().BaseType.Name -eq "Array"){

    Foreach ($serverObject in $serverinfo){
     $dataoutput = ($serverObject.path + ";" + $serverObject.server + ";" + $serverObject.version)


        Write-ExchServerInfo -DataOutput $dataoutput.ToString()

    }
}

Else {  write-output "test" ;  Write-Log -Message $FailureMessage -Type 2}

}
}
Else { write-output "Not Exchange Server" ; exit}
}
Function Main {
    $exchinfofile = ((GetTaniumDir).tostring() + "\Tools\MSExchData\Exch.conf")
If (test-path -Path $exchinfofile) {
        $ExchCmdletOutput = $null

    Try{
        Start-Sleep -Seconds (Get-Random -Minimum 2 -Maximum 20)

        $values = import-csv $exchinfofile -Delimiter ";" -Header "uri","ComputerName","version" | sort Version -Descending
        $relaxed=New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri ($values)[0].uri -Authentication Kerberos -SessionOption $relaxed -WarningAction SilentlyContinue  -ErrorAction silentlycontinue
        Import-PSSession $Session -WarningAction SilentlyContinue -DisableNameChecking -CommandName Get-ExchangeServer -ErrorAction silentlycontinue| out-null
        $ExchCmdletOutput = get-exchangeserver -ErrorAction silentlycontinue |Where {$_.name -like "*$env:computername*"} | select Site, ServerRole, Edition, AdminDisplayVersion
       }
    Catch{

        Write-Log -message "Failed to create pssession" -Type 2
        Write-log -Message $Error[0] -Type 2
        Write-ExchData -DataOutput "Failed: Check Exchange Servers are Members of View-Only Organization Management AD Group"

        }

        If ($ExchCmdletOutput -ne $null){

            Write-ExchData -DataOutput ($ExchCmdletOutput.Site + "|" + $ExchCmdletOutput.Edition + "|" + $ExchCmdletOutput.ServerRole + "|" + $ExchCmdletOutput.AdminDisplayVersion)
            $Session | Remove-PSSession -Confirm:$false
            }
    }

Else {

    Write-Log -Message "No Active Directory Information Present" -Type 2 -Exit
    }
}

Pre-Work


Main
