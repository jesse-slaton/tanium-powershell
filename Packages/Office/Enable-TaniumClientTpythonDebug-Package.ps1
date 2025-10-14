function Enable-TaniumClientTpythonDebug {
    [cmdletbinding()]
    param ()
    Write-Verbose 'Enabling Tpython Debug mode'
    Set-TaniumClientSetting -Setting 'DEBUG_DisablePythonAncestry' -Value 1
}