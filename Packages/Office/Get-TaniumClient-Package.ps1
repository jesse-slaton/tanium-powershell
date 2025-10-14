function Get-TaniumClient {
    [cmdletbinding()]
    param()
    try {
        if (Get-Variable -Name TaniumClient -Scope global -ErrorAction Stop) {
            Write-Verbose "TaniumClient global variable already set to $TaniumClient"
            $TaniumClient
        }
    }
    catch {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        $PowerShellType = Get-PowerShellType
        switch ($PowerShellType) {
            'DesktopWindows' {
                $TaniumClient = "$TaniumClientDirectory\TaniumClient.exe"
            }
            'CoreWindows' {
                $TaniumClient = "$TaniumClientDirectory\TaniumClient.exe"
            }
            'CoreLinux' {
                $TaniumClient = "$TaniumClientDirectory/TaniumClient"
            }
            'CoreMacOS' {
                $TaniumClient = "$TaniumClientDirectory/TaniumClient"
            }
        }
        if (Test-Path -Path $TaniumClient) {
            Write-Verbose "Tanium Client binary exists"
            Set-Variable -Name TaniumClient -Value $TaniumClient -Scope global
            $TaniumClient
        }
        else {
            Write-Warning "Tanium Client binary does not exist"
        }
    }  
}