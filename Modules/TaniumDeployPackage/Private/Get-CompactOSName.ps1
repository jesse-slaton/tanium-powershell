function Get-CompactOSName {
    <#
    .SYNOPSIS
        Gets a compact OS name for self-service display.

    .PARAMETER String
        The string to parse (e.g., update title or OS name).

    .OUTPUTS
        String - Compact OS name (Win10, Win11, WinSvr2022, etc.)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String
    )

    if ($String -match 'Windows 10') {
        return 'Win10'
    }
    elseif ($String -match 'Windows 11') {
        return 'Win11'
    }
    elseif ($String -match 'Windows Server 2022') {
        return 'WinSvr2022'
    }
    elseif ($String -match 'Windows Server 2019') {
        return 'WinSvr2019'
    }
    elseif ($String -match 'Windows Server 2016') {
        return 'WinSvr2016'
    }
    else {
        return 'Windows'
    }
}
