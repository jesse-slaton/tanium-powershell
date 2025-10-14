function Enable-TaniumClientActionLock {
    [cmdletbinding()]
    param ()
    Set-TaniumClientSetting -Setting 'ActionLockFlag' -Value 1
}