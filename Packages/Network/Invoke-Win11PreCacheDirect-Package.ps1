<#
.Synopsis
    Pre-Cache Windows 10 In Place Upgrade bits
.DESCRIPTION
    Tanium Deploy wrapper script for a Microsoft Windows 10 In Place Upgrade - Part 1 - Pre Cache files
.NOTES
    Copyright Tanium, All rights Reserved
    This script will download the Windows Install esd(ISO) bits DIRECTLY from Windows Update, not from the Tanium Server.
    Ensure the endpoint has Antivirus Exceptions for c:\deploy
	
.LINK
    https://tanium.com/products/deploy/
    https://microsoft.com/Deployment
    https://go.microsoft.com/fwlink/?LinkID=799445
.Parameter Path
    Target Directory, for extracted WIM file
.Parameter BuildNumber
    Use this specific build number (example: 19042). Otherwise latest build is used. Latest revision is default.
#>

[cmdletbinding()]
param(
    [string] $osdPath = 'c:\deploy\Tanium\OS',
    [string] $RegKey = '%TANIUMROOT%\Tanium Client\OSD',
    [string] $ImageName = 'Windows 10 Enterprise',
    [switch] $VersionTesting,
    [switch] $forcePhase3,
    [ValidateRange(17134,32767)]
    [int] $BuildNumber    
)

try { Start-Transcript -path $env:temp\Win10IPU_PreCache.txt -Append } catch {}

#region Initialize and cleanup

if (-not $PSScriptRoot) { $PSScriptRoot = split-path $MyInvocation.MyCommand.Path }   # For Windows 7 and Powershell 2.0

if ( [IntPtr]::Size -ne 8  ) {
    $TaniumRegKey = $regKey.Replace('%TANIUMROOT%','HKLM:\Software\tanium' )
}
else {
    $TaniumRegKey = $regKey.Replace('%TANIUMROOT%','HKLM:\Software\WOW6432Node\tanium' )
}

function Set-ACL{
write-verbose "Reset ACLs"
& TakeOwn.exe /F "$osdPath" /A /R /D N
& icacls "$osdPath" /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" /Q
& icacls "$osdPath" /grant:r "*S-1-5-18:(OI)(CI)F" /T /grant:r "*S-1-5-32-544:(OI)(CI)F" /T /Q
& icacls "$osdPath\setup.exe" | write-output
}

if ( -not $VersionTesting ) {

    write-verbose "Clean..."

    if ( test-path $TaniumRegKey ) {
        # Backup $TaniumRegKey to $TaniumRegKey.[1..1000]
        $BakKey = 1
        while ( test-path "$($TaniumRegKey).$($BakKey)" ) { $BakKey++ }
        Move-item $TaniumRegKey "$($TaniumRegKey).$($BakKey)"
    }
    New-item -Path $TaniumRegKey -force | out-null
    Set-ItemProperty -Path $TaniumRegKey -Name Status -Value 'Ready to Install'
    if ( Test-Path $osdPath ) {
        Write-Host "Clean $osdPath Folder"
        Remove-Item -Recurse -Force $osdPath
    }
}

#endregion

#region Compute Windows Update download Link

$downloadLink = 'https://content.tanium.com/files/tsw/update-map.xml.gz'
$localzip = join-path $env:temp ( split-path -Leaf $downloadLink )
$localxml = join-path $env:temp ( split-path -Leaf ($downloadLink -replace '.gz$','') )

write-verbose "download control file"
Invoke-WebRequest -Uri $downloadLink -OutFile $localzip -UseBasicParsing

write-verbose "Extract datafile"
$input = New-Object System.IO.FileStream $localzip, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
$output = New-Object System.IO.MemoryStream
$gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
$gzipStream.CopyTo( $output )

[xml] $WUData = [System.Text.Encoding]::ASCII.GetString($output.toarray())

$gzipStream.Close()
$output.Close()
$input.Close()

#######################
write-verbose "Determine OS Image Types:"

if (  gwmi win32_operatingSystem | ? ProductType -ne 1 ) { throw "N/A - Server" }
$isFre = 'fre'
$isx64 = if ( [Environment]::Is64BitOperatingSystem ) { 'x64' } else { 'x86' }
$LangUI = [CultureInfo]::InstalledUICulture | select-object -first 1 | % name
$LicType = 'ret'
if ( Get-WmiObject -query "SELECT PartialProductKey, Description FROM SoftwareLicensingProduct WHERE ApplicationID = '55c92734-d682-4d71-983e-d6ec3f16059f'" | ? PartialProductKey | ? Description -match "VOLUME" ) {
    $LicType = 'vol'  
}
if ( -not $BuildNumber ) { [string]$BuildNumber = '[0-9]*' }

$searchPattern = '^https?\:(?>[^\/]*\/)*(?<build>{4})\.(?<revision>[0-9]*)\..*(?<search>{0}_{1}{2}_{3})_(?<sha1>[0-9a-f]*)\.esd$' -f ( $licType, $isx64, $isfre, $langUI, $buildNumber ) 
write-verbose "Search for: $searchPattern"

$FoundESD = $WUData.updates.update.url.'#cdata-section' | % { 
    if ( $_ -match $searchPattern ) { 
        # $matches.remove(0); 
        [pscustomobject]$matches
    }
} | sort -Property @{Expression={[version]::new($_.build,$_.revision)}} | select-object -last 1 

$FoundESD | Out-String -Width 200 | Write-Verbose

if ( $FoundESD.sha1 -notmatch "[0-9a-f]{40}" ) { throw "SHA1 Value mismatch" }

Set-ItemProperty -Path $TaniumRegKey -Name "Windows10UpgradeURL" -Value $FoundESD.0


if ( $versionTesting ) { 
    # For LARGE SCALE Tanium Windows 10 Upgrades: 
    # Extract this script, and run as a package within Tanium. Run with the -versionTesting flag.
    # Then cross check all machines with bitness,language,buildNumber,license (Retail vs VolumeLic)... to verify this script has calculated the correct download link.
    try { Stop-Transcript | Write-Verbose } catch {}
    return
}

#endregion

#region Download Package

write-verbose "Start Bits Transfer"

# Bits should auto-recover. Priority set to "Background Normal"

$localesd = join-path "$osdPath\.." ( split-path -Leaf $FoundESD.0 )
if ( -not ( test-path "$osdPath\.." ) ) { new-item -ItemType Directory -Path "$osdPath\.." -ErrorAction SilentlyContinue | Out-Null } 
Set-ACL
if ( -not ( test-path $localesd ) ) { 

    if ( Get-BitsTransfer | ? displayname -eq $FoundESD.sha1) {
        Write-verbose "BITS already Running: $($FoundESD.sha1)"
        $job = Get-BitsTransfer | ? displayname -eq $FoundESD.sha1
    }
    else {
        $job = Start-BitsTransfer -DisplayName $FoundESD.sha1 -Source $FoundESD.0  -Destination $localesd -Asynchronous -Priority Normal
        start-sleep 10
    }

    $job | out-string | Write-Verbose

    if ( $Job.JobState -eq 'error' ) { throw "Bad download State $localESD" }
    while ( $Job.JobState -match '(Transferring|Connecting|TransientError)' ) { $Percent = try { $Job.BytesTransferred * 100 / $job.BytesTotal } catch { 0 }
        Write-Verbose ("Downloading [$($localesd)] {0:N2}%" -f $Percent)
        write-progress -Activity "Downloading [$($localesd)]" -CurrentOperation ("{0:N2}%" -f $Percent ) -PercentComplete $Percent
        start-sleep 10
    }

    Write-Progress -Activity "FInished $($localesd)" -Completed
    $job | out-string | write-verbose
    $Job | complete-BitsTransfer | write-verbose
    if ( -not ( test-path $localesd ) ) { throw "Missing $localesd" }
}

write-verbose "Bonus, Check the SHA1"
dir $localESD | out-string | Write-Verbose
if ( Get-FileHash -Algorithm SHA1 -Path $localesd | ? hash -ne $FoundESD.sha1 ) { 
    write-verbose "Hash is bad, remove $($localesd), then try again..."
    remove-item -Path $localesd -Force -ErrorAction SilentlyContinue | write-verbose
    throw "Bad Hash on $localesd"
}

#endregion

#region Extract ESD bits

    Write-Host "Found Local Install.esd file at $($localesd) extract to $osdPath"
    new-item -ItemType Directory -path $osdPath -Force -ErrorAction SilentlyContinue | out-null

    dism.exe /Apply-image  /ImageFile:"$($localesd)"       /Index:1                  /ApplyDir:"$osdPath" | out-string | write-verbose
    Dism.exe /export-image /SourceImageFile:"$($localesd)" /SourceIndex:3            /DestinationImageFile:"$osdPath\Sources\Boot.wim" | out-string | write-verbose
    move-item $localesd -Destination "$osdPath\Sources\install.esd"

#endregion

#region Copy Support Files

# Find the PostOOBE.ps1 and/or PostRollBack.ps1 file(s) within this Deploy Package and prep for use during Upgrade.
dir -Recurse -path $PSScriptRoot -filter PostOOBE.ps1 | select-object -first 1 | copy-item -Destination $osdPath\.. -Force
dir -Recurse -path $PSScriptRoot -filter PostRollBack.ps1 | select-object -first 1 | copy-item -Destination $osdPath\.. -Force

# Same for the OEM folder
dir -Recurse -path $PSScriptRoot -filter OEM | where-object { $_.PSIsContainer } | select-object -first 1 | copy-item -Destination $osdPath\.. -Force -Recurse

#endregion

Set-ACL

#region Write-Status

New-Item "$TaniumRegKey\WIM" -Force | Out-Null


get-item "$osdPath\Sources\install.wim","$osdPath\Sources\install.esd" -ErrorAction SilentlyContinue |
    %{ dism /Get-WIMInfo /WimFile:"$($_.fullName)" /index:1 } |
    select-string -Pattern '(.*) : (.*)' -AllMatches |
    % { $_.Matches } |
    % { Set-ItemProperty -path "$TaniumRegKey\WIM" -Name $_.Groups[1].Value -Value $_.Groups[2].value }

if ( $forcePhase3 ) {
    Set-ItemProperty -Path $TaniumRegKey -Name Status -Value 'Compat Scan OK'
}
else {
    Set-ItemProperty -Path $TaniumRegKey -Name Status -Value 'WIM File Copied'
}

get-itemproperty -Path $TaniumRegKey | write-host

#endregion

try { Stop-Transcript } catch {}

exit 0
# SIG # Begin signature block
# MIIZhgYJKoZIhvcNAQcCoIIZdzCCGXMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGK/R6aNWh3Fuwyhh4kaPV0eA
# FjmgghSUMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBSUwggQN
# oAMCAQICEApsRMexcxJHJwozgKuRmMowDQYJKoZIhvcNAQELBQAwcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTAeFw0yMTAyMTgwMDAwMDBaFw0yNDAzMDYyMzU5NTlaMGMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRMwEQYDVQQHEwpFbWVyeXZp
# bGxlMRQwEgYDVQQKEwtUYW5pdW0gSW5jLjEUMBIGA1UEAxMLVGFuaXVtIEluYy4w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQClopxvUwtO/9wXE+s4O2r3
# PM6WwwsSjBuOMs+UNRUUgErQo60bRHgZT0DBgAV+vp6L3iHYSEf6I1tCmSn3rdW0
# fS/NHnzFO4ggqPukYdB1A7dQ6DQwdMxVxXdzUsPkyARIGYLx7DecQ5TEdzbkpq9g
# 2jjM5ACm0etzFU2KWKmCm7/VW3BRL24yaEvXVEqOBOkPugNzSPoUoVlFNPR/Ao9s
# Er89AwyAZ0F48PHXTGRFS1lwgL+VC28iF0ELXaKKz/3OODT21rS7ydh6On4yd/hD
# KhlgKi5Cy/wfUDFlkTlkQC6aQ6WOIhYvLFQZBVX2c4iuTQiUtucgZd5cVMTUeAut
# AgMBAAGjggHEMIIBwDAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAd
# BgNVHQ4EFgQUXUq5tVbzg9KQCh9xDSpkH/iuKNQwDgYDVR0PAQH/BAQDAgeAMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0dHA6Ly9jcmwz
# LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWgM6Axhi9odHRw
# Oi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDBLBgNV
# HSAERDBCMDYGCWCGSAGG/WwDATApMCcGCCsGAQUFBwIBFhtodHRwOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEFBQcBAQR4MHYwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBOBggrBgEFBQcwAoZCaHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRENv
# ZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggEB
# AL3iDKusBRNddWqYzgi4gle9uGbw22VS2KlwUKS4dcYpeOIt1BrI9WD3l6MazbG5
# dOHWQf1gfPRizJbOl7ElC0xW9/pSPqwQyXpYiFfLsR28LprBljklYPBrcIiuMeB6
# tnj0atmCtJz0YNzwn+vumP1oEVtc6WlGqdqwbREm8py0mA4CKzdpUBeagU5Ci7xt
# ZbZfioywPiQAoCYDdaE5cKDeWvQbIqN1q8kFMKMyFPnGBenxVxkProuixnzZaGpZ
# 9uL9Xi2ylkLtd4IkXiynC3ID2QRU8T3V2P4oh6Ir/IkExz0PuOqK60qPdyKfISeF
# bNrTqZ7CKP4YnD10MEFKHDkwggUwMIIEGKADAgECAhAECRgbX9W7ZnVTQ7VvlVAI
# MA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lD
# ZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIxMjAwMDBaFw0yODEwMjIx
# MjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAX
# BgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIg
# QXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IB
# DwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmxOttE9X/lqJ3bMtdx6nad
# BS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfTxvspJ8fTeyOU5JEjlpB3
# gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6YgsIJWuHEqHCN8M9eJNYBi+
# qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tKtel05iv+bMt+dDk2DZDv
# 5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0xY4PwaLoLFH3c7y9hbFi
# g3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGjggHNMIIByTASBgNVHRMB
# Af8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcD
# AzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2lj
# ZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0
# aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENB
# LmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCGSAGG/WwAAgQwKjAoBggr
# BgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAKBghghkgBhv1s
# AzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHwYDVR0jBBgwFoAUReui
# r/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQADggEBAD7sDVoks/Mi0RXI
# LHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBVN7Dh9tGSdQ9RtG6ljlri
# XiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEbBw6RFfu6r7VRwo0kriTG
# xycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZcbEMj7uo+MUSaJ/PQMtA
# RKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRrsutmQ9qzsIzV6Q3d9gEg
# zpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKUGIUukpHqaGxEMrJmoecY
# pJpkUe8wggUxMIIEGaADAgECAhAKoSXW1jIbfkHkBdo2l8IVMA0GCSqGSIb3DQEB
# CwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQg
# SUQgUm9vdCBDQTAeFw0xNjAxMDcxMjAwMDBaFw0zMTAxMDcxMjAwMDBaMHIxCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBU
# aW1lc3RhbXBpbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC9
# 0DLuS82Pf92puoKZxTlUKFe2I0rEDgdFM1EQfdD5fU1ofue2oPSNs4jkl79jIZCY
# vxO8V9PD4X4I1moUADj3Lh477sym9jJZ/l9lP+Cb6+NGRwYaVX4LJ37AovWg4N4i
# Pw7/fpX786O6Ij4YrBHk8JkDbTuFfAnT7l3ImgtU46gJcWvgzyIQD3XPcXJOCq3f
# QDpct1HhoXkUxk0kIzBdvOw8YGqsLwfM/fDqR9mIUF79Zm5WYScpiYRR5oLnRlD9
# lCosp+R1PrqYD4R/nzEU1q3V8mTLex4F0IQZchfxFwbvPc3WTe8GQv2iUypPhR3E
# HTyvz9qsEPXdrKzpVv+TAgMBAAGjggHOMIIByjAdBgNVHQ4EFgQU9LbhIB3+Ka7S
# 5GGlsqIlssgXNW4wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wEgYD
# VR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYB
# BQUHAwgweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5k
# aWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0
# LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4
# oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJv
# b3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRFJvb3RDQS5jcmwwUAYDVR0gBEkwRzA4BgpghkgBhv1sAAIEMCow
# KAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCwYJYIZI
# AYb9bAcBMA0GCSqGSIb3DQEBCwUAA4IBAQBxlRLpUYdWac3v3dp8qmN6s3jPBjdA
# hO9LhL/KzwMC/cWnww4gQiyvd/MrHwwhWiq3BTQdaq6Z+CeiZr8JqmDfdqQ6kw/4
# stHYfBli6F6CJR7Euhx7LCHi1lssFDVDBGiy23UC4HLHmNY8ZOUfSBAYX4k4YU1i
# RiSHY4yRUiyvKYnleB/WCxSlgNcSR3CzddWThZN+tpJn+1Nhiaj1a5bA9FhpDXzI
# AbG5KHW3mWOFIoxhynmUfln8jA/jb7UBJrZspe6HUSHkWGCbugwtK22ixH67xCUr
# RwIIfEmuE7bhfEJCKMYYVs9BNLZmXbZ0e/VWMyIvIjayS6JKldj1po5SMYIEXDCC
# BFgCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hB
# MiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQQIQCmxEx7FzEkcnCjOAq5GYyjAJ
# BgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAj
# BgkqhkiG9w0BCQQxFgQUddGOAvlmMtEnOTuoXDxFJrpTSr8wDQYJKoZIhvcNAQEB
# BQAEggEAotgOypOdBB3Do5gmDUQqrt0wHlk8zXF6OKeUdGr/pnVWFWx9TKukKAsF
# qp1Cr7wQWi6QDNbOzTE61ZtDxYS7986JGIM6HYb3mU2USlzGsgBuXacxDCPtcF1Z
# jRx4NBEe5VtoDASJDHjEOVQ5fQl8gEwUl9mNr9NmPvf8P2KwTaEJNTjzp5iqgqrQ
# eqYB/fjrMbh5QARJ6vrtx25B+tgWsvkUdMYs3Mdey0IHMudV6/TwtjhMAqA5XNVV
# AocrI40NRaRNs4JoOTuMYeNPIQ6ZfRntY5jS0IkyNvykh/yQqyvlJ/jOT13naToy
# kE2nx9ri1sMmFlvm+eHZyDgo6yHYUqGCAjAwggIsBgkqhkiG9w0BCQYxggIdMIIC
# GQIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEy
# IEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMA0G
# CWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG
# 9w0BCQUxDxcNMjEwOTA3MTM1MjM4WjAvBgkqhkiG9w0BCQQxIgQgcUzryt2iTZoa
# mJ6yXnclo6fc0Ec2Wm7xL/Z1WJOSZCswDQYJKoZIhvcNAQEBBQAEggEAa6ubaVkY
# pPea5ClzmJG3pDtzIpqe6k2k/QQ0iWXCjzokhAnMOcK1LcEOXKN11n30UL/ON1wx
# 8uIw5nZEI9qaZCxb03z3RT2bmZMDmaLzdO1bWz2b/kCJsQJU8WjzcD+SmiCrXVBU
# DAp6i+Fb6JAHCf8Ab0ElkYlBCCvoTQPxUI+hRv+R2aCczAx6nI27CLQBY0qKuv2x
# RruEjSPR9lZG1pR9E9Rqs3ySYhOPP7L0cXbGdFfhjSdZkNMcKUhDeA/t4qwb/1Or
# zo5pbJhiBW/keLVNr8dSl7nMNwuqxu/lfEK0/Ue320CugFENfvVhUZn4QzN7ja/U
# cNl7nWBr8H8MiQ==
# SIG # End signature block
