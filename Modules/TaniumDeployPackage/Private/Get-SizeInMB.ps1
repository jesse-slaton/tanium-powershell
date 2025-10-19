function Get-SizeInMB {
    <#
    .SYNOPSIS
        Converts a size string to megabytes.

    .PARAMETER SizeString
        Size string (e.g., "3933.9 MB", "4.5 GB", "500 KB")

    .OUTPUTS
        Int - Size in megabytes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SizeString
    )

    if ($SizeString -match '([\d.]+)\s*([KMG]?B)') {
        $value = [double]$Matches[1]
        $unit = $Matches[2]

        $sizeMB = switch ($unit) {
            'KB' { [math]::Max([int]($value / 1024), 1) }
            'MB' { [math]::Max([int]$value, 1) }
            'GB' { [math]::Max([int]($value * 1024), 1) }
            default { 100 }
        }

        return $sizeMB
    }
    else {
        return 100  # Default
    }
}
