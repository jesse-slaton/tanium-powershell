$InventoryFile = 'C:\Program Files (x86)\Tanium\Tanium Client\Tools\ADQuery\Inventory.xml'
[xml]$Inventory = Get-Content -Path $InventoryFile
$PrimaryUser = $Inventory.SelectNodes("//Tanium/users/user") | Where-Object { $_.primaryUser -eq 'yes' }
[string]$Location = $PrimaryUser.properties.physicalDeliveryOfficeName

Write-Output "$Location"