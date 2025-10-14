function Get-TaniumClientRegistryPath {
    [CmdletBinding()]
    param()
    $Bitness = Get-Bitness

    if ($Bitness -eq 'x64') {
        $TaniumClientRegistryPath = 'HKLM:\Software\WOW6432Node\Tanium\Tanium Client'
    }
    elseif ($Bitness -eq 'x86') {
        $TaniumClientRegistryPath = 'HKLM:\Software\Tanium\Tanium Client'
    }
    else {
        Write-Warning 'Unable to determine the Tanium client registry path'
        $TaniumClientRegistryPath = $null
    }
    if (Test-Path -Path $TaniumClientRegistryPath) {
        $TaniumClientRegistryPath
    }
    else {
        Write-Warning 'Unable to determine the Tanium client registry path'
        $TaniumClientRegistryPath = $null
    }
}