function Test-TaniumClientDirectoryAccess {
    [cmdletbinding()]
    param()
    $TaniumClientDirectoryAccess = $false
    $TaniumClientDirectory = Get-TaniumClientDirectory
    if (Test-Path $TaniumClientDirectory) {
        try {
            $TaniumClientDirectoryContents = Get-ChildItem -Path $TaniumClientDirectory -ErrorAction Stop
            if ($TaniumClientDirectoryContents) {
                $TaniumClientDirectoryAccess = $true
            }
        }
        catch {
            Write-Warning "Unable to read contents of $TaniumClientDirectory"
        }
    }
    $TaniumClientDirectoryAccess
}
