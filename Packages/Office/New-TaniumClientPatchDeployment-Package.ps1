
<#
.SYNOPSIS
Create a new Tanium Patch deployment.
.DESCRIPTION
This script will generate a Tanium Patch deployment configuration for an immediate deployment
on an endpoint.
.PARAMETER DeploymentConfigurationId
Enter a deployment ID.
It is recommended to have an ongoing deployment ID that matches this ID so that you can view the deployment
status and results from the Tanium Patch console.
.PARAMETER DeploymentPatchListId
Enter a patch list ID for the deployment (i.e. Production Baseline). Retreive patch list ID from Tanium Patch console.
.PARAMETER DeploymentLengthInHours
Specify the length of the deployment in hours. The deployment should include time to downloads required patch files (i.e. 1-3 hours)
.PARAMETER Force
Use the Force option if you want to stop an already running Tanium patch manager process. The patch manager
process may already be running a scan or a deployment.
.PARAMETER AllowClobber
Use the AllowClobber switch to overwrite any existing patch deployment configuration files.
.NOTES
Created by: Jason Wasser @wasserja
Modified: 2021-05-21
* Added unmanaged tag in deployment configuration to support Patch 3.4 and ECF
#>
function New-TaniumClientPatchDeployment {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]$DeploymentConfigurationId,
        [parameter(Mandatory = $true)]
        [string[]]$DeploymentPatchListId,
        [parameter(Mandatory = $true)]
        [int]$DeploymentLengthInHours,
        [switch]$Force,
        [switch]$AllowClobber
    )

    # DeploymentConfiguration data
    $DeploymentConfiguration = @"
<Deployment id="999">
	<name>DO NOT DELETE - Manual Patch Deployment</name>
	<type>install</type>
	<startTime>2020-04-28 17:00:00</startTime>
	<endTime></endTime>
    <unmanaged>True</unmanaged>
	<downloadImmediately>true</downloadImmediately>
	<distributeOverTimeMinutes>0</distributeOverTimeMinutes>
	<overrideBlacklists>false</overrideBlacklists>
	<overrideMaintenanceWindows>true</overrideMaintenanceWindows>
	<restart>true</restart>
	<useTaniumClientTimeZone>true</useTaniumClientTimeZone>
	<stoppedAt></stoppedAt>
	<targetedComputerNames></targetedComputerNames>
	<retryLimit>5</retryLimit>
	<retryResetFrequencyInHours>24</retryResetFrequencyInHours>
	<requiredBlacklistManifestTime>2019-11-08 14:55:26</requiredBlacklistManifestTime>
	<requiredMaintenanceWindowManifestTime>2020-01-14 21:32:20</requiredMaintenanceWindowManifestTime>
	<patchListIdsWithLatestVersion>4</patchListIdsWithLatestVersion>
	<patchListsWithPinnedVersion>
	</patchListsWithPinnedVersion>
	<patchTaniumUids></patchTaniumUids>
	<InstallOrUninstallClientNotification></InstallOrUninstallClientNotification>
	<RestartClientNotification>
		<Notification id="13">
			<allowPostpone>true</allowPostpone>
			<postponeDurationInMinutes>1440</postponeDurationInMinutes>
			<countdownToDeadlineInMinutes>10</countdownToDeadlineInMinutes>
			<gentleNotificationDurationInMinutes>0.5</gentleNotificationDurationInMinutes>
			<userPostponementPeriodInMinutesOne>60</userPostponementPeriodInMinutesOne>
			<userPostponementPeriodInMinutesTwo>120</userPostponementPeriodInMinutesTwo>
			<userPostponementPeriodInMinutesThree>240</userPostponementPeriodInMinutesThree>
			<title>Restart Required</title>
			<icon></icon>
			<body>A restart is required to finish applying updates.</body>
			<bodyImage></bodyImage>
		</Notification>
	</RestartClientNotification>
</Deployment>
"@
    [xml]$DeploymentConfigurationXML = $DeploymentConfiguration
    $DeploymentConfigurationXML.Deployment.id = $DeploymentConfigurationId
    $DeploymentConfigurationXML.Deployment.patchListIdsWithLatestVersion = $DeploymentPatchListId -join ','
    $EndTime = (Get-Date ((Get-Date).AddHours($DeploymentLengthInHours)) -format "yyyy-MM-dd HH:mm:ss").toString()
    $DeploymentConfigurationXML.Deployment.endTime = $EndTime
    $DeploymentConfiguration = $DeploymentConfigurationXML.Deployment.OuterXml
    # end of deployment configuration data

    # Helper functions
    function Save-PatchConfiguration {
        param (
            [Parameter(Mandatory = $true)]
            [ValidateSet('scan', 'deployment')]
            $ConfigurationType
        )
        switch ($ConfigurationType) {
            'scan' {
                # test if scan configuration file exists first
                $ConfigurationFilePath = "$ScansDirectory\configurations\scan-configuration-$ScanConfigurationId.xml"
                if ((Test-Path $ConfigurationFilePath) -and $AllowClobber.IsPresent) {
                    Write-Verbose "$ConfigurationFilePath already exists. Overwriting."
                    # Generate File for scanning
                    Set-Content -Path $ConfigurationFilePath -Value $ScanConfiguration -Force | Out-Null
                    if (Test-Path $ConfigurationFilePath) {
                        Write-Verbose "Created $ConfigurationType configuration $ConfigurationFilePath"
                    }
                }
                elseif (Test-Path $ConfigurationFilePath) {
                    Write-Verbose "$ConfigurationFilePath already exists. Skipping."
                }
                else {
                    Write-Verbose "$ConfigurationFilePath doesn't exists. Continuing."
                    # Generate File for scanning
                    Set-Content -Path $ConfigurationFilePath -Value $ScanConfiguration | Out-Null
                    if (Test-Path $ConfigurationFilePath) {
                        Write-Verbose "Created $ConfigurationType configuration $ConfigurationFilePath"
                    }
                }
            }
            'deployment' {
                # test if file deployment configuration exists first
                $ConfigurationFilePath = "$DeploymentsDirectory\configurations\deployment-$DeploymentConfigurationId.xml"
                if ((Test-Path $ConfigurationFilePath) -and $AllowClobber.IsPresent) {
                    Write-Verbose "$ConfigurationFilePath already exists. Overwriting."
                    # Generate File for deployment
                    Set-Content -Path $ConfigurationFilePath -Value $DeploymentConfiguration -Force | Out-Null
                    Remove-TaniumClientPatchDeploymentStatus -Id $DeploymentConfigurationId
                    if (Test-Path $ConfigurationFilePath) {
                        Write-Verbose "Created $ConfigurationType configuration $ConfigurationFilePath"
                    }
                }
                elseif (Test-Path $ConfigurationFilePath) {
                    Write-Verbose "$ConfigurationFilePath already exists. Skipping."
                }
                else {
                    Write-Verbose "$ConfigurationFilePath doesn't exist. Continuing."

                    # Generate File for deployment
                    Set-Content -Path $ConfigurationFilePath -Value $DeploymentConfiguration | Out-Null
                    Remove-TaniumClientPatchDeploymentStatus -Id $DeploymentConfigurationId
                    if (Test-Path $ConfigurationFilePath) {
                        Write-Verbose "Created $ConfigurationType configuration $ConfigurationFilePath"
                    }
                }
            }
        }
    }
    # End of helper functions

    ### Begin main execution code ###
    Write-Verbose "Running with Force $($Force.IsPresent)"
    Write-Verbose "Running with AllowClobber $($AllowClobber.IsPresent)"
    # Get Tanium client directory
    $TaniumClientDirectory = Get-TaniumClientDirectory
    if ($TaniumClientDirectory) {
        # Set Patch directory
        $TaniumClientPatchDirectory = "$TaniumClientDirectory\Patch"
        # Set Patch deployments directory
        $DeploymentsDirectory = "$TaniumClientPatchDirectory\deployments"
        # Validate full path to Patch deployments directory
        if (Test-Path $DeploymentsDirectory) {
            # Get Patch Manager Process
            $PatchManagerProcess = Get-TaniumClientPatchManagerProcess
            # If the Patch manager process is already running and Force parameter exists, stop
            # the patch manager process and proceed.
            if ($PatchManagerProcess -and $Force.IsPresent) {
                Write-Verbose 'Found Tanium patch manager process. Stopping Tanium patch manager process.'
                Stop-Process -Id $PatchManagerProcess.ProcessId -Force
                Save-PatchConfiguration -ConfigurationType deployment
                Write-Verbose 'Check the Tanium client patch log for status.'
            }
            # If the patch manager process is already running and no Force paramter exists, abort.
            elseif ($PatchManagerProcess -and $Force.IsPresent) {
                Write-Warning 'Found Tanium patch manager process running. Aborting.'
            }
            # If the patch manager process is not already running, proceed.
            else {
                Write-Verbose 'Tanium Patch manager process not running, continuing.'
                Save-PatchConfiguration -ConfigurationType deployment
                Write-Verbose 'Check the Tanium client patch log for status.'
            }
        }
        # No Patch deployments folder.
        else {
            Write-Warning "Unable to find $DeploymentsDirectory"
        }
    }
    # No Tanium client folder found
    else {
        Write-Warning "Unable to determine Tanium Client directory."
    }
    ### end of main ###
}