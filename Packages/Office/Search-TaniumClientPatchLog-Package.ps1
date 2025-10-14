function Search-TaniumClientPatchLog {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [string]$Filter,
        [switch]$AllLogs
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    if ($AllLogs.IsPresent) {
        $PatchLog = "$TaniumClientPatchDirectory\patch*.log"
    }
    else {
        $PatchLog = "$TaniumClientPatchDirectory\patch0.log"
    }
    Select-String -Path $PatchLog -Pattern $Filter
}