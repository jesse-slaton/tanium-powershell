#Requires -Version 5.1

<#
.SYNOPSIS
    Lists Office COM add-ins from the registry, one pipe-delimited line each.

.DESCRIPTION
    Reads the Platform value (x64 or x86) of the Click-to-Run configuration key
    HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration to choose the machine-wide
    Office key (HKLM:\SOFTWARE\Microsoft\Office for x64,
    HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office for x86). It then recursively searches
    HKCU:\SOFTWARE\Microsoft\Office and that machine-wide key for keys whose path
    contains 'Addins' and that have at least one value, and writes one line per add-in:

        <Name>|<Product>|<FriendlyName>|<LoadBehavior>|<Load Behavior Description>

    Name is the add-in key name, Product is the registry path segment three levels up
    (for example Outlook), and Load Behavior Description translates the LoadBehavior
    number to text. Entries without a LoadBehavior value are left out. Results are
    sorted and de-duplicated by Product and Name within each hive. Quotes are removed
    and the CSV header line is dropped. Read-only.

    If Platform is missing or has another value, the native machine-wide key is chosen
    as a fallback. If no add-in key could be read, or if emitting the results fails,
    the script writes one "Error: <message>" line.

.EXAMPLE
    .\Get-OfficeCOMAddins-Sensor.ps1

    <AddinName>|Outlook|<FriendlyName>|3|Loaded. Load at startup.

.NOTES
    Written as a Tanium sensor for Click-to-Run Office installations. The ClickToRun
    key check at the top does not stop the script when the key is missing (Test-Path
    returns False instead of throwing). HKCU is the hive of the account that runs the
    script; under the Tanium Client (Local System) that is not the logged-on user's
    hive. No admin rights needed to read these keys.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/ActiveDirectory/Get-OfficeCOMAddins-Sensor.ps1.
#>
$CTRPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
[hashtable]$LoadBehaviorHash = @{
    0  = "Unloaded. Do not load automatically."
    1  = "Loaded. Do not load automatically."
    2  = "Unloaded. Load at startup."
    3  = "Loaded. Load at startup."
    8  = "Unloaded. Load on demand."
    9  = "Loaded. Load on demand."
    16 = "Loaded. Load first time, then load on demand."
}

Try {
    Test-Path -Path $CTRPath -ErrorAction Stop | Out-Null
}
Catch {
    Write-Error $_.Exception.Message -ErrorAction Stop
    [Environment]::Exit($_.Exception.HResult)
}

# The Click-to-Run key may be absent; a missing key falls back to the native machine hive.
Switch ((Get-ItemProperty $CTRPath -ErrorAction SilentlyContinue).Platform) {
    'x64' { $HKLMPath = "HKLM:\SOFTWARE\Microsoft\Office" }
    'x86' { $HKLMPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Office" }
    Default { $HKLMPath = "HKLM:\SOFTWARE\Microsoft\Office" }
}
$searchScopes = "HKCU:\SOFTWARE\Microsoft\Office", $HKLMPath

$addinKeys = @()
$readErrors = @()
foreach ($scope in $searchScopes) {
    if (-not (Test-Path -LiteralPath $scope)) {
        # The hive is absent on this machine; there are no add-ins to report for it.
        continue
    }
    # A single denied subkey is skipped, not fatal: -ErrorAction SilentlyContinue keeps
    # the recursion going so one unreadable key does not silently drop later add-ins.
    $addinKeys += @(Get-ChildItem -LiteralPath $scope -Recurse -ErrorAction SilentlyContinue -ErrorVariable +readErrors)
}

$Addins = $addinKeys |
    Where-Object { ($_.PSPath -like '*\Addins\*') -and ($_.ValueCount -gt 0) } |
    ForEach-Object { Get-ItemProperty -Path $_.PSPath } |
    Select-Object @{n = "Name"; e = { Split-Path $_.PSPath -leaf } },
        @{n = "Product"; e = { (($_.PSPath -split '\\')[0, -3])[1] } },
        FriendlyName,
        Loadbehavior,
        @{n = "Load Behavior Description"; e = { $LoadBehaviorHash.$($_.Loadbehavior) } } |
    Where-Object { $null -ne $_.Loadbehavior } |
    Sort-Object -Property Product, Name -Unique

if ($readErrors.Count -gt 0 -and $addinKeys.Count -eq 0) {
    # Nothing at all could be read (every present hive was denied); report it rather
    # than silently emitting an empty inventory.
    Write-Output "Error: $($readErrors[0].Exception.Message)"
}

try {
    $Addins |
        ConvertTo-Csv -Delimiter '|' -NoTypeInformation |
        Select-Object -Skip 1 |
        ForEach-Object { $_.Replace('"', '') }
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
}
