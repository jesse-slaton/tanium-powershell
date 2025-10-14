$RegEx = '^CN=(.+?),(?:CN|OU)=.+'
$InventoryFile = 'C:\Program Files (x86)\Tanium\Tanium Client\Tools\ADQuery\Inventory.xml'
[xml]$Inventory = Get-Content -Path $InventoryFile
$PrimaryUser = $Inventory.SelectNodes("//Tanium/users/user") | Where-Object { $_.primaryUser -eq 'yes' }
[string]$Manager = $PrimaryUser.properties.manager -replace $RegEx, '$1'
[string]$ManagerCN = $PrimaryUser.properties.manager
Write-Output "$Manager|$ManagerCN"