function Get-ArchitectureFromString {
    <#
    .SYNOPSIS
        Parses architecture from a string.

    .PARAMETER String
        The string to parse (e.g., update title).

    .OUTPUTS
        String - Architecture (x64, x86, ARM64, or unknown)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$String
    )

    if ($String -match 'x64-based|x64') {
        return 'x64'
    }
    elseif ($String -match 'x86-based|x86') {
        return 'x86'
    }
    elseif ($String -match 'ARM64') {
        return 'ARM64'
    }
    else {
        return 'x64'  # Default
    }
}
