# Tanium Candidates Analysis

Generated: 2025-10-14 10:46:50

## Overview

This report identifies scripts suitable for Tanium deployment:
- **Sensors**: Read-only data collection scripts
- **Packages**: Scripts that modify system state
- **Dual-Use**: Scripts useful for both Tanium and general sysadmin

## Statistics

- Tanium Sensors: 15
- Tanium Packages: 159
- Pipe-Delimited Output Scripts: 80
- Dual-Use Candidates: 16

## Tanium Sensors (Read-Only Data Collection)

These scripts are ideal Tanium sensor candidates - they collect and report data without modifying system state.

| Script | Lines | Indicators | Synopsis |
|--------|-------|------------|----------|
| Get-TaniumClientPatchBlocklist.ps1 | 18 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientPatchScanConfiguration.ps1 | 18 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientPatchMaintenanceWindow.ps1 | 18 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientPatchDeployment.ps1 | 20 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientPeer.ps1 | 21 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientPatchProcess.ps1 | 21 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientPatchManagerProcess.ps1 | 21 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientDeployProcess.ps1 | 21 | Tanium-Named; Sensor-Pattern | (No description) |
| Get-TaniumClientPatchTswProcess.ps1 | 22 | Tanium-Named; Sensor-Pattern | (No description) |
| MIGPendingRebootforTanium.ps1 | 234 | WOW64-Handling; Tanium-Named; Sensor-Pattern | Gets the pending reboot status on a local or remote computer |
| Get-TaniumClientPatchList.ps1 | 33 | Tanium-Named; Sensor-Pattern | (No description) |
| Stop-TaniumClientDeployProcess.ps1 | 37 | Tanium-Named; Sensor-Pattern | (No description) |
| Start-TaniumClientPatchDeployment.ps1 | 42 | Tanium-Named; Sensor-Pattern | (No description) |
| Stop-TaniumClient.ps1 | 45 | Tanium-Named; Sensor-Pattern | (No description) |
| Start-TaniumClientPatchTswProcess.ps1 | 58 | Tanium-Named; Sensor-Pattern | (No description) |

### File Paths

- `DeployOffice\Client\Get-TaniumClientPeer.ps1`
- `DeployOffice\Client\Stop-TaniumClient.ps1`
- `DeployOffice\Deploy\Get-TaniumClientDeployProcess.ps1`
- `DeployOffice\Deploy\Stop-TaniumClientDeployProcess.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchBlocklist.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchDeployment.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchList.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchMaintenanceWindow.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchManagerProcess.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchProcess.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchScanConfiguration.ps1`
- `DeployOffice\Patch\Get-TaniumClientPatchTswProcess.ps1`
- `DeployOffice\Patch\Start-TaniumClientPatchDeployment.ps1`
- `DeployOffice\Patch\Start-TaniumClientPatchTswProcess.ps1`
- `System-Monitoring-Reporting\Health-Monitoring\MIGPendingRebootforTanium.ps1`

## Tanium Packages (System Modification)

These scripts perform system modifications and are suitable for Tanium package deployment.

### By Category

#### DeployOffice (133 scripts)

- **Add-TaniumClientDeploySelfService.ps1** (78 lines)
  - Indicators: Tanium-Named
- **Disable-TaniumClientActionLock.ps1** (5 lines)
  - Indicators: Tanium-Named
- **Disable-TaniumClientDeploy.ps1** (12 lines)
  - Indicators: Tanium-Named
- **Disable-TaniumClientTpythonDebug.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Enable-TaniumClientActionLock.ps1** (5 lines)
  - Indicators: Tanium-Named
- **Enable-TaniumClientDeploy.ps1** (12 lines)
  - Indicators: Tanium-Named
- **Enable-TaniumClientTpythonDebug.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClient.ps1** (36 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientActionHistoryStatistics.ps1** (57 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientActionLock.ps1** (12 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientApiDownload.ps1** (66 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientApiToken.ps1** (29 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientCustomTag.ps1** (15 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientCxConfigurationManifestRevision.ps1** (54 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDbTable.ps1** (26 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployCatalogVersion.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployConfiguration.ps1** (23 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployDbFile.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployDbLog.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployDbTable.ps1** (21 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployDeployment.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployDirectory.ps1** (37 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployDownloads.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployEussActivities.ps1** (31 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployEussProfile.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployLog.ps1** (23 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployLogLevel.ps1** (28 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployMaintenanceWindow.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployProductInstallId.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployScanHistory.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployScanHistoryStatistics.ps1** (34 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployScanHistoryStatisticsByDay.ps1** (19 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeploySoftwareBundle.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeploySoftwarePackage.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDeployVersion.ps1** (18 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientDirectory.ps1** (66 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientEndpointConfigurationTool.ps1** (19 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientFileModificationTime.ps1** (14 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientHardening.ps1** (127 lines)
  - Indicators: SYSTEM-Context; Tanium-Named
- **Get-TaniumClientListenPort.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientLog.ps1** (42 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchActiveScanConfiguration.ps1** (19 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchApplicablePatches.ps1** (5 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchApplicableProducts.ps1** (5 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchCabAge.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchCabFileSize.ps1** (45 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchConfiguration.ps1** (43 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchData.ps1** (84 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchDeploymentResult.ps1** (12 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchDeploymentStatus.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchDirectory.ps1** (37 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchLatestErrors.ps1** (10 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchListApplicability.ps1** (55 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchLog.ps1** (23 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchManifest.ps1** (5 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchProductScanResults.ps1** (14 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchScanAge.ps1** (17 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchScanPriorities.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchScanResults.ps1** (18 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchScanStatistics.ps1** (34 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchScanStatus.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchSetting.ps1** (20 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchTswDb.ps1** (47 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchTswManifest.ps1** (5 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientPatchVersion.ps1** (4 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientProcessLoadedModules.ps1** (121 lines)
  - Indicators: WOW64-Handling; Tanium-Named
- **Get-TaniumClientRegistryPath.ps1** (23 lines)
  - Indicators: WOW64-Handling; Tanium-Named
- **Get-TaniumClientSensorHistoryStatistics.ps1** (54 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientSetting.ps1** (62 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientSettingCli.ps1** (21 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientSize.ps1** (20 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientSoapPort.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientTpython.ps1** (33 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientTpythonDebug.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientUninstallRegistry.ps1** (18 lines)
  - Indicators: WOW64-Handling; Tanium-Named
- **Get-TaniumClientVdiSetting.ps1** (14 lines)
  - Indicators: Tanium-Named
- **Get-TaniumClientVersion.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Install-ClicktoRunOffice.ps1** (1000 lines) - Install Click-to-Run Office as part of Tanium Deploy
  - Indicators: WOW64-Handling; Tanium-Named
- **Install-ClicktoRunOffice-NoVisioOrProject.ps1** (839 lines) - Install Click-to-Run Office as part of Tanium Deploy
  - Indicators: WOW64-Handling; Tanium-Named
- **Invoke-TaniumClientPatchPostUpgradePatchDeployment.ps1** (38 lines)
  - Indicators: Tanium-Named
- **New-Download.ps1** (121 lines)
  - Indicators: Tanium-Named
- **New-TaniumClientApiDownload.ps1** (65 lines)
  - Indicators: Tanium-Named
- **New-TaniumClientCustomTag.ps1** (20 lines)
  - Indicators: Tanium-Named
- **New-TaniumClientDeployDeployment.ps1** (71 lines)
  - Indicators: Tanium-Named
- **New-TaniumClientEndUserNotification.ps1** (155 lines)
  - Indicators: SYSTEM-Context; Tanium-Named
- **New-TaniumClientPatchDeployment.ps1** (193 lines) - Create a new Tanium Patch deployment
  - Indicators: Tanium-Named
- **Read-TaniumClientCxMailbox.ps1** (35 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientCustomTag.ps1** (20 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientPatchDeployment.ps1** (16 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientPatchDeploymentResult.ps1** (25 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientPatchDeploymentStatus.ps1** (26 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientPatchLatestErrors.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientPatchScanResults.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientPatchSettingsFile.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientSetting.ps1** (33 lines)
  - Indicators: Tanium-Named
- **Remove-TaniumClientVdiSetting.ps1** (14 lines)
  - Indicators: Tanium-Named
- **Restart-TaniumClient.ps1** (5 lines)
  - Indicators: Tanium-Named
- **Restart-TaniumClientCx.ps1** (32 lines)
  - Indicators: Tanium-Named
- **Restart-TaniumClientDeployProcess.ps1** (30 lines)
  - Indicators: Tanium-Named
- **Save-TaniumClientApiDownload.ps1** (14 lines)
  - Indicators: Tanium-Named
- **Search-TaniumClientDeployLog.ps1** (16 lines)
  - Indicators: Tanium-Named
- **Search-TaniumClientPatchLog.ps1** (16 lines)
  - Indicators: Tanium-Named
- **Send-TaniumClientSoapRequest.ps1** (36 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientDeployDbFile.ps1** (16 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientDeployDirectory.ps1** (16 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientDeployLogLevel.ps1** (30 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientPatchDirectory.ps1** (16 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientPatchProcessOptions.ps1** (20 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientSetting.ps1** (39 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientSettingCli.ps1** (17 lines)
  - Indicators: Tanium-Named
- **Set-TaniumClientVdiSetting.ps1** (20 lines)
  - Indicators: Tanium-Named
- **Start-TaniumClient.ps1** (15 lines)
  - Indicators: Tanium-Named
- **Start-TaniumClientDeployCatalogScan.ps1** (30 lines)
  - Indicators: Tanium-Named
- **Start-TaniumClientDeploySelfServiceClient.ps1** (28 lines)
  - Indicators: Tanium-Named
- **Start-TaniumClientDeploySelfServiceScan.ps1** (42 lines)
  - Indicators: Tanium-Named
- **Start-TaniumClientDeployWakeUp.ps1** (30 lines)
  - Indicators: Tanium-Named
- **Start-TaniumClientEndUserNotificationManager.ps1** (238 lines) - A generatic manager function to display Tanium End-User Notifications
  - Indicators: Tanium-Named
- **Start-TaniumClientPatchProcess.ps1** (22 lines)
  - Indicators: WOW64-Handling; Tanium-Named
- **Start-TaniumClientPatchScan.ps1** (170 lines) - Start a Tanium Patch scan
  - Indicators: Tanium-Named
- **Stop-TaniumClientApiDownload.ps1** (65 lines)
  - Indicators: Tanium-Named
- **Stop-TaniumClientPatchManagerProcess.ps1** (9 lines)
  - Indicators: Tanium-Named
- **Stop-TaniumClientPatchProcess.ps1** (9 lines)
  - Indicators: Tanium-Named
- **Stop-TaniumClientPatchTswProcess.ps1** (37 lines)
  - Indicators: Tanium-Named
- **Sync-TaniumClientDeployConfig.ps1** (44 lines)
  - Indicators: Tanium-Named
- **TaniumClient.psd1** (270 lines)
  - Indicators: Tanium-Named
- **Test-TaniumClientDirectoryAccess.ps1** (18 lines)
  - Indicators: Tanium-Named
- **Test-TaniumClientPatchTswDbPath.ps1** (7 lines)
  - Indicators: Tanium-Named
- **Test-TaniumClientPatchXmlFile.ps1** (95 lines)
  - Indicators: Tanium-Named
- **Test-TaniumClientPeering.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Update-TaniumClientPatchCabFile.ps1** (13 lines)
  - Indicators: Tanium-Named
- **Update-TaniumClientPatchDeployment.ps1** (33 lines)
  - Indicators: Tanium-Named
- **Watch-TaniumClientPatchDeployment.ps1** (90 lines) - Monitor a Tanium Patch deployment using Tanium End-User Notifications tools for logged in user
  - Indicators: Tanium-Named
- **Write-TaniumClientCxMailbox.ps1** (31 lines)
  - Indicators: Tanium-Named

#### Network-Infrastructure (6 scripts)

- **Invoke-Win10CompatScan.ps1** (290 lines) - Compatibility Scan for Windows 10 In Place Upgrade
  - Indicators: WOW64-Handling; Tanium-Named
- **Invoke-Win10PreCache.ps1** (366 lines) - Pre-Cache Windows 10 In Place Upgrade bits
  - Indicators: WOW64-Handling; Tanium-Named
- **Invoke-Win10PreCacheDirect.ps1** (366 lines) - Pre-Cache Windows 10 In Place Upgrade bits
  - Indicators: WOW64-Handling; Tanium-Named
- **Invoke-Win10Upgrade.ps1** (373 lines) - Windows 10 In Place Upgrade
  - Indicators: WOW64-Handling; Tanium-Named
- **Invoke-Win11PreCache.ps1** (366 lines) - Pre-Cache Windows 10 In Place Upgrade bits
  - Indicators: WOW64-Handling; Tanium-Named
- **Invoke-Win11PreCacheDirect.ps1** (366 lines) - Pre-Cache Windows 10 In Place Upgrade bits
  - Indicators: WOW64-Handling; Tanium-Named

#### Utilities-Tools (4 scripts)

- **BulkSNTix.ps1** (207 lines)
  - Indicators: Tanium-Named
- **Get-MSExchData.ps1** (340 lines) - Writes out passed error messages to errors
  - Indicators: WOW64-Handling; Tanium-Named; Registry-Read
- **Set-Mig_LocationTag.ps1** (72 lines)
  - Indicators: WOW64-Handling; Tanium-Named
- **WQL-LastModifiedExample.ps1** (1 lines)
  - Indicators: Tanium-Named

#### ActiveDirectory-UserManagement (4 scripts)

- **GetLastLoggedInUserDetails.ps1** (15 lines)
  - Indicators: Tanium-Named
- **GetPrimaryUserLocation.ps1** (6 lines)
  - Indicators: Tanium-Named
- **Get-PrimaryUserManager.ps1** (7 lines)
  - Indicators: Tanium-Named
- **Get-TaniumPrimaryorLoggedInUserProfilePath.ps1** (13 lines)
  - Indicators: Tanium-Named

#### System-Maintenance (3 scripts)

- **NewSafeDiskCleanUp.ps1** (96 lines)
  - Indicators: Tanium-Named
- **parseCBSLOG.ps1** (63 lines)
  - Indicators: Tanium-Named
- **RepairWMI.ps1** (379 lines)
  - Indicators: Tanium-Named

#### Security-Compliance (3 scripts)

- **Get-ClientAuthenticationCerts.ps1** (56 lines)
  - Indicators: Tanium-Named
- **Get-ClientAuthenticationCertsfromJSON.ps1** (22 lines)
  - Indicators: Tanium-Named
- **Set-ClientAuthenticationCertstoJSON.ps1** (53 lines)
  - Indicators: Tanium-Named

#### System-Monitoring-Reporting (2 scripts)

- **GetWindows10OSSKU.ps1** (100 lines)
  - Indicators: Tanium-Named
- **TaniumSucks.ps1** (1 lines)
  - Indicators: Tanium-Named

#### Development-Testing (1 scripts)

- **Test-Office64bit.ps1** (34 lines)
  - Indicators: Tanium-Named

#### Backup-Recovery (1 scripts)

- **CreateChromeBackupScheduledTask.ps1** (31 lines)
  - Indicators: Tanium-Named

#### Application-Management (1 scripts)

- **Copy-DBVisLicFile.ps1** (41 lines)
  - Indicators: Tanium-Named

#### Create-ScriptInventory.ps1 (1 scripts)

- **Create-ScriptInventory.ps1** (365 lines) - Creates a comprehensive inventory of PowerShell scripts in the repository
  - Indicators: WOW64-Handling; Tanium-Named; Registry-Read

## Scripts with Pipe-Delimited Output

These scripts output pipe-delimited data, making them excellent Tanium sensor candidates.

- `ActiveDirectory-UserManagement\User-Queries\AD Query - Altiris Primary User Details.ps1`
- `ActiveDirectory-UserManagement\User-Queries\AD Query - Altiris Primary User Group Member.ps1`
- `ActiveDirectory-UserManagement\User-Queries\GetLastLoggedInUserDetails.ps1`
- `ActiveDirectory-UserManagement\User-Queries\GetLastUserDetails.ps1`
- `ActiveDirectory-UserManagement\User-Queries\Get-PrimaryUserManager.ps1`
- `Application-Management\Chrome-Management\Fix-Chrome77JumpList.ps1`
- `Application-Management\General-Removers\Get-UninstallerDetailedInfo.ps1`
- `Application-Management\GetOdbcDsnsToJSON.ps1`
- `Application-Management\Software-Inventory\Get-InstalledSoftware_Tanium.ps1` - Short description
- `Application-Management\Tableau\Extract-TableauInstaller.ps1`
- `Backup-Recovery\GetSystemDriveShadowStorageMaxSize.ps1`
- `Create-ScriptInventory.ps1` - Creates a comprehensive inventory of PowerShell scripts in the repository
- `DeployOffice\Client\Get-TaniumClientActionHistoryStatistics.ps1`
- `DeployOffice\Client\Get-TaniumClientLog.ps1`
- `DeployOffice\Client\Get-TaniumClientProcessLoadedModules.ps1`
- `DeployOffice\Deploy\Get-TaniumClientDeployLog.ps1`
- `DeployOffice\Install-ClicktoRunOffice.ps1` - Install Click-to-Run Office as part of Tanium Deploy
- `DeployOffice\Install-ClicktoRunOffice-NoVisioOrProject.ps1` - Install Click-to-Run Office as part of Tanium Deploy
- `DeployOffice\Patch\Get-TaniumClientPatchLog.ps1`
- `Development-Testing\Find-Hack-Run.ps1`
- `Development-Testing\Invoke-VBScript.ps1` - Run VBScript from PowerShell
- `Development-Testing\ncsidiag.ps1`
- `Development-Testing\PSObjectBrowser.ps1`
- `Development-Testing\Show-ProcessTree.ps1`
- `Development-Testing\Test-MIAVC.ps1` - Short description
- `LidarrPS\Examples\Unmonitor-AlbumsFromCsv.ps1` - Unmonitors Lidarr albums listed in a CSV file
- `LidarrPS\Tests\Invoke-LidarrApi.Tests.ps1`
- `Network-Infrastructure\Get-8021x_Profiles.ps1`
- `Network-Infrastructure\Get-AttachedMonitorInfo_Tanium.ps1` - This PowerShell function gets information about the monitors attached to any computer
- `Network-Infrastructure\GetGeoIP.ps1` - Resolve IPAddress Geo IP Location
- `Network-Infrastructure\GetLocation.ps1`
- `Network-Infrastructure\GetTZConfiguration.ps1`
- `Network-Infrastructure\GetWindowsTimeSettings.ps1`
- `Network-Infrastructure\Get-WiredLANProfile.ps1`
- `Network-Infrastructure\Invoke-Win10CompatScan.ps1` - Compatibility Scan for Windows 10 In Place Upgrade
- `Network-Infrastructure\Invoke-Win10PreCacheDirect.ps1` - Pre-Cache Windows 10 In Place Upgrade bits
- `Network-Infrastructure\Invoke-Win10Upgrade.ps1` - Windows 10 In Place Upgrade
- `Network-Infrastructure\Invoke-Win11PreCacheDirect.ps1` - Pre-Cache Windows 10 In Place Upgrade bits
- `Network-Infrastructure\OneDriveMapper.ps1`
- `Office-Productivity\Get-OfficeAddIns.ps1`
- `Office-Productivity\MigrateOffice.ps1`
- `Office-Productivity\Office-365\Update-Office365.ps1`
- `Office-Productivity\SwitchOfficeC2RChannel.ps1` - Switches an Office Click-to-Run install from its existing channel to a new channel
- `ReadDhcpOptions\ReadDhcpOptions.ps1` - # Returns the string representation of a System
- `Security-Compliance\BitLocker\BitlockerLocalAdStatusReport.ps1` - Gets BitLocker recovery information for one or more Active Directory computer objects
- `Security-Compliance\Certificates\Get-ClientAuthenticationCerts.ps1`
- `Security-Compliance\Certificates\Get-ClientAuthenticationCertsfromJSON.ps1`
- `Security-Compliance\Certificates\Set-ClientAuthenticationCertstoJSON.ps1`
- `Security-Compliance\Compliance-Checks\HylandCompliance.ps1` - Short description
- `Security-Compliance\Compliance-Checks\HylandCompliance-CABITS770340L.ps1` - Short description
- `Security-Compliance\Device-Guard\Get-DeviceGuardStatus.ps1`
- `Security-Compliance\DGAvailableSecurityProperties.ps1`
- `Security-Compliance\DGCredentialGuard.ps1`
- `Security-Compliance\DGRequiredSecurityProperties.ps1`
- `Security-Compliance\TestIsRegistryPOLGood.ps1`
- `System-Maintenance\Get-MalformedPathEntries.ps1` - Analyzes the PATH environment variable for malformed entries
- `System-Maintenance\Invoke-CCMCacheCleanup.ps1` - Cleans the configuration manager client cache
- `System-Maintenance\parseCBSCSV.ps1`
- `System-Maintenance\parseCBSLOG.ps1`
- `System-Monitoring-Reporting\Hardware-Detection\GetSystemDriveBusandMediaType.ps1`
- `System-Monitoring-Reporting\Health-Monitoring\Find-WMIPigs.ps1` - Join data from two sets of objects based on a common value
- `System-Monitoring-Reporting\Health-Monitoring\Find-WMIPigs_nodelay.ps1` - # Join data from two sets of objects based on a common value #
- `System-Monitoring-Reporting\Health-Monitoring\Get-DriveHealthStats2.ps1`
- `System-Monitoring-Reporting\Health-Monitoring\Get-WMIActivityTrace.ps1`
- `System-Monitoring-Reporting\Health-Monitoring\MIGPendingRebootforTanium.ps1` - Gets the pending reboot status on a local or remote computer
- `System-Monitoring-Reporting\LockScreenInfo.ps1`
- `System-Monitoring-Reporting\OS-Information\GetNETFrameworkVersionScript.ps1`
- `System-Monitoring-Reporting\OS-Information\HWImageInfoSensor.ps1`
- `System-Monitoring-Reporting\OS-Information\NetFrameworkVersion.ps1` - Gets the version of the
- `Utilities-Tools\BulkSNTix.ps1`
- `Utilities-Tools\Convert-Subnetmask.ps1` - Convert a subnetmask to CIDR and vise versa
- `Utilities-Tools\GetBinaryTypeTaniumSensor.ps1`
- `Utilities-Tools\GetExplorerArch.ps1`
- `Utilities-Tools\get-indexedItem.ps1` - Gets files which have been indexed by Windows desktop search
- `Utilities-Tools\Get-MSExchData.ps1` - Writes out passed error messages to errors
- `Utilities-Tools\Import-WindowsErrorCode.ps1`
- `Utilities-Tools\TaniumFileHash.ps1`
- `Windows-Secure-Host-Baseline\Compliance\Scripts\Compliance.psm1` - Compares two string values based on conditions in valueData
- `Windows-Secure-Host-Baseline\Scripts\GitHub.psm1` - Gets the GitHub rate limit information for API access
- `Windows-Secure-Host-Baseline\Scripts\GroupPolicy.psm1` - Gets information about Group Policy Client Side Extensions available on the system

## Dual-Use Scripts

These scripts have Tanium indicators but are also useful as general utilities.

| Script | Functions | Indicators | Synopsis |
|--------|-----------|------------|----------|
| Compliance.psm1 | 24 | Registry-Read | Compares two string values based on conditions in valueData |
| Find-Hack-Run.ps1 | 1 | Sensor-Pattern | (No description) |
| GetBinaryType.ps1 | 1 | WOW64-Handling; Sensor-Pattern | Gets the binary executable type for a given set of files |
| GetGeoIP.ps1 | 1 | Sensor-Pattern | Resolve IPAddress Geo IP Location |
| GetLastUserDetails.ps1 | 1 | WOW64-Handling | (No description) |
| Get-MalformedPathEntries.ps1 | 1 | Sensor-Pattern | Analyzes the PATH environment variable for malformed entries |
| Get-ProcessBitness.ps1 | 1 | WOW64-Handling | (No description) |
| GetWindowsTimeSettings.ps1 | 1 | Registry-Read | (No description) |
| Install-SysInternalsSuite.ps1 | 1 | Registry-Read | (No description) |
| LockScreenInfo.ps1 | 7 | Registry-Read | (No description) |
| NetFrameworkVersion.ps1 | 1 | WOW64-Handling | Gets the version of the |
| OneDriveMapper.ps1 | 21 | Registry-Read | (No description) |
| ReadDhcpOptions.ps1 | 1 | Registry-Read | # Returns the string representation of a System |
| StartWPRSession.ps1 | 2 | Sensor-Pattern | Starts a Windows Performance Recorder (WPR) session |
| Test-InternetConnection.ps1 | 1 | Registry-Read; Sensor-Pattern | Tests for an internet connection |
| Update-Sysinternals.ps1 | 1 | Sensor-Pattern | (No description) |

## Recommendations

1. **Prioritize Sensors**: The 15 sensor scripts should be tested for Tanium sensor deployment first
2. **Package Review**: Review the 159 package candidates for deployment safety and WhatIf support
3. **Add Pipe Delimiters**: Consider modifying scripts to output pipe-delimited data for better Tanium integration
4. **Standardize Output**: Create a standard output format for all Tanium sensors
5. **Test in Lab**: Always test Tanium packages in a lab environment before production deployment

