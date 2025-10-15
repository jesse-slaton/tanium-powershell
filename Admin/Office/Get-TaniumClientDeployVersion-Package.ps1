function Get-TaniumClientDeployVersion {
    [cmdletbinding()]
    param ()
    $TaniumClientDirectory = Get-TaniumClientDirectory
    if ($TaniumClientDirectory) {
        $TaniumClientDeployVersionFile = "$TaniumClientDirectory\Tools\Deploy\version"
        if (Test-Path $TaniumClientDeployVersionFile) {
        $TaniumClientDeployVersion = Get-Content -Path $TaniumClientDeployVersionFile
        $TaniumClientDeployVersion
        }
        else {
            Write-Warning 'Unable to find Tanium Client version.'
        }
    }
    else {
        Write-Warning 'Unable to find Tanium Client Deploy directory'
    }
}