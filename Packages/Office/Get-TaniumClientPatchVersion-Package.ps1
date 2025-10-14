function Get-TaniumClientPatchVersion {
    $TaniumClientPatchVersion = Get-TaniumClientPatchManifest | Select-Object -ExpandProperty Version
    $TaniumClientPatchVersion
}