
function Get-TaniumClientPatchDirectory {
    [CmdletBinding()]
    param()
    try {
        if (Get-Variable -Name TaniumClientPatchDirectory -Scope global -ErrorAction Stop) {
            Write-Verbose "TaniumClientPatchDirectory global variable already set to $TaniumClientPatchDirectory"
            $TaniumClientPatchDirectory
        }
    }
    catch {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $PowerShellType = Get-PowerShellType
        switch ($PowerShellType) {
            'DesktopWindows' {
                $TaniumClientPatchDirectory = "$TaniumClientDirectory\Patch"
            }
            'CoreWindows' {
                $TaniumClientPatchDirectory = "$TaniumClientDirectory\Patch"
            }
            'CoreLinux' {
                $TaniumClientPatchDirectory = "$TaniumClientDirectory/Tools/Patch"
            }
            'CoreMacOS' {
                $TaniumClientPatchDirectory = "$TaniumClientDirectory/Tools/Patch"
            }
        }
        if (Test-Path -Path $TaniumClientPatchDirectory) {
            Write-Verbose "Tanium Client Patch folder exists"
            Set-Variable -Name TaniumClientPatchDirectory -Value $TaniumClientPatchDirectory -Scope global
            $TaniumClientPatchDirectory
        }
        else {
            Write-Warning "Tanium Client Patch folder does not exist"
        }
    }
}