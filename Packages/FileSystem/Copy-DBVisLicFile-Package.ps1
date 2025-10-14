$DBVisLicense = @"
# DbVisualizer license key
dbvis.license.product        = DbVisualizer
dbvis.license.edition        = Personal
dbvis.license.id             = 253489488 / Enterprise License
dbvis.license.name           = CONTOSO INSURANCE SERVICES, LLC
dbvis.license.org            = CONTOSO INSURANCE SERVICES, LLC
dbvis.license.activation     = 2020-12-21
dbvis.license.expire         = 2099-01-01
dbvis.license.upgrade.expire = 2021-12-23
dbvis.license.seal           = MCwCFC3q/whVSlWx8fLfTwpDw8SRoiAJAhQ7q9Pb5CVJt2UXSEpQicT7s/9grA==
# The following is needed only for backward compatibility
dbvis.license.version        = 5.*
"@

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

$CachePath = $ProfilePath + "\.dbvis"

If (!(Test-Path -Path $CachePath)) {
    New-Item -ItemType Directory -Path $CachePath
}

Try {
    Write-Host ("Replacing dbvis.license in the .dbvis folder:  " + $CachePath)
    $DBVisLicense | Out-File -FilePath "$CachePath\dbvis.license" -Encoding utf8 -Force
}
Catch {
    Write-Error ("Couldn't replace dbvis.license in .dbvis folder:  " + $CachePath)
}