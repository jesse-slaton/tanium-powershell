
function Get-TaniumClientDeployDbFile {
    [CmdletBinding()]
    param()
    try {
        if (Get-Variable -Name TaniumClientDeployDbFile -Scope global -ErrorAction Stop) {
            Write-Verbose "TaniumClientDeployDbFile global variable already set to $TaniumClientDeployDbFile"
            $TaniumClientDeployDbFile
        }
    }
    catch {
        $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
        if (Test-Path "$TaniumClientDeployDirectory\data\software-management.db") {
            Write-Verbose "Found Tanium Client Deploy Datbase file."
            $global:TaniumClientDeployDbFile = "$TaniumClientDeployDirectory\data\software-management.db"
            $TaniumClientDeployDbFile
        }
        else {
            Write-Warning "Tanium Client Deploy database file does not exist"
        }
    }
}