#==============================================================
# Import User Client Authentication Certificates from JSON File
# Get-ClientAuthenticationCertsfromJSON.ps1
#==============================================================

$InputDir = 'C:\DesktopSupportTools\TaniumOutput\'
$CertJSON = $InputDir + 'ClientAuthenticationCerts.json'

Try {
    $JSONFile = ConvertFrom-Json (Get-Content -Path $CertJSON -Raw -ErrorAction Stop)
}
Catch {
    Write-Error $_.Exception.Message -ErrorAction Stop
    [Environment]::Exit($_.Exception.HResult)   
}

iF ($JSONFile.Count -lt 1) {
    Write-Error "Invalid JSON File!" -ErrorAction Stop
} Else {
    $CSVOutput = ($JSONFile | ConvertTo-Csv -Delimiter "|" -NoTypeInformation) -replace '"', ''
    $CSVOutput[1..($CSVOutput.Length)] 
 }