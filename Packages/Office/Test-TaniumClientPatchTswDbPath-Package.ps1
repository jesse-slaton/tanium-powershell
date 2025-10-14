function Test-TaniumClientPatchTswDbPath {
    [cmdletbinding()]
    param (
        [string]$Name
    )
    Get-TaniumClientPatchTswDb -Name $Name | Select-Object -Property Path | Test-Path
}