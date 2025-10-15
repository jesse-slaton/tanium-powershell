
function Set-TaniumClientPatchDirectory {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Path
    )
    if (Test-Path -Path $Path) {
        Write-Verbose "Tanium Client Patch folder exists"
        $global:TaniumClientPatchDirectory = $Path
        $TaniumClientPatchDirectory
    }
    else {
        Write-Warning "Tanium Client Patch folder does not exist at $Path"
    }
}