
<#
.Synopsis
    Compatibility Scan for Windows 10 In Place Upgrade
.DESCRIPTION
    Tanium Deploy wrapper script for a Microsoft Windows 10 In Place Upgrade - Part 2 - Compatibility Scan
.NOTES
    Copyright Tanium, All rights Reserved
    Add this script *AND* a WIndows 10 Deployment Media ( Extracted ISO, ZIP, or ISO ) to the Deploy Package
    Ensure client has Anti-Virus Exceptions for c:\deploy
.LINK
    https://tanium.com/products/deploy/
    https://microsoft.com/Deployment
.Parameter Path
    Target Directory, for extracted WIM file
.Parameter RegStatus
    Registry Key for Status Messages
#>

[cmdletbinding()]
param(
    $path = 'c:\deploy\Tanium\OS',
    $RegKey = '%TANIUMROOT%\Tanium Client\OSD',
    $ScanMinutes
)

try { Start-Transcript -path $env:temp\Win10IPU_CompatScan.txt -Append } catch {}

#region Initialize Environment

if ( [IntPtr]::Size -ne 8  ) {
    $TaniumRegKey = $regKey.Replace('%TANIUMROOT%','HKLM:\Software\tanium' )
}
else {
    $TaniumRegKey = $regKey.Replace('%TANIUMROOT%','HKLM:\Software\WOW6432Node\tanium' )
}

new-item $TaniumRegKey -ErrorAction SilentlyContinue | out-null

#endregion

#region Block execution if within $ScanMinutes

if ( $ScanMinutes ) {

    $lastScanTime = Get-ItemProperty -Path $TaniumRegKey -ErrorAction SilentlyContinue | foreach-object { $_.LastScanTime -as [datetime] }

    if ( -not $lastScanTime ) { $lastScanTime = [datetime]'1/1/1970' }

    if ( New-TimeSpan -Start $lastScanTime | where-object { $_.TotalMinutes -lt $ScanMinutes } ) {
        Write-Host "Skip! Last scan was performed at: $LastScanTime"
        return
    }

    Write-host "OK to run again! outside of $ScanMinutes Minutes"

    Set-ItemProperty -Path $TaniumRegKey -Name LastScanTime -Value ( [datetime]::now.ToString('s') )

}

#endregion

#region Run Compat Scan

remove-item -force -Recurse 'C:\$WINDOWS.~BT' -ErrorAction SilentlyContinue

write-host ( [DateTime]::now.ToString('s') + " Begin Setup.exe /compat ScanOnly [...]")

& "$Path\setup.exe" /Auto Upgrade /Quiet /NoReboot /DynamicUpdate Disable /Compat ScanOnly | out-null

write-host ( [DateTime]::now.ToString('s') + " Finished Setup.exe /compat ScanOnly [...]" )

#endregion

#region Parse Exit codes

switch ( $LASTEXITCODE ) {

    0xC1900202  { $CompatReason = 'Compatibility Issues'  }   # QUESTION, if it's not a HARD blocker, should we just let it pass?!?
    { $_ -eq 0xC1900208 -or $_ -eq 0x800F0923 }
                { $CompatReason = 'Compatibility Failed: Hard Block'  }
    { $_ -eq 0x80070070 -or $_ -eq 0xC190020E -or $_ -eq 0x8031004a }
                { $CompatReason = ( 'Insufficient Space: {0:0} GB Free' -f ( (gwmi -query 'SELECT * FROM win32_volume Where DriveLetter = "C:"').FreeSpace / 1gb) ) }
    { $_ -eq 0xC1900204 -or $_ -eq 0xc1900215 }
                { $CompatReason = 'Migration Choice Not Available'  }
    0xC1900200  { $CompatReason = 'Doesn''t Meet Requirements'  }
    0xC1900210  { $CompatReason = 'Passed' }
    default     { $CompatReason = 'Unknown Error: 0x{0:x8}' -f $LASTEXITCODE }

}

Set-ItemProperty -Path $TaniumRegKey -Name LastResult -Value ('0x{0:x2}' -f $LASTEXITCODE) -Force
Set-ItemProperty -Path $TaniumRegKey -Name Status -Value $CompatReason -Force

#endregion

#region Gather results and cleanup

remove-item -Force $path\..\CompatScan.txt -ErrorAction SilentlyContinue | out-null

# Errors

get-childitem 'C:\$WINDOWS.~BT\Sources\Panther\compat*.xml' |
    ? { [datetime]::ParseExact($_.Name.SubString(11,19),'yyyy_MM_dd_HH_mm_ss',$null) -gt [datetime]::now.AddDays(-1) } |
    % {
        [xml]$Compat = type $_.FullName
    
        $Compat.CompatReport.Hardware.HardwareItem |
            ? { $_.CompatibilityInfo.BlockingType -eq 'Hard' } |
            % { $_.CompatibilityInfo.BlockingType + "|" + $_.HardwareType + "|" + ($_.CompatibilityInfo.Name,$_.CompatibilityInfo.Message) -join ':' } |
            out-file -Append -Encoding ascii -FilePath $path\..\CompatScan.txt

        $Compat.CompatReport.Programs.Program |
            ? { $_.CompatibilityInfo.BlockingType -eq 'Hard' } |
            % { $_.CompatibilityInfo.BlockingType + "|" + $_.Name + "|" + $_.CompatibilityInfo.Message } |
            out-file -Append -Encoding ascii -FilePath $path\..\CompatScan.txt

        $Compat.CompatReport.Devices.Device |
            ? { $_.CompatibilityInfo.BlockingType -eq 'Hard' -and $_.CompatibilityInfo.StatusDetail -ne 'WarnUpgrade' } |
            % { $_.CompatibilityInfo.BlockingType + "|" + $_.Name + "|" + ($_.CompatibilityInfo.Message,$_.Manufacturer,$_.Model) -join ' ' } |
            out-file -Append -Encoding ascii -FilePath $path\..\CompatScan.txt

    }

#endregion

#region Summary

$result = 0

write-host ( "Was: " + (Get-ItemProperty -Path $TaniumRegKey | % { $_.Status } ) )
if ( get-item $path\..\CompatScan.txt | % { $_.Length -gt 6 } ) {


    $ErrorOutput = ( Get-Content -Path $Path\..\CompatScan.txt ) -join '~~'

    if ( $ErrorOutput -gt 2 ) {
        Set-ItemProperty -Path $TaniumRegKey -Name ErrorDetails -Value $errorOutput
        Set-ItemProperty -Path $TaniumRegKey -Name Status -Value 'Compat Scan Errors'
    }
    else {
        Set-ItemProperty -Path $TaniumRegKey -Name ErrorDetails -Value "Passed: No error Data"
        Set-ItemProperty -Path $TaniumRegKey -Name Status -Value 'Compat Scan OK'
    }

    $result = 1
}
else {
    Set-ItemProperty -Path $TaniumRegKey -Name ErrorDetails -Value "Passed: No error Data"
    Set-ItemProperty -Path $TaniumRegKey -Name Status -Value 'Compat Scan OK'
}

get-itemproperty -Path $TaniumRegKey | write-host

#endregion

try { Stop-Transcript } catch {}

exit $result

# SIG # Begin signature block
# MIIX9gYJKoZIhvcNAQcCoIIX5zCCF+MCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUai47yzHYV9znUu+Omqhpd6Oa
# vEGgghMpMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUwMIIEGKADAgECAhAECRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9v
# dCBDQTAeFw0xMzEwMjIxMjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNp
# Z25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4R
# r2d3B9MLMUkZz9D7RZmxOttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrw
# nIal2CWsDnkoOn7p0WfTxvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnC
# wlLyFGeKiUXULaGj6YgsIJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8
# y5Kh5TsxHM/q8grkV7tKtel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM
# 0SAlI+sIZD5SlsHyDxL0xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6f
# pjOp/RnfJZPRAgMBAAGjggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGsw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcw
# AoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Um9vdENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDov
# L2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBP
# BgNVHSAESDBGMDgGCmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoK
# o6XqcQPAYPkt9mV1DlgwHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8w
# DQYJKoZIhvcNAQELBQADggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+
# C2D9wz0PxK+L/e8q3yBVN7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119E
# efM2FAaK95xGTlz/kLEbBw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR
# 4pwUR6F6aGivm6dcIFzZcbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4v
# cn4c10lFluhZHen6dGRrsutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwH
# gfqL2vmCSfdibqFT+hKUGIUukpHqaGxEMrJmoecYpJpkUe8wggVYMIIEQKADAgEC
# AhAE4gEAx1y8dKCueh6UpxduMA0GCSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25p
# bmcgQ0EwHhcNMTgwMjE2MDAwMDAwWhcNMjEwMjI0MTIwMDAwWjCBlDELMAkGA1UE
# BhMCVVMxCzAJBgNVBAgTAkNBMRMwEQYDVQQHEwpFbWVyeXZpbGxlMRQwEgYDVQQK
# EwtUYW5pdW0gSW5jLjETMBEGA1UECxMKUG93ZXJzaGVsbDEUMBIGA1UEAxMLVGFu
# aXVtIEluYy4xIjAgBgkqhkiG9w0BCQEWE3NlY3VyaXR5QHRhbml1bS5jb20wggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC0ROosyJVw9SW6HnyT9wuMZjye
# eIMMfg0gMAt4jRKOtxl/LEa0XBtkwQwj1WXXCK1CZELn2ZGQBLGJ9bWu1TQ4iocy
# i7kNNS6sh5DKah4uWRtm2WwrXEZlMUzEOhPa4t05Lb6ugq6oah3g8k6MuTr05CEa
# OsnqBo9+DJh7sLyMYBI9KcKPaK5B7ahjvgO3UWFW2RzHkoNLZX3OnuRqC7kh4dYT
# XcEKu9Nfx30yYMdZVkIWTl8EMCzvpM95dCZogWa7R6ub8PsIf6eLVrfldmh3ow54
# VUA63m+hQhPulheTf9YADbgRl2vtXDAl5uia6EYkwssimJrBjyYRoIoQ4N1bAgMB
# AAGjggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAdBgNV
# HQ4EFgQU+j1xeQtK1FXgoPfGgF2TNXi6QDcwDgYDVR0PAQH/BAQDAgeAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGGL2h0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMDWgM6Axhi9odHRwOi8v
# Y3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDBMBgNVHSAE
# RTBDMDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdp
# Y2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJBc3N1cmVkSURDb2Rl
# U2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQCD
# ZVhNgzeR/I0kp54AkQWisw8fFCq1ANa6bIWN42CHOkjn4+mrsDpIdFPkzLfU2XYj
# FFl0ez8wGc50Sa5HJBnpAwbw+4QVJnUg+6jeEZ1QXYibn4HLbDRxTdv1Ggw4B5X3
# fPiDf7nwFMsLHdRDHxt25XmJuB+ta1nh5zuAbUXxjE6OouQQBu+vorfxMLNnddK9
# bbeMxJgFELDhDyWhclZQaM1bnfihgXX5WC8ASPZV/qAtm4lOqaIGl2ZB9NOSr2gi
# LdEy422+Z8Juy2nE4t9zqD7T+/SYPSgRJi7ozy9SMNJUw02A3zItjqfoH3YCyENp
# BgIlMA2Znf3kwYFLfe1GMYIENzCCBDMCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTAT
# BgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEx
# MC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBD
# QQIQBOIBAMdcvHSgrnoelKcXbjAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUXKFRXei9HIxNPMsT
# P9b87tcTwjQwDQYJKoZIhvcNAQEBBQAEggEAc9Ok2PTpFsTRp3vPJQl2zWRNSYrL
# UbSU8aGsc0Urie4aRm5g30lEkg6gu57yAtbHMoArdMpY7CpdYT/jTtfXRePQna6q
# nVSKhIWSa08Cg/1MQwEqGX3GIsot5exzBCIZBpCdCTbg5yQgvomsAKdNMUx+kw/i
# rJ7eUOQ/8PHaDn7GelJ9WfP8cj0tQvzABKfBi8qd59+pkS3U+2RSqfXcCeAbsY/t
# uH6xI2c9gyTMHq9bdTIpjrbvXc1VMkePbtS1iEU+ELSMju0anL+3cKO6bw5LiA50
# 9QlV/qNhonzeD3Q+xYBDSc4U3mSpMtXatS5zW89fO8+WRvP9fAVEKFdUG6GCAgsw
# ggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYD
# VQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGlt
# ZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkG
# BSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJ
# BTEPFw0yMDA3MzEwNjI0MjNaMCMGCSqGSIb3DQEJBDEWBBRh+uNBtTt8QRgCC7NI
# DIRyyS2NcDANBgkqhkiG9w0BAQEFAASCAQBhxs3ZNyOw9yBmmV1i1iJzyHA5m2zb
# wuGtqN/Wb6j+R98UcuqWcp0xTimhTvS631mSND1xzZKsMX+34WBcHgGx7TTbw4dE
# dB4+Sr29wskvXtR8nblfFNo0v/0+P+rRamQ/Y7GBmKJnIYzs5xs5KVEshK0kSyVn
# hjLO5E8QFKMCMHogub3/ihyBG7NI+Mc4C763G57JMI6ELf0cQr7NqjJJBgusc2I/
# uqm4vvKtIV7PTRUizMJYy6h5ZHoTtoLbbJ7zLe9ocUUq71mMXi9zyqSMZc/6R/mD
# WHaERahoetj4W2hjm/ozPAe4/FzFbPDECEaBXpxLhXC6f6hfhSXAQBVm
# SIG # End signature block
