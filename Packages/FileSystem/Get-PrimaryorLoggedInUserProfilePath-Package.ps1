$InventoryFile = 'C:\Program Files (x86)\Tanium\Tanium Client\Tools\ADQuery\Inventory.xml'
$ProfilePath = ''
[xml]$Inventory = Get-Content -Path $InventoryFile
$PrimaryUserAccountSid = ($Inventory.SelectNodes("//Tanium/users/user") | Where-Object { $_.primaryUser -eq 'yes' }).properties.objectSid
$PrimaryUserAccountPath = (Get-CimInstance -Class "Win32_UserProfile" -Namespace root\CimV2 -Filter "SID = '$PrimaryUserAccountSid'").LocalPath

If (($PrimaryUserAccountPath -notmatch 'C:\\Users') -or ($Null -eq $PrimaryUserAccountPath)) {
$ProfilePath = (Get-CimInstance -Class "Win32_UserProfile" -Namespace root\CimV2 -Filter "Special = 'False' and LastUseTime != NULL" |
        Sort-Object -Property LastUseTime |
            Select-Object -Last 1).LocalPath
}
Else {$ProfilePath = $PrimaryUserAccountPath}
$ProfilePath