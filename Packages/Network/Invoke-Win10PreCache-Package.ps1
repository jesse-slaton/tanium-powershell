<#
.Synopsis
    Pre-Cache Windows 10 In Place Upgrade bits
.DESCRIPTION
    Tanium Deploy wrapper script for a Microsoft Windows 10 In Place Upgrade - Part 1 - Pre Cache files
.NOTES
    Copyright Tanium, All rights Reserved
    Add this script *AND* a WIndows 10 Deployment Media ( Extracted ISO, ZIP, or ISO ) to the Deploy Package
    Ensure client has Anti-Virus Exceptions for c:\deploy
.LINK
    https://tanium.com/products/deploy/
    https://microsoft.com/Deployment
.Parameter Path
    Target Directory, for extracted WIM file
#>

[cmdletbinding()]
param(
    [string] $osdPath = 'c:\deploy\Tanium\OS',
    [string] $RegKey = '%TANIUMROOT%\Tanium Client\OSD',
    [string] $ImageName = 'Windows 10 Enterprise',
    [switch] $forcePhase3
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

if ( test-path $TaniumRegKey ) {
    # Backup $TaniumRegKey to $TaniumRegKey.[1..1000]
    $BakKey = 1
    while ( test-path "$($TaniumRegKey).$($BakKey)" ) { $BakKey++ }
    Move-item $TaniumRegKey "$($TaniumRegKey).$($BakKey)"
}

New-item -Path $TaniumRegKey -force | out-null
Set-ItemProperty -Path $TaniumRegKey -Name Status -Value 'Ready to Install'


function Set-ACL{
write-verbose "Reset ACLs"
& TakeOwn.exe /F "$osdPath" /A /R /D N
& icacls "$osdPath" /inheritance:r /grant:r "*S-1-5-18:(OI)(CI)F" /Q
& icacls "$osdPath" /grant:r "*S-1-5-18:(OI)(CI)F" /T /grant:r "*S-1-5-32-544:(OI)(CI)F" /T /Q
& icacls "$osdPath\setup.exe" | write-output
}


if ( Test-Path $osdPath ) {
    Write-Host "Clean $osdPath Folder"
    Remove-Item -Recurse -Force $osdPath
}

new-item -ItemType Directory $osdPath
Set-ACL

#endregion

#region Extract install bits to local folder

$excludeFiles = @('Invoke-Win10CompatScan.ps1')

if ( $FoundISO = Get-childItem -path $PSScriptRoot -filter *.iso -Recurse | sort length | Where-Object { $_.Length -gt 2gb } | Select -last 1 ) {

    Write-Host "Found ISO Image, need to extract: $($FoundISO.FullName)"

    #region 7zip

    Write-Host "7za.exe does not provide native ISO extraction tools, use the Full 7zip version."
    $foundFull7Zip = get-childitem $PSScriptRoot -filter 7z* -recurse | ? { $_.Name -match '^7[zZ][iI]?[pP]?[0-9]{0,5}(\-x64)?\.(msi|exe)' } | Select -First 1
    if ( -not $foundFull7Zip ) {
        throw "Please attach 7zip download to Phase1 Package. Example https://www.7-zip.org/a/7z1900.exe or https://www.7-zip.org/a/7z1900.msi"
    }

    Write-Verbose "'$PSScriptRoot\..\..\..\..\7za.exe' e '$($foundFull7Zip.FullName)' *7z.exe *7z.dll -o'$env:temp'"
    & "$PSScriptRoot\..\..\..\..\7za.exe" e "$($foundFull7Zip.FullName)" *7z.exe *7z.dll "-o$env:temp" -y

    if ( Test-Path  "$env:temp\_7z.exe" ) { move  "$env:temp\_7z.exe"  "$env:temp\7z.exe" -Force }
    if ( Test-Path  "$env:temp\_7z.dll" ) { move  "$env:temp\_7z.dll"  "$env:temp\7z.dll" -Force }

    #endregion

    Write-Host "'$env:temp\7z.exe' x $FoundISO.FullName -o'$osdPath'"
    if ( Test-Path "$env:temp\7z.exe" ) {
        & "$env:temp\7z.exe" x "$($FoundISO.FullName)" "-o$($osdPath)" -y
        Remove-Item "$env:temp\7z.exe","$env:temp\7z.dll" -ErrorAction SilentlyContinue | out-null
    }
    else {
        throw "Unable to extract *7z.exe from install package $($foundFull7Zip.FullName)"
    }

}
elseif ( $FoundWIM = get-childitem -Recurse -path $PSScriptRoot -filter install.wim -ErrorAction SilentlyContinue | Where-Object { $_.length -gt 2GB } | Select-Object -First 1 ) {

    Write-Host "Found Local Install.Wim file at $($FoundWIM.fullname)"

    $OSInstallRoot = Split-Path ( Split-Path $FoundWIM.FullName )

    if ( ( Test-Path $OSInstallRoot\Sources\Install.wim ) -and ( Test-Path $OSInstallRoot\setup.exe  ) ) {
        Write-Host "Basic copy of ISO extracted Media $OSInstallRoot"

        New-Item -ItemType Directory -Path $osdPath -ErrorAction SilentlyContinue -Force | Out-Null
        Get-Item $OSInstallRoot\* | Where-Object {$excludeFiles -notcontains $_.Name} | Move-Item -Destination $osdPath -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Verbose "This is not a ISO extracted Media. Find the Setup.exe..."

        if ( $FoundSetup = get-childitem -Recurse -path $PSScriptRoot -filter setup.exe -ErrorAction SilentlyContinue | Select-Object -First 1 ) {
            Write-Host "Found the [$($FoundSetup.FullName)] file. Now Merge..."
            $OSInstallRoot = Split-Path $FoundSetup.FullName

            New-Item -ItemType Directory -Path $osdPath -ErrorAction SilentlyContinue -Force | Out-Null
            Get-Item $OSInstallRoot\* | Where-Object {$excludeFiles -notcontains $_.Name} | Move-Item -Destination $osdPath -Force -ErrorAction SilentlyContinue

            $FoundWim | Move-Item -Destination $osdPath\Sources -Force -ErrorAction SilentlyContinue

        }
        else {
            throw "Missing Setup.Exe. Package must have *BOTH* Install.wim and Setup.exe"
        }

    }

}
elseif ( $FoundESD = get-childitem -Recurse -path $PSScriptRoot -filter *.esd -ErrorAction SilentlyContinue | Sort-Object length | Where-Object { $_.length -gt 2GB } | Select-Object -First 1 ) {

    Write-Host "Found Local Install.esd file at $($FoundESD.fullname)"

    $OSInstallRoot = Split-Path ( Split-Path $FoundESD.FullName )

    if ( ( $FoundESD.Name -eq 'install.esd' ) -and ( Test-Path $OSInstallRoot\Sources\Install.ESD ) -and ( Test-Path $OSInstallRoot\setup.exe  ) ) {
        Write-Host "Basic copy of ISO extracted Media $OSInstallRoot"

        New-Item -ItemType Directory -Path $osdPath -ErrorAction SilentlyContinue -Force | Out-Null
        Get-Item $OSInstallRoot\* | Where-Object {$excludeFiles -notcontains $_.Name} | Move-Item -Destination $osdPath -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Verbose "This is not a ISO extracted Media. Find the Setup.exe..."

        if ( $FoundSetup = get-childitem -Recurse -path $PSScriptRoot -filter setup.exe -ErrorAction SilentlyContinue | Select-Object -First 1 ) {
            Write-Host "Found the [$($FoundSetup.FullName)] file. Now Merge..."
            $OSInstallRoot = Split-Path $FoundSetup.FullName

            New-Item -ItemType Directory -Path $osdPath -ErrorAction SilentlyContinue -Force | Out-Null
            Get-Item $OSInstallRoot\* | Where-Object {$excludeFiles -notcontains $_.Name} | Move-Item -Destination $osdPath -Force -ErrorAction SilentlyContinue

            $FoundESD | Move-Item -Destination $osdPath\Sources\install.esd -Force -ErrorAction SilentlyContinue

        }
        else {
            Write-Host "OK, this esd file is not extracted from a ISO image, and there is no coresponding Setup.exe. Assume this is a compressed package."

            Write-Host "Found ESD Image, need to mount and extract $($FoundESD.FullName) to $osdPath"

            new-item -ItemType Directory -path $osdPath -Force -ErrorAction SilentlyContinue | out-null

            dism.exe /Apply-image  /ImageFile:"$($FoundESD.FullName)"       /Index:1                  /ApplyDir:"$osdPath" | out-null
            Dism.exe /export-image /SourceImageFile:"$($FoundESD.FullName)" /SourceIndex:3            /DestinationImageFile:"$osdPath\Sources\Boot.wim" | out-null
            Dism.exe /export-image /SourceImageFile:"$($FoundESD.FullName)" /SourceName:"$ImageName"  /DestinationImageFile:"$osdPath\Sources\install.wim" | out-null

        }

    }

}
else {

    Write-Host "No sources found!"
    dir $PSScriptRoot | Out-String -Width 200 | Write-Host

}

if ( -not ( ( Test-Path $osdPath\sources\install.wim ) -or ( Test-Path $osdPath\sources\install.esd ) ) ) {
    throw "Missing Sources $osdPath\Sources\Install.wim"
}

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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnJrb98t5v98ouaOfmCZGgXE3
# 5EqgghSUMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
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
# BgkqhkiG9w0BCQQxFgQUdIFIP59kpjSTCKAFDG4xJHdDtQgwDQYJKoZIhvcNAQEB
# BQAEggEACaf3rI/opqLPI2xY/2gjh4XUJaYYTEgaUAgPPw8S+L6qUUgj0vz1RLtx
# Xf0a0qjwcoEZ4ix/KxW0F9j+ZR2Es3yFLWY8KEmQH00U57MRWQNmyfFNacFREV48
# DaXgkMxTj65oGKnJCF6cyOfY8a9AUr5ON+xzDzPqlAB1O89cykPtTu5h8jE/gbFf
# 36+DrkSdWG0PhFd3xDIsvzvOzxDJhhXPFfeBb99BIR8mLI603WfbcWdTzvTs9or2
# 17X9zI88TqOuWG1yHXIpBje1xMnyBGFh91uhMcl5KNt8kyBFBt65GeUcAIUW+iQF
# iktaGp1EBPB4KI5JcrhaBBFEmckHH6GCAjAwggIsBgkqhkiG9w0BCQYxggIdMIIC
# GQIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkw
# FwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEy
# IEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMA0G
# CWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG
# 9w0BCQUxDxcNMjEwNTE5MTgxODM4WjAvBgkqhkiG9w0BCQQxIgQgZAjTmbo8F53m
# jBsOW2LzaPN0Up7gPLU6BpKBQrt/VCYwDQYJKoZIhvcNAQEBBQAEggEAmwP5arH7
# c34gtInLUQA6pLW4G3Q0SiAAIdImGohBp4Unpb75nw21qoVGf0ywTyzXe+yt4AjL
# CAlweydOGVQ/lnWcLyVKBXahtkMohjiUZM44QEwMx386ws5wLASPuUGh3+LTVrEW
# rvBpN92ZJ/TfO3HmSxvCbMf1D7E+39lDzeQV1tADMnqZPUi9v3jfro7NUbCJURQ2
# UnuZJcI+zBbYtFRfkGfwmbQY33VIQ+S6q3LNv4z/MdFVL0r6rtpOD3AT5qoz0qBN
# XB8KnJbnRy45V1FPBRYo8c0pRj8htHOV4YSsOaTOlhWmBK/b6SotIUm0/+9Yy8p6
# TKQjSn7be2k6IQ==
# SIG # End signature block
