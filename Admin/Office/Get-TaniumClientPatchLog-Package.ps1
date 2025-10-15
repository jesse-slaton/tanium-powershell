function Get-TaniumClientPatchLog {
    [CmdletBinding()]
    param(
        [int]$Last,
        [Alias('Tail')]
        [switch]$Wait,
        [string]$Filter
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $PatchLog = "`"$TaniumClientPatchDirectory\patch0.log`""
    $Command = "Get-Content -Path $PatchLog"
    if ($Last) {
        $Command = $Command + " -Last $Last"
    }
    if ($Wait.IsPresent) {
        $Command = $Command + " -Wait"
    }
    if ($Filter) {
        $Command = $Command + " | Select-String -Pattern `"$Filter`""
    }
    Write-Verbose "Executing $Command"
    Invoke-Expression $Command
}