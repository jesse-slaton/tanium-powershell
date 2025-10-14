$WQL = "SELECT SID, LastUseTime FROM Win32_UserProfile Where Special=False AND LastUseTime IS NOT NULL"
$W32UP = Get-CimInstance -Query $WQL | Sort-Object -Property LastUseTime -Descending | Select-Object -First 1  
$DateOutput = (Get-Date -f "ddd, dd MMM yyyy HH:mm zzz" $W32up.LastUseTime) -replace '(.*)(\+|\-)([0-9][0-9]):([0-9][0-9])', '$1$2$3$4'
$RegEx = '^CN=(.+?),(?:CN|OU)=.+'
$InventoryFile = 'C:\Program Files (x86)\Tanium\Tanium Client\Tools\ADQuery\Inventory.xml'
[xml]$Inventory = Get-Content -Path $InventoryFile
$LLUser = $Inventory.SelectNodes("//Tanium/users/user/properties") | Where-Object { $_.objectSid -eq $($W32UP.SID) } `
| Select-Object name, department, co, title, physicalDeliveryOfficeName, mail, telephoneNumber, manager
[string]$Manager = $LLUSER.manager -replace $RegEx, '$1'
$LLUserData = ($LLUser | ConvertTo-Csv -Delimiter "|" -NoTypeInformation).Replace('"', '') | Select-Object -Skip 1
IF ($W32UP.SID) {
    IF ($LLUser.name) { Write-Output "$LLUserData|$Manager|$DateOutput" }
    ELSE { Write-Output "$($W32Up.SID)|||||||||$DateOutput" }
}

