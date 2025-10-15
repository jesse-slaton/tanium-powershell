function Get-TaniumClientPatchCabAge {
    [CmdletBinding()]
    param()
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    Get-TaniumClientFileModificationTime -Path "$TaniumClientPatchDirectory\scans\wsusscn2.cab"
}