function Invoke-TaniumClientPatchPostUpgradePatchDeployment {
    [cmdletbinding()]
    param (
        [int]$ScanConfigurationId = 999,
        [string]$ScanMethod = 'tanium',
        [int]$DeploymentConfigurationId = 999,
        [parameter(mandatory=$true)]
        [string]$DeploymentPatchListId,
        [int]$DeploymentLengthInHours = 3
    )

    # Remove Action Lock
    Write-Verbose 'Checking Tanium client action lock status'
    if (Get-TaniumClientActionLock) {
        Write-Verbose 'Tanium client is action locked. Removing action lock.'
        Disable-TaniumClientActionLock
    }
    else {
        Write-Verbose 'Tanium client is not action locked. Skipping removal of action lock.'
    }

    # Start Patch Process
    Write-Verbose 'Checking Tanium Client Patch process is running.'
    $TaniumClientPatchProcess = Get-TaniumClientPatchProcess
    if (!$TaniumClientPatchProcess) {
        Write-Verbose 'Tanium Client patch process is not running. Starting now.'
        Start-TaniumClientPatchProcess
    }
    else {
        Write-Verbose 'Tanium Client Patch process is already running.'
    }
    # Force Scan
    Write-Verbose "Forcing a Tanium client patch scan now using the $ScanMethod method."
    Start-TaniumClientPatchScan -ScanConfigurationId $ScanConfigurationId -ScanMethod $ScanMethod -Force
    # Create Deployment
    Write-Verbose "Creating a new Patch deployment now"
    New-TaniumClientPatchDeployment -DeploymentConfigurationId $DeploymentConfigurationId -DeploymentPatchListId $DeploymentPatchListId -DeploymentLengthInHours $DeploymentLengthInHours -Force
}