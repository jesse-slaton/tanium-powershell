
function Set-TaniumClientDeployDirectory {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Path
    )
    if (Test-Path -Path $Path) {
        Write-Verbose "Tanium Client Deploy folder exists"
        $global:TaniumClientDeployDirectory = $Path
        $TaniumClientDeployDirectory
    }
    else {
        Write-Warning "Tanium Client Deploy folder does not exist at $Path"
    }
}