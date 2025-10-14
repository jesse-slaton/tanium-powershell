function New-TaniumClientCustomTag {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string[]]$Tag
    )
    $TaniumClientRegistryPath = Get-TaniumClientRegistryPath
    if ($TaniumClientRegistryPath) {
        $TaniumClientCustomTagRegistryPath = "$TaniumClientRegistryPath\Sensor Data\Tags"
        if (Test-Path $TaniumClientCustomTagRegistryPath) {
            foreach ($strTag in $Tag) {
                Write-Verbose "Add custom tag $strTag"
                New-ItemProperty -Path "$TaniumClientCustomTagRegistryPath" -Name $strTag -Value $null -PropertyType String -Force | Out-Null
            }
        }
        else {
            Write-Verbose 'Unable to find Tanium Client custom tag registry path.'
        }
    }
}