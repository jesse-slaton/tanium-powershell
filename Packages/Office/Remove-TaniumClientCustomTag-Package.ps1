function Remove-TaniumClientCustomTag {
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
                Write-Verbose "Removing custom tag $strTag"
                Remove-ItemProperty -Path "$TaniumClientCustomTagRegistryPath" -Name $strTag
            }
        }
        else {
            Write-Verbose 'Unable to find Tanium Client custom tag registry path.'
        }
    }
}