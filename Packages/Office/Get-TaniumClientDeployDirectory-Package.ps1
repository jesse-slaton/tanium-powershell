
function Get-TaniumClientDeployDirectory {
    [CmdletBinding()]
    param()
    try {
        if (Get-Variable -Name TaniumClientDeployDirectory -Scope global -ErrorAction Stop) {
            Write-Verbose "TaniumClientDeployDirectory global variable already set to $TaniumClientDeployDirectory"
            $TaniumClientDeployDirectory
        }
    }
    catch {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $PowerShellType = Get-PowerShellType
        switch ($PowerShellType) {
            'DesktopWindows' {
                $TaniumClientDeployDirectory = "$TaniumClientDirectory\Tools\SoftwareManagement"
            }
            'CoreWindows' {
                $TaniumClientDeployDirectory = "$TaniumClientDirectory\Tools\SoftwareManagement"
            }
            'CoreLinux' {
                $TaniumClientDeployDirectory = "$TaniumClientDirectory/Tools/SoftwareManagement"
            }
            'CoreMacOS' {
                $TaniumClientDeployDirectory = "$TaniumClientDirectory/Tools/SoftwareManagement"
            }
        }
        if (Test-Path -Path $TaniumClientDeployDirectory) {
            Write-Verbose "Tanium Client Deploy folder exists"
            Set-Variable -Name TaniumClientDeployDirectory -Value $TaniumClientDeployDirectory -Scope global
            $TaniumClientDeployDirectory
        }
        else {
            Write-Warning "Tanium Client Deploy folder does not exist"
        }
    }
}