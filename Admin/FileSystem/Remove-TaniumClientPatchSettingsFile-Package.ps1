function Remove-TaniumClientPatchSettingsFile {
    [CmdletBinding()]
    param( )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchSettingsFile = "$TaniumClientPatchDirectory\settings-file"
    if (Test-Path $TaniumClientPatchSettingsFile) {
        Write-Verbose "Found settings-file, removing."
        Remove-Item -Path $TaniumClientPatchSettingsFile | Out-Null
    }
    else {
        Write-Verbose "settings-file not found. Skipping removal."
    }
}