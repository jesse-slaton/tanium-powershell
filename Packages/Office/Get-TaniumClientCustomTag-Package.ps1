function Get-TaniumClientCustomTag {
    [cmdletbinding()]
    param ()
    $TaniumClientRegistryPath = Get-TaniumClientRegistryPath
    if ($TaniumClientRegistryPath) {
        $TaniumClientCustomTagRegistryPath = "$TaniumClientRegistryPath\Sensor Data\Tags"
        if (Test-Path $TaniumClientCustomTagRegistryPath) {
            $TaniumClientCustomTag = Get-Item -Path "$TaniumClientRegistryPath\Sensor Data\Tags" | Select-Object -ExpandProperty Property
            $TaniumClientCustomTag
        }
        else {
            Write-Verbose 'No Custom Tags found.'
        }
    }
}