function Get-TaniumClientPatchManifest {
    [CmdletBinding()]
    param()
    Get-TaniumClientPatchData -DataType required-files-manifest
}