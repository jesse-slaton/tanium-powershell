function Remove-TaniumClientVdiSetting {
    [cmdletbinding()]
    param ()    
    begin {}
    process {
        Remove-TaniumClientSetting -Setting 'RandomSensorDelayInSeconds'
        Remove-TaniumClientSetting -Setting 'MaxAgeMultiplier'
        Remove-TaniumClientSetting -Setting 'MinDistributeOverTimeInSeconds'
        Remove-TaniumClientSetting -Setting 'SaveClientStateIntervalInSeconds'
        Remove-TaniumClientSetting -Setting 'Logs.extensions.LogVerbosityLevel'
        Set-TaniumClientSetting -Setting 'LogVerbosityLevel' -Value 1
    }
    end {}
}