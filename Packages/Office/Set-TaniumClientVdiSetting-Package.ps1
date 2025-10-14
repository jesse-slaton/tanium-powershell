function Set-TaniumClientVdiSetting {
    [cmdletbinding()]
    param ()
    begin {}
    process {
        $Setting = @{
            'RandomSensorDelayInSeconds'        = 30
            'MaxAgeMultiplier'                  = 2
            'MinDistributeOverTimeInSeconds'    = 60
            'LogVerbosityLevel'                 = 0
            'SaveClientStateIntervalInSeconds'  = 1800
            'Logs.extensions.LogVerbosityLevel' = 0
        }

        foreach ($S in $Setting.GetEnumerator()) {
            Set-TaniumClientSetting -Setting $S.Key -Value $S.Value
        }
    }
    end {}
}