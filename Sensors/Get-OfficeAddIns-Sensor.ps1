#Requires -Version 5.1

<#
.SYNOPSIS
    Lists Office add-ins registered in the registry, one pipe-delimited line each.

.DESCRIPTION
    Searches the Addins keys under HKCU:\SOFTWARE\Microsoft\Office\*,
    HKLM:\SOFTWARE\Microsoft\Office\* and HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office\*
    and reads the values of every key below them. For each add-in it builds:

        <Hive>|<Product>|<Architecture>|<Name>|<FriendlyName>|<LoadBehavior>

    Hive is User or Machine, Product is the registry path segment immediately before
    'Addins' (the Office application, for example Excel), Architecture is 32-bit for
    Wow6432Node keys, 64-bit for the native machine keys, and Unknown for the shared
    HKCU keys, Name is the add-in key name, and LoadBehavior is the LoadBehavior value
    translated to text (for example "Load at startup (Loaded)", and 16 is "Load first
    time, then load on demand (Loaded)"). Add-ins are
    de-duplicated by Name across all three locations, add-ins whose LoadBehavior is
    missing or not in the translation table are left out, quotes are removed, and the
    header line is dropped. The lines are written sorted. If nothing is found the
    script writes nothing. If emitting the results fails, the script writes one
    "Error: <message>" line. Read-only.

.EXAMPLE
    .\Get-OfficeAddIns-Sensor.ps1

    Machine|Outlook|64-bit|<AddinName>|<FriendlyName>|Load at startup (Loaded)

.NOTES
    Written as a Tanium sensor. The ClickToRun Configuration key check at the top does
    not stop the script when the key is missing (Test-Path returns False instead of
    throwing). HKCU is the hive of the account that runs the script; under the Tanium
    Client (Local System) that is not the logged-on user's hive. No admin rights needed
    to read these keys.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/ActiveDirectory/Get-OfficeAddIns-Sensor.ps1.
#>
$ClicktoRunPath = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
$HKCUBasePath = "HKCU:\SOFTWARE\Microsoft\Office"
$HKLMBasePath = "HKLM:\SOFTWARE\Microsoft\Office"
$HKLM32BasePath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office"

$LoadBehaviorHashTable = @{
    0  = "Do not load (Unloaded)";
    1  = "Do not load (Loaded)";
    2  = "Load at startup (Unloaded)";
    3  = "Load at startup (Loaded)";
    8  = "Load on demand (Unloaded)";
    9  = "Load on demand (Loaded)";
    16 = "Load first time, then load on demand (Loaded)";
}

Try {
    Test-Path -Path $ClicktoRunPath -ErrorAction Stop | Out-Null
}
Catch {
    Write-Error $_.Exception.Message -ErrorAction Stop
    [Environment]::Exit($_.Exception.HResult)
}

$ArrayofOfficeAddins = @($HKCUBasePath, $HKLMBasePath, $HKLM32BasePath) | ForEach-Object {
    $basePath = $_
    try {
        $products = Get-ChildItem -LiteralPath $basePath -ErrorAction Stop
    }
    catch {
        # A hive that is not present on this machine is normal, not an error.
        $products = $null
    }
    foreach ($product in $products) {
        $addinsPath = Join-Path -Path $product.PSPath -ChildPath 'Addins'
        # A product key without an Addins key is normal; read only the ones that exist.
        Get-ChildItem -LiteralPath $addinsPath -Recurse -ErrorAction SilentlyContinue
    }
} | ForEach-Object {
    Get-ItemProperty -Path $_.PSPath
} | Select-Object @{n = 'Hive'; e = { if ($_.PSParentPath -match '_USER') { 'User' } else { 'Machine' } } },
    @{n = 'Product'; e = { $Segments = (Convert-Path $_.PSParentPath) -split '\\'; $Segments[[array]::IndexOf($Segments, 'Addins') - 1] } },
    @{n = 'Architecture'; e = { if ($_.PSPath -match 'Wow6432Node') { '32-bit' } elseif ($_.PSPath -match '_USER') { 'Unknown' } else { '64-bit' } } },
    @{n = 'Name'; e = { Split-Path $_.PSPath -Leaf } },
    FriendlyName,
    @{n = 'LoadBehavior'; e = { $LoadBehaviorHashTable.($_.LoadBehavior) } } |
    Sort-Object -Unique -Property name

try {
    $ArrayofOfficeAddins |
        Where-Object { $null -ne $_.LoadBehavior } |
        ConvertTo-Csv -Delimiter '|' -NoTypeInformation |
        Select-Object -Skip 1 |
        ForEach-Object { $_.Replace('"', '') } |
        Sort-Object
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
}
