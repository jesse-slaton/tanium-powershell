function Stop-TaniumClientPatchProcess {
    [CmdletBinding()]
    param()
    $TaniumClientPatchProcess = Get-TaniumClientPatchProcess
    if ($TaniumClientPatchProcess) {
        Write-Verbose "Found Tanium Client Patch process. Stopping now."
        Stop-Process $TaniumClientPatchProcess.ProcessId -Force
    }
}