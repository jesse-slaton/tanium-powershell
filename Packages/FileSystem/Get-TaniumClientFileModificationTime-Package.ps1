function Get-TaniumClientFileModificationTime {
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Path
    )
    if (Test-Path $Path) {
        $FileModificationTime = (Get-Item -Path $Path).LastWriteTime
        $FileModificationTime
    }
    else {
        Write-Verbose "$Path not found."
    }
}