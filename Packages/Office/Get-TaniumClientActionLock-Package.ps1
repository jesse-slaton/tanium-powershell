function Get-TaniumClientActionLock {
    [cmdletbinding()]
    param ()

    $ActionLock = Get-TaniumClientSetting -Setting ActionLockFlag
    if ($ActionLock.Value -eq 1) {
        Write-Output $true
    }
    else {
        Write-Output $false
    }
}