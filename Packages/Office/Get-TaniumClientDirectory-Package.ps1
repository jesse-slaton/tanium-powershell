
function Get-TaniumClientDirectory {
    [CmdletBinding()]
    param()

    function Get-TaniumClientDirectoryWindows {
        $TaniumClientPathSetting = (Get-TaniumClientSetting -Setting Path).Value
        if ($TaniumClientPathSetting) {
            $TaniumClientDirectory = $TaniumClientPathSetting
        }
        else {
            if (Test-Command -Name 'Get-CimInstance') {
                $TaniumService = Get-CimInstance -Class win32_service -Filter "Name = 'Tanium Client'"
            }
            elseif (Test-Command -Name 'Get-WmiObject') {
                $TaniumService = Get-WmiObject -Class win32_service -Filter "Name = 'Tanium Client'"
            }
            else {
                Write-Warning 'Unable to find a valid cmdlet to find the Tanium Client directory'
            }
            if ($TaniumService) {
                $TaniumClientDirectory = Split-Path -Path (Get-Item $TaniumService.PathName.Replace('"', '').TrimEnd('--service')) -Parent
            }
        }
        Write-Output $TaniumClientDirectory
    }


    if (Test-Path -Path env:TANIUM_CLIENT_ROOT -ErrorAction SilentlyContinue) {
        $TaniumClientDirectory = $env:TANIUM_CLIENT_ROOT
    }
    elseif (Get-Variable -Name TaniumClientDirectory -Scope global -ErrorAction SilentlyContinue) {
        Write-Verbose "TaniumClientDirectory global variable already set to $TaniumClientDirectory"
        $TaniumClientDirectoryGlobal = $true
    }
    else {
        $PowerShellType = Get-PowerShellType
        switch ($PowerShellType) {
            'DesktopWindows' {
                $TaniumClientDirectory = Get-TaniumClientDirectoryWindows
            }
            'CoreWindows' {
                $TaniumClientDirectory = Get-TaniumClientDirectoryWindows
            }
            'CoreLinux' {
                $TaniumClientDirectory = '/opt/Tanium/TaniumClient'
            }
            'CoreMacOS' {
                $TaniumClientDirectory = '/Library/Tanium/TaniumClient'
            }
        }
    }
    
    if ($TaniumClientDirectory) {
        if (Test-Path $TaniumClientDirectory) {
            Write-Verbose "Found Tanium Client at: $TaniumClientDirectory"
            if (!$TaniumClientDirectoryGlobal) {
                Set-Variable -Name TaniumClientDirectory -Value $TaniumClientDirectory -Scope global
            }
            $TaniumClientDirectory
        }
    }
    else {
        Write-Warning "Unable to find Tanium Client directory"
    }
}