function Get-TaniumClientPatchTswManifest {
    [CmdletBinding()]
    param()
    Get-TaniumClientPatchData -DataType tsw-manifest
}