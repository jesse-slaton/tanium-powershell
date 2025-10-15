function Get-TaniumClientPatchActiveScanConfiguration {
    [CmdletBinding()]
    param()
    $TaniumClientPatchScanPriorities = Get-TaniumClientPatchData -DataType scan-configuration-priorities
    $TaniumClientPatchScanConfiguration = Get-TaniumClientPatchScanConfiguration
    foreach ($ScanPriority in $TaniumClientPatchScanPriorities) {
        foreach ($ScanConfiguration in $TaniumClientPatchScanConfiguration) {
            Write-Verbose "Checking Scan Priority Config $ScanPriority and ScanConfiguration ID $($ScanConfiguration.id)"
            if ($ScanPriority -eq $ScanConfiguration.id) {
                Write-Verbose "Found active scan configuration"
                $ActiveScanConfiguration = $ScanPriority
            }
        }
        if ($ActiveScanConfiguration) {
            $ActiveScanConfiguration
            break
        }
    }
}