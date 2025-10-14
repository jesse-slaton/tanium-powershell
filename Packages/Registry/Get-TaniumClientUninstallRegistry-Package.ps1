function Get-TaniumClientUninstallRegistry {
    [cmdletbinding()]
    param()
    $Bitness = Get-Bitness
    if ($Bitness -eq 'x64') {
        $TaniumClientUninstallRegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Tanium Client'
    }
    elseif ($Bitness -eq 'x86') {
        $TaniumClientUninstallRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Tanium Client'
    }
    else {
        Write-Warning 'Unable to determine bitness'
    }
    if (Test-Path $TaniumClientUninstallRegistryPath) {
        Write-Verbose "Found Tanium Client Uninstall Registry path at $TaniumClientUninstallRegistryPath"
    }
    $TaniumClientUninstallRegistryPath
}