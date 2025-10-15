function Stop-TaniumClientPatchManagerProcess {
    [CmdletBinding()]
    param()
    $TaniumClientPatchManagerProcess = Get-TaniumClientPatchManagerProcess
    if ($TaniumClientPatchManagerProcess) {
        Write-Verbose "Found Tanium Client Patch Manager process. Stopping now."
        Stop-Process $TaniumClientPatchManagerProcess.ProcessId -Force
    }
}