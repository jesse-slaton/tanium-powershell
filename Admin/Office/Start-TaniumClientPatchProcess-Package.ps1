function Start-TaniumClientPatchProcess {
    [CmdletBinding()]
    param()
    $TaniumClientPatchProcess = Get-TaniumClientPatchProcess
    if ($TaniumClientPatchProcess) {
        Write-Warning "The Tanium client Patch process is already running."
    }
    else {
        $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
        Write-Verbose "Starting Tanium client Patch process"
        $Bitness = Get-Bitness
        if ($Bitness -eq 'x86') {
            Start-Process -FilePath "$ENV:WINDIR\system32\cscript.exe" -ArgumentList '//nologo',"`"$TaniumClientPatchDirectory\tanium-patch.min.vbs`"" -WindowStyle Hidden
        }
        elseif ($Bitness -eq 'x64') {
            Start-Process -FilePath "$ENV:WINDIR\syswow64\cscript.exe" -ArgumentList '//nologo',"`"$TaniumClientPatchDirectory\tanium-patch.min.vbs`"" -WindowStyle Hidden
        }
        else {
            Write-Warning "Unable to determine bitness: $Bitness"
        }
    }
}