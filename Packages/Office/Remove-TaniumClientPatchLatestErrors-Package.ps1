function Remove-TaniumClientPatchLatestErrors {
    [CmdletBinding()]
    param( )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchLatestErrors = "$TaniumClientPatchDirectory\latest-errors"
    if (Test-Path $TaniumClientPatchLatestErrors) {
        Write-Verbose "Found latest-errors file, removing."
        Remove-Item -Path $TaniumClientPatchLatestErrors | Out-Null
    }
    else {
        Write-Verbose "latest-errors file not found. Skipping removal."
    }
}