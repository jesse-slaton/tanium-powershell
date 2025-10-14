#================================================
# Collect User and Computer Client Authentication Certificates
# Set-ClientAuthenticationCertstoJSON.ps1
#================================================

$OutputDir = 'C:\DesktopSupportTools\TaniumOutput'
$CertJSON = $OutputDir + '\ClientAuthenticationCerts.json'
$Paths = @("Cert:\CurrentUser\My","Cert:\LocalMachine\My")
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
    $certs = Get-ChildItem -Recurse -Path $Path `
        | Where-Object { $_.Issuer -match 'IssuingPolicy' `
         -and $_.EnhancedKeyUsageList.count -eq 1 `
         -and $_.EnhancedKeyUsageList.FriendlyName -match 'Client Authentication' 
         }
    foreach ($cert in $certs) {
        $ArrayofCerts += $cert | Select-Object `
            @{n = "Issued to"; e = {If ($null -eq $_.DnsNameList.Unicode) {$_.Subject -replace 'E\=(.*\.com).*', '$1'} Else {$_.DnsNameList.Unicode}}}, `
            @{n = "Issued by"; e = {$_.Issuer -Replace '^CN=|,.*$'}}, `
            @{n = "Expiration"; e = {$_.NotAfter.ToString("r")}}, `
            @{n = "Purpose"; e = {$_.EnhancedKeyUsageList.FriendlyName}}, `
            @{n = "Template"; e = {($_.Extensions | Where-Object {$_.oid.Friendlyname -match "Certificate Template Information"}).Format(0) -replace "(.+)?=(.+)\((.+)?", '$2'}}, `
            @{n = "Thumbprint"; e = {$_.Thumbprint}}, `
            @{n = "Certificate Path"; e = { $cert.PSParentPath -replace '^.*::|,.*$' }}          
        }
    }

Try {
    $ArrayofCerts | ConvertTo-Json | Out-File -FilePath $CertJSON -Force -ErrorAction Stop | Out-Null
}
Catch {
    Write-Error $_.Exception.Message -ErrorAction Stop
    [Environment]::Exit($_.Exception.HResult)   
}

Try {
    $TestContent = ConvertFrom-Json (Get-Content -Path $CertJSON -Raw -ErrorAction Stop)
}
Catch {
    Write-Error "Failed to export content"
    Write-Error $_.Exception.Message -ErrorAction Stop
    [Environment]::Exit($_.Exception.HResult)   
}
