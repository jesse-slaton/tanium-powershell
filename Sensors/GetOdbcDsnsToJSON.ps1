$DSNNames = Get-OdbcDsn | Select-Object Name
foreach ($DSNName in $DSNNames) {
    Get-OdbcDsn -Name "$($DSNName.Name)" | ConvertTo-Json -Depth 100 | Out-File "C:\DesktopSupportTools\$($DSNName.Name).json"
}