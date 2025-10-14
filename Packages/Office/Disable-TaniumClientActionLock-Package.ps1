function Disable-TaniumClientActionLock {
    [cmdletbinding()]
    param ()
    Set-TaniumClientSetting -Setting 'ActionLockFlag' -Value 0
}