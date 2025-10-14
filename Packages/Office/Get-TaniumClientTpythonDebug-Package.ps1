function Get-TaniumClientTpythonDebug {
    [cmdletbinding()]
    param()
    $TaniumClientTpythonDebug = Get-TaniumClientSetting -Setting 'DEBUG_DisablePythonAncestry'
    $TaniumClientTpythonDebug
}