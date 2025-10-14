function Get-TaniumClientVersion {
    [cmdletbinding()]
    param ()
    $TaniumClientVersion = Get-TaniumClientSetting -Setting Version
    $TaniumClientVersion | Select-Object -ExpandProperty Value
}