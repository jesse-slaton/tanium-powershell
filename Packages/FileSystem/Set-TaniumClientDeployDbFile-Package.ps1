
function Set-TaniumClientDeployDbFile {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Path
    )
    if (Test-Path -Path $Path) {
        Write-Verbose "Tanium Client Deploy database file exists"
        $global:TaniumClientDeployDbFile = $Path
        $TaniumClientDeployDbFile
    }
    else {
        Write-Warning "Tanium Client Deploy database file does not exist at $Path"
    }
}