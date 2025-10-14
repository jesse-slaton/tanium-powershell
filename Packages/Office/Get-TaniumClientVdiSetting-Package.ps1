function Get-TaniumClientVdiSetting {
    [cmdletbinding()]
    param (
        [ValidateSet('RandomSensorDelayInSeconds', 'MaxAgeMultiplier', 'MinDistributeOverTimeInSeconds', 'LogVerbosityLevel', 'SaveClientStateIntervalInSeconds', 'Logs.extensions.LogVerbosityLevel')]
        $Setting = @('RandomSensorDelayInSeconds', 'MaxAgeMultiplier', 'MinDistributeOverTimeInSeconds', 'LogVerbosityLevel', 'SaveClientStateIntervalInSeconds', 'Logs.extensions.LogVerbosityLevel')
    )
    begin {}
    process {
        foreach ($S in $Setting) {
            Get-TaniumClientSetting -Setting $S
        }
    }
    end {}
}