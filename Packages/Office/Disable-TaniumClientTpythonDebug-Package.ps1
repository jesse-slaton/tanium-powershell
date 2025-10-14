function Disable-TaniumClientTpythonDebug {
    [cmdletbinding()]
    param ()
    Write-Verbose 'Disabling Tpython Debug mode'
    Set-TaniumClientSetting -Setting 'DEBUG_DisablePythonAncestry' -Value 0
}