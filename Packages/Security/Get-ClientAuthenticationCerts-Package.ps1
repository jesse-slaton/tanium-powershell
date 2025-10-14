#================================================
# Collect User Client Authentication Certificates
# Get-ClientAuthenticationCerts.ps1
#================================================

$OutputDir = 'C:\DesktopSupportTools\TaniumOutput'
$Paths = @("Cert:\CurrentUser\My", "Cert:\LocalMachine\My")
$ArrayofCerts = @()

if (!(Test-Path $OutputDir)) {
    Try {
        New-Item -ItemType Directory -Force -Path $OutputDir -ErrorAction Stop | Out-Null
    }
    Catch {
        Write-Error $_.Exception.Message -ErrorAction Stop
        [Environment]::Exit($_.Exception.HResult)   
    }
}

foreach ($Path in $Paths) {
    Try { Test-Path -Path $Path -ErrorAction Stop | Out-Null }
    Catch {
        Write-Error $_.Exception.Message -ErrorAction Stop
        [Environment]::Exit($_.Exception.HResult)
    }
    $ClientAuthCertificates = Get-ChildItem -Recurse -Path $Path `
    | Where-Object { $_.Issuer -match 'IssuingPolicy' `
            -and $_.EnhancedKeyUsageList.count -eq 1 `
            -and $_.EnhancedKeyUsageList -match 'Client Authentication' 
    }
    foreach ($certificate in $ClientAuthCertificates) {
        $ArrayofCerts += $certificate | Select-Object `
        @{n = "Issued to"; e = { $_.DnsNameList.Unicode } }, `
        @{n = "Issued by"; e = { $_.Issuer -Replace '^CN=|,.*$' } }, `
        @{n = "Expiration"; e = { $_.NotAfter.ToShortDateString() } }, `
        @{n = "Purpose"; e = { $_.EnhancedKeyUsageList.FriendlyName } }, `
        @{n = "Template"; e = { ($_.Extensions | Where-Object {
                        $_.oid.Friendlyname -match "Certificate Template Information" }).Format(0) `
                    -replace "(.+)?=(.+)\((.+)?", '$2' }
        }, `
        @{n = "Thumbprint"; e = { $_.Thumbprint } }, `
        @{n = "Certificate Path"; e = { $_.PSParentPath -replace '^.*::|,.*$' } }, `
        @{n = "FullName"; e = { $_.PSPath -replace "(^.*::|,.*$)", 'Cert:' } }     
    }
}

Try {
    #$CSV = ($ArrayofCerts | ConvertTo-Csv -Delimiter "|" -NoTypeInformation).Replace("`"", "")
    #$CSV[1..($CSV.Length)]
    $ArrayofCerts | ConvertTo-Json -Depth 100 | Set-Content -Path "$OutputDir\ClientAuthCerts.json"
}
Catch {
    Write-Error $_.Exception.Message -ErrorAction Stop
    #[Environment]::Exit($_.Exception.HResult)   
}

