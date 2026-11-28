# Inventory follow-up proposals

Proposed issue titles and bodies for the follow-up work the inventory in `INVENTORY.md` requires
(issue #50). These are the text to file under each epic; they are not created here. Agent hints are
included on each title line. Survivors are the rows whose Decision is `keep`, `fix`, or `move`.

## Archive parts (epic #51)

Archived files are the rows whose Decision is `retire`; survivors (`keep`, `fix`, or `move`) are
covered by the other parts, not here. Each part also removes the retired script's docs page and
test stub, and records the removal in `ARCHIVED.md`.

### Archive part 1 of 2

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Archive retired scripts, part 1 of 2 (#51)

**Scope:**

- `Packages/FileSystem/Copy-DBVisLicFile-Package.ps1`
- `docs/Copy-DBVisLicFile-Package.md`
- `Tests/Unit/Copy-DBVisLicFile-Package.Tests.ps1`
- `Packages/FileSystem/NewSafeDiskCleanUp-Package.ps1`
- `docs/NewSafeDiskCleanUp-Package.md`
- `Tests/Unit/NewSafeDiskCleanUp-Package.Tests.ps1`
- `Packages/General/BulkSNTix-Package.ps1`
- `docs/BulkSNTix-Package.md`
- `Tests/Unit/BulkSNTix-Package.Tests.ps1`
- `Packages/General/Generate-InventoryReports-Package.ps1`
- `docs/Generate-InventoryReports-Package.md`
- `Tests/Unit/Generate-InventoryReports-Package.Tests.ps1`
- `Packages/General/Get-MSExchData-Package.ps1`
- `docs/Get-MSExchData-Package.md`
- `Tests/Unit/Get-MSExchData-Package.Tests.ps1`
- `Packages/General/Implement-Reorganization-Package.ps1`
- `docs/Implement-Reorganization-Package.md`
- `Tests/Unit/Implement-Reorganization-Package.Tests.ps1`
- `Packages/General/Set-Mig_LocationTag-Package.ps1`
- `docs/Set-Mig_LocationTag-Package.md`
- `Tests/Unit/Set-Mig_LocationTag-Package.Tests.ps1`
- `Packages/General/WQL-LastModifiedExample-Package.ps1`
- `docs/WQL-LastModifiedExample-Package.md`
- `Tests/Unit/WQL-LastModifiedExample-Package.Tests.ps1`
- `Packages/Network/Create-ScriptInventory-Package.ps1`
- `docs/Create-ScriptInventory-Package.md`
- `Tests/Unit/Create-ScriptInventory-Package.Tests.ps1`
- `Packages/Security/Get-ClientAuthenticationCerts-Package.ps1`
- `docs/Get-ClientAuthenticationCerts-Package.md`
- `Tests/Unit/Get-ClientAuthenticationCerts-Package.Tests.ps1`

**Acceptance criteria:**

- Each script moves to `Archive/` with its existing path preserved under the archive root,
  per the retirement reasons recorded in `INVENTORY.md`.
- Each script's docs page and test stub (listed above) are removed with it.
- Create `ARCHIVED.md` at the repo root (later parts append to it) with a dated section that names
  this issue, records the commit SHA this part runs from (the last commit that still contains the
  files), and a `Path | What it did` table (descriptions from `INVENTORY.md`), noting each file can
  be restored with `git show <sha>:"<path>"`.
- No remaining script, test, docs page or README references a removed script by its old path. Grep
  the repository for each archived path and allow matches only in `ARCHIVED.md`, `INVENTORY.md` and
  `INVENTORY-FOLLOWUPS.md`, which keep the record on purpose.
- The Pester suite still passes after the moves and removals.

### Archive part 2 of 2

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Archive retired scripts, part 2 of 2 (#51)

**Scope:**

- `Packages/Security/Get-ClientAuthenticationCertsfromJSON-Package.ps1`
- `docs/Get-ClientAuthenticationCertsfromJSON-Package.md`
- `Tests/Unit/Get-ClientAuthenticationCertsfromJSON-Package.Tests.ps1`
- `Packages/Security/Set-ClientAuthenticationCertstoJSON-Package.ps1`
- `docs/Set-ClientAuthenticationCertstoJSON-Package.md`
- `Tests/Unit/Set-ClientAuthenticationCertstoJSON-Package.Tests.ps1`
- `Packages/System/RepairWMI-Package.ps1`
- `docs/RepairWMI-Package.md`
- `Tests/Unit/RepairWMI-Package.Tests.ps1`
- `Packages/System/TaniumSucks-Package.ps1`
- `docs/TaniumSucks-Package.md`
- `Tests/Unit/TaniumSucks-Package.Tests.ps1`
- `Sensors/General/Generate-RenamePlan-Sensor.ps1`
- `docs/Generate-RenamePlan-Sensor.md`
- `Tests/Unit/Generate-RenamePlan-Sensor.Tests.ps1`
- `Sensors/GetOdbcDsnsToJSON.ps1`

**Acceptance criteria:**

- Each script moves to `Archive/` with its existing path preserved under the archive root,
  per the retirement reasons recorded in `INVENTORY.md`.
- Each script's docs page and test stub (listed above) are removed with it.
- Append to `ARCHIVED.md` a dated section that names this issue, records the commit SHA this part
  runs from, and a `Path | What it did` table with the same `git show <sha>:"<path>"` restore note.
- No remaining script, test, docs page or README references a removed script by its old path. Grep
  the repository for each archived path and allow matches only in `ARCHIVED.md`, `INVENTORY.md` and
  `INVENTORY-FOLLOWUPS.md`, which keep the record on purpose.
- The Pester suite still passes after the moves and removals.


## Fix parts (inventory)

The four scripts whose Decision is `fix`. Behavior tests for these files belong to #62 after each fix
lands.

### Fix part 1 of 1

[mode: direct] [model: sonnet] [effort: high]

**Title:** Fix the four scripts flagged in the inventory, part 1 of 1

**Scope:**

- `Admin/Office/Get-TaniumClientPatchListApplicability-Package.ps1`
- `Packages/Office/TaniumClient.psd1-Package.ps1`
- `Packages/System/DisableSMBv3Compression.ps1`
- `Sensors/Get-ComputerInfo.ps1`

**Acceptance criteria:**

- `Packages/System/DisableSMBv3Compression.ps1`: set the SMB server `DisableCompression` value to `1` so
  it actually disables compression; keep the paired `Packages/System/EnableSMBv3Compression.ps1` at `0`
  (enables) so the two stay consistent.
- `Sensors/Get-ComputerInfo.ps1`: replace the undefined `$system` with `$ComputerSystem` so the sensor
  emits the model string instead of empty output.
- `Packages/Office/TaniumClient.psd1-Package.ps1`: make the manifest loadable (fix `ModuleToProcess` /
  `RootModule` and the module path, or document and implement the packaging step that colocates
  `Modules/TaniumClient.psm1` with the manifest); also add the exported helpers that have no file
  (`Get-PowerShellType`, `Get-Bitness`, `Test-Command`, `Read-XmlFile`, `Test-XmlFile`, `New-Download`,
  and the Patch process getters) or trim `FunctionsToExport`.
- `Admin/Office/Get-TaniumClientPatchListApplicability-Package.ps1`: finish the applicability evaluation
  so it emits a result, removing the placeholder logic.

Behavior tests for these files belong to #62 after the fix lands.

## Help parts (epic #3, milestone M5)

Survivors that stay in this repository (Decision `keep` or `fix`) whose `Help` cell in `INVENTORY.md`
is a missing-section list. The moved script is handled by the move part and gets its help in the
destination repository.

### Help part 1 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 1 of 16 (#3)

**Scope:**

- `Admin/Deploy/Add-TaniumClientDeploySelfService-Package.ps1`
- `Admin/Deploy/Get-TaniumClientDeployDownloads-Package.ps1`
- `Admin/FileSystem/Get-TaniumClientDeployDbFile-Package.ps1`
- `Admin/FileSystem/Get-TaniumClientDeployEussProfile-Package.ps1`
- `Admin/FileSystem/Get-TaniumClientPatchCabFileSize-Package.ps1`
- `Admin/FileSystem/Remove-TaniumClientPatchSettingsFile-Package.ps1`
- `Admin/FileSystem/Set-TaniumClientDeployDbFile-Package.ps1`
- `Admin/FileSystem/Test-TaniumClientPatchXmlFile-Package.ps1`
- `Admin/FileSystem/Update-TaniumClientPatchCabFile-Package.ps1`
- `Admin/Office/Disable-TaniumClientDeploy-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 2 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 2 of 16 (#3)

**Scope:**

- `Admin/Office/Enable-TaniumClientDeploy-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployCatalogVersion-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployConfiguration-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDbLog-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDbTable-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDeployment-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDirectory-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployEussActivities-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployLog-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployLogLevel-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 3 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 3 of 16 (#3)

**Scope:**

- `Admin/Office/Get-TaniumClientDeployMaintenanceWindow-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployScanHistory-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployScanHistoryStatistics-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployScanHistoryStatisticsByDay-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployVersion-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchActiveScanConfiguration-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchApplicablePatches-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchApplicableProducts-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchCabAge-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchConfiguration-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 4 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 4 of 16 (#3)

**Scope:**

- `Admin/Office/Get-TaniumClientPatchData-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchDeploymentResult-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchDeploymentStatus-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchDirectory-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchLatestErrors-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchListApplicability-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchLog-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchManifest-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchProductScanResults-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanAge-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 5 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 5 of 16 (#3)

**Scope:**

- `Admin/Office/Get-TaniumClientPatchScanPriorities-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanResults-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanStatistics-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanStatus-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchSetting-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchTswDb-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchTswManifest-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchVersion-Package.ps1`
- `Admin/Office/New-TaniumClientDeployDeployment-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchDeployment-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 6 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 6 of 16 (#3)

**Scope:**

- `Admin/Office/Remove-TaniumClientPatchDeploymentResult-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchDeploymentStatus-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchLatestErrors-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchScanResults-Package.ps1`
- `Admin/Office/Restart-TaniumClientDeployProcess-Package.ps1`
- `Admin/Office/Search-TaniumClientDeployLog-Package.ps1`
- `Admin/Office/Search-TaniumClientPatchLog-Package.ps1`
- `Admin/Office/Set-TaniumClientDeployDirectory-Package.ps1`
- `Admin/Office/Set-TaniumClientDeployLogLevel-Package.ps1`
- `Admin/Office/Set-TaniumClientPatchDirectory-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 7 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 7 of 16 (#3)

**Scope:**

- `Admin/Office/Set-TaniumClientPatchProcessOptions-Package.ps1`
- `Admin/Office/Start-TaniumClientDeployCatalogScan-Package.ps1`
- `Admin/Office/Start-TaniumClientDeploySelfServiceClient-Package.ps1`
- `Admin/Office/Start-TaniumClientDeploySelfServiceScan-Package.ps1`
- `Admin/Office/Start-TaniumClientDeployWakeUp-Package.ps1`
- `Admin/Office/Start-TaniumClientPatchProcess-Package.ps1`
- `Admin/Office/Stop-TaniumClientPatchManagerProcess-Package.ps1`
- `Admin/Office/Stop-TaniumClientPatchProcess-Package.ps1`
- `Admin/Office/Stop-TaniumClientPatchTswProcess-Package.ps1`
- `Admin/Office/Sync-TaniumClientDeployConfig-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 8 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 8 of 16 (#3)

**Scope:**

- `Admin/Office/Test-TaniumClientPatchTswDbPath-Package.ps1`
- `Admin/Office/Update-TaniumClientPatchDeployment-Package.ps1`
- `Admin/Software/TaniumClientDeployProductInstallId/Get-TaniumClientDeployProductInstallId-Package.ps1`
- `Admin/Software/TaniumClientDeploySoftwareBundle/Get-TaniumClientDeploySoftwareBundle-Package.ps1`
- `Admin/Software/TaniumClientDeploySoftwarePackage/Get-TaniumClientDeploySoftwarePackage-Package.ps1`
- `Admin/Software/WinGetPackage/7-Zip/25.01/machine/Install-7-Zip.ps1`
- `Admin/Software/WinGetPackage/7-Zip/25.01/machine/Remove-7-Zip.ps1`
- `Admin/Software/WinGetPackage/Get-WinGetPackage.ps1`
- `Admin/Software/WinGetPackage/Windows Notepad/Unknown/machine/Install-Windows Notepad.ps1`
- `Admin/Software/WinGetPackage/Windows Notepad/Unknown/machine/Remove-Windows Notepad.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 9 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 9 of 16 (#3)

**Scope:**

- `Admin/System/Invoke-TaniumClientPatchPostUpgradePatchDeployment-Package.ps1`
- `Modules/TaniumDeployPackage/Classes/PackageMetadata.Class.ps1`
- `Modules/TaniumDeployPackage/Private/Get-ArchitectureFromString.ps1`
- `Modules/TaniumDeployPackage/Private/Get-CompactOSName.ps1`
- `Modules/TaniumDeployPackage/Private/Get-InstallerVersion.ps1`
- `Modules/TaniumDeployPackage/Private/Get-SizeInMB.ps1`
- `Modules/TaniumDeployPackage/Public/Get-InstallerDefaults.ps1`
- `Modules/TaniumDeployPackage/Public/Invoke-FileDownload.ps1`
- `Modules/TaniumDeployPackage/Public/New-InstallScript.ps1`
- `Modules/TaniumDeployPackage/Public/New-MsixInstallScript.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 10 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 10 of 16 (#3)

**Scope:**

- `Modules/TaniumDeployPackage/Public/New-MsixRemoveScript.ps1`
- `Modules/TaniumDeployPackage/Public/New-PackageReadme.ps1`
- `Modules/TaniumDeployPackage/Public/New-RemoveScript.ps1`
- `Modules/TaniumDeployPackage/Public/New-TaniumDeployMetadata.ps1`
- `Packages/FileSystem/Get-PrimaryorLoggedInUserProfilePath-Package.ps1`
- `Packages/FileSystem/Get-TaniumClientFileModificationTime-Package.ps1`
- `Packages/General/New-TaniumClientEndUserNotification-Package.ps1`
- `Packages/General/Read-TaniumClientCxMailbox-Package.ps1`
- `Packages/Office/Disable-TaniumClientActionLock-Package.ps1`
- `Packages/Office/Disable-TaniumClientTpythonDebug-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 11 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 11 of 16 (#3)

**Scope:**

- `Packages/Office/Enable-TaniumClientActionLock-Package.ps1`
- `Packages/Office/Enable-TaniumClientTpythonDebug-Package.ps1`
- `Packages/Office/Get-TaniumClient-Package.ps1`
- `Packages/Office/Get-TaniumClientActionHistoryStatistics-Package.ps1`
- `Packages/Office/Get-TaniumClientActionLock-Package.ps1`
- `Packages/Office/Get-TaniumClientApiToken-Package.ps1`
- `Packages/Office/Get-TaniumClientCustomTag-Package.ps1`
- `Packages/Office/Get-TaniumClientCxConfigurationManifestRevision-Package.ps1`
- `Packages/Office/Get-TaniumClientDbTable-Package.ps1`
- `Packages/Office/Get-TaniumClientDirectory-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 12 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 12 of 16 (#3)

**Scope:**

- `Packages/Office/Get-TaniumClientEndpointConfigurationTool-Package.ps1`
- `Packages/Office/Get-TaniumClientHardening-Package.ps1`
- `Packages/Office/Get-TaniumClientListenPort-Package.ps1`
- `Packages/Office/Get-TaniumClientLog-Package.ps1`
- `Packages/Office/Get-TaniumClientSensorHistoryStatistics-Package.ps1`
- `Packages/Office/Get-TaniumClientSetting-Package.ps1`
- `Packages/Office/Get-TaniumClientSettingCli-Package.ps1`
- `Packages/Office/Get-TaniumClientSize-Package.ps1`
- `Packages/Office/Get-TaniumClientSoapPort-Package.ps1`
- `Packages/Office/Get-TaniumClientTpython-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 13 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 13 of 16 (#3)

**Scope:**

- `Packages/Office/Get-TaniumClientTpythonDebug-Package.ps1`
- `Packages/Office/Get-TaniumClientVdiSetting-Package.ps1`
- `Packages/Office/Get-TaniumClientVersion-Package.ps1`
- `Packages/Office/New-TaniumClientCustomTag-Package.ps1`
- `Packages/Office/Remove-TaniumClientCustomTag-Package.ps1`
- `Packages/Office/Remove-TaniumClientSetting-Package.ps1`
- `Packages/Office/Remove-TaniumClientVdiSetting-Package.ps1`
- `Packages/Office/Restart-TaniumClient-Package.ps1`
- `Packages/Office/Restart-TaniumClientCx-Package.ps1`
- `Packages/Office/Set-TaniumClientSetting-Package.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 14 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 14 of 16 (#3)

**Scope:**

- `Packages/Office/Set-TaniumClientSettingCli-Package.ps1`
- `Packages/Office/Set-TaniumClientVdiSetting-Package.ps1`
- `Packages/Office/Start-TaniumClient-Package.ps1`
- `Packages/Office/Test-Office64bit-Package.ps1`
- `Packages/Office/Test-TaniumClientDirectoryAccess-Package.ps1`
- `Packages/Office/Test-TaniumClientPeering-Package.ps1`
- `Packages/Office/Write-TaniumClientCxMailbox-Package.ps1`
- `Packages/Registry/Get-TaniumClientRegistryPath-Package.ps1`
- `Packages/Registry/Get-TaniumClientUninstallRegistry-Package.ps1`
- `Packages/System/DisableSMBv3Compression.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 15 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 15 of 16 (#3)

**Scope:**

- `Packages/System/EnableSMBv3Compression.ps1`
- `Packages/System/Get-TaniumClientProcessLoadedModules-Package.ps1`
- `Packages/System/GetWindows10OSSKU-Package.ps1`
- `Packages/System/parseCBSLOG-Package.ps1`
- `Packages/Templates/RateLimiting-Helpers.ps1`
- `Sensors/Get-ComputerInfo.ps1`
- `Sensors/Get-PrimaryUserManager.ps1`
- `Sensors/Get-RateLimitStatus.ps1`
- `Sensors/GetLastLoggedInUserDetails.ps1`
- `Sensors/GetOSBrandName.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.

### Help part 16 of 16

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Add comment-based help, part 16 of 16 (#3)

**Scope:**

- `Sensors/GetOSSetupDate.ps1`
- `Sensors/GetPrimaryUserLocation.ps1`
- `Sensors/GetSystemDriveBusandMediaType.ps1`
- `Sensors/Get_SecureBootStatus.ps1`
- `Sensors/HasWirelessAdapter.ps1`

**Acceptance criteria:**

- Each script below is brought to `Complete` in the `INVENTORY.md` `Help` column: the sections its
  `Help` cell lists as missing (`SYNOPSIS`, `DESCRIPTION`, `PARAMETER`, `EXAMPLE`, `NOTES`) are added,
  per STANDARDS R-07 (and R-29 for admin/API scripts: at least two `.EXAMPLE` entries and a
  `.PARAMETER` for every parameter).
- The #48 help-grade check passes for each script, and the Pester suite still passes.


## Test parts (epic #62, milestone M7)

Survivors that stay in this repository (Decision `keep` or `fix`). Every one is listed here: most
have only a parse-only test stub today, and a survivor with no test file gets a new one. The moved
script is handled by the move part and gets its tests in the destination repository.

### Test part 1 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 1 of 17 (#62)

**Scope:**

- `Admin/Deploy/Add-TaniumClientDeploySelfService-Package.ps1`
- `Admin/Deploy/Get-TaniumClientDeployDownloads-Package.ps1`
- `Admin/FileSystem/Get-TaniumClientDeployDbFile-Package.ps1`
- `Admin/FileSystem/Get-TaniumClientDeployEussProfile-Package.ps1`
- `Admin/FileSystem/Get-TaniumClientPatchCabFileSize-Package.ps1`
- `Admin/FileSystem/Remove-TaniumClientPatchSettingsFile-Package.ps1`
- `Admin/FileSystem/Set-TaniumClientDeployDbFile-Package.ps1`
- `Admin/FileSystem/Test-TaniumClientPatchXmlFile-Package.ps1`
- `Admin/FileSystem/Update-TaniumClientPatchCabFile-Package.ps1`
- `Admin/Office/Disable-TaniumClientDeploy-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 2 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 2 of 17 (#62)

**Scope:**

- `Admin/Office/Enable-TaniumClientDeploy-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployCatalogVersion-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployConfiguration-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDbLog-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDbTable-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDeployment-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployDirectory-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployEussActivities-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployLog-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployLogLevel-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 3 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 3 of 17 (#62)

**Scope:**

- `Admin/Office/Get-TaniumClientDeployMaintenanceWindow-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployScanHistory-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployScanHistoryStatistics-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployScanHistoryStatisticsByDay-Package.ps1`
- `Admin/Office/Get-TaniumClientDeployVersion-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchActiveScanConfiguration-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchApplicablePatches-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchApplicableProducts-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchCabAge-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchConfiguration-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 4 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 4 of 17 (#62)

**Scope:**

- `Admin/Office/Get-TaniumClientPatchData-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchDeploymentResult-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchDeploymentStatus-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchDirectory-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchLatestErrors-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchListApplicability-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchLog-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchManifest-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchProductScanResults-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanAge-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 5 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 5 of 17 (#62)

**Scope:**

- `Admin/Office/Get-TaniumClientPatchScanPriorities-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanResults-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanStatistics-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchScanStatus-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchSetting-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchTswDb-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchTswManifest-Package.ps1`
- `Admin/Office/Get-TaniumClientPatchVersion-Package.ps1`
- `Admin/Office/New-TaniumClientDeployDeployment-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchDeployment-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 6 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 6 of 17 (#62)

**Scope:**

- `Admin/Office/Remove-TaniumClientPatchDeploymentResult-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchDeploymentStatus-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchLatestErrors-Package.ps1`
- `Admin/Office/Remove-TaniumClientPatchScanResults-Package.ps1`
- `Admin/Office/Restart-TaniumClientDeployProcess-Package.ps1`
- `Admin/Office/Search-TaniumClientDeployLog-Package.ps1`
- `Admin/Office/Search-TaniumClientPatchLog-Package.ps1`
- `Admin/Office/Set-TaniumClientDeployDirectory-Package.ps1`
- `Admin/Office/Set-TaniumClientDeployLogLevel-Package.ps1`
- `Admin/Office/Set-TaniumClientPatchDirectory-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 7 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 7 of 17 (#62)

**Scope:**

- `Admin/Office/Set-TaniumClientPatchProcessOptions-Package.ps1`
- `Admin/Office/Start-TaniumClientDeployCatalogScan-Package.ps1`
- `Admin/Office/Start-TaniumClientDeploySelfServiceClient-Package.ps1`
- `Admin/Office/Start-TaniumClientDeploySelfServiceScan-Package.ps1`
- `Admin/Office/Start-TaniumClientDeployWakeUp-Package.ps1`
- `Admin/Office/Start-TaniumClientPatchProcess-Package.ps1`
- `Admin/Office/Stop-TaniumClientPatchManagerProcess-Package.ps1`
- `Admin/Office/Stop-TaniumClientPatchProcess-Package.ps1`
- `Admin/Office/Stop-TaniumClientPatchTswProcess-Package.ps1`
- `Admin/Office/Sync-TaniumClientDeployConfig-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 8 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 8 of 17 (#62)

**Scope:**

- `Admin/Office/Test-TaniumClientPatchTswDbPath-Package.ps1`
- `Admin/Office/Update-TaniumClientPatchDeployment-Package.ps1`
- `Admin/Software/TaniumClientDeployProductInstallId/Get-TaniumClientDeployProductInstallId-Package.ps1`
- `Admin/Software/TaniumClientDeploySoftwareBundle/Get-TaniumClientDeploySoftwareBundle-Package.ps1`
- `Admin/Software/TaniumClientDeploySoftwarePackage/Get-TaniumClientDeploySoftwarePackage-Package.ps1`
- `Admin/Software/UpdateCatalogPackage/Get-UpdateCatalogPackage.ps1`
- `Admin/Software/WinGetPackage/7-Zip/25.01/machine/Install-7-Zip.ps1`
- `Admin/Software/WinGetPackage/7-Zip/25.01/machine/Remove-7-Zip.ps1`
- `Admin/Software/WinGetPackage/Get-WinGetPackage.ps1`
- `Admin/Software/WinGetPackage/Windows Notepad/Unknown/machine/Install-Windows Notepad.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 9 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 9 of 17 (#62)

**Scope:**

- `Admin/Software/WinGetPackage/Windows Notepad/Unknown/machine/Remove-Windows Notepad.ps1`
- `Admin/System/Invoke-TaniumClientPatchPostUpgradePatchDeployment-Package.ps1`
- `Modules/TaniumClient.psm1`
- `Modules/TaniumDeployPackage/Classes/PackageMetadata.Class.ps1`
- `Modules/TaniumDeployPackage/Private/Get-ArchitectureFromString.ps1`
- `Modules/TaniumDeployPackage/Private/Get-CompactOSName.ps1`
- `Modules/TaniumDeployPackage/Private/Get-InstallerVersion.ps1`
- `Modules/TaniumDeployPackage/Private/Get-SizeInMB.ps1`
- `Modules/TaniumDeployPackage/Public/Get-InstallerDefaults.ps1`
- `Modules/TaniumDeployPackage/Public/Invoke-FileDownload.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 10 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 10 of 17 (#62)

**Scope:**

- `Modules/TaniumDeployPackage/Public/New-InstallScript.ps1`
- `Modules/TaniumDeployPackage/Public/New-MsixInstallScript.ps1`
- `Modules/TaniumDeployPackage/Public/New-MsixRemoveScript.ps1`
- `Modules/TaniumDeployPackage/Public/New-PackageReadme.ps1`
- `Modules/TaniumDeployPackage/Public/New-RemoveScript.ps1`
- `Modules/TaniumDeployPackage/Public/New-TaniumDeployMetadata.ps1`
- `Modules/TaniumDeployPackage/TaniumDeployPackage.psm1`
- `Packages/FileSystem/Get-PrimaryorLoggedInUserProfilePath-Package.ps1`
- `Packages/FileSystem/Get-TaniumClientFileModificationTime-Package.ps1`
- `Packages/General/New-TaniumClientEndUserNotification-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 11 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 11 of 17 (#62)

**Scope:**

- `Packages/General/Read-TaniumClientCxMailbox-Package.ps1`
- `Packages/Maintenance/Remove-ExpiredRateLimits-Package.ps1`
- `Packages/Office/Disable-TaniumClientActionLock-Package.ps1`
- `Packages/Office/Disable-TaniumClientTpythonDebug-Package.ps1`
- `Packages/Office/Enable-TaniumClientActionLock-Package.ps1`
- `Packages/Office/Enable-TaniumClientTpythonDebug-Package.ps1`
- `Packages/Office/Get-TaniumClient-Package.ps1`
- `Packages/Office/Get-TaniumClientActionHistoryStatistics-Package.ps1`
- `Packages/Office/Get-TaniumClientActionLock-Package.ps1`
- `Packages/Office/Get-TaniumClientApiToken-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 12 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 12 of 17 (#62)

**Scope:**

- `Packages/Office/Get-TaniumClientCustomTag-Package.ps1`
- `Packages/Office/Get-TaniumClientCxConfigurationManifestRevision-Package.ps1`
- `Packages/Office/Get-TaniumClientDbTable-Package.ps1`
- `Packages/Office/Get-TaniumClientDirectory-Package.ps1`
- `Packages/Office/Get-TaniumClientEndpointConfigurationTool-Package.ps1`
- `Packages/Office/Get-TaniumClientHardening-Package.ps1`
- `Packages/Office/Get-TaniumClientListenPort-Package.ps1`
- `Packages/Office/Get-TaniumClientLog-Package.ps1`
- `Packages/Office/Get-TaniumClientSensorHistoryStatistics-Package.ps1`
- `Packages/Office/Get-TaniumClientSetting-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 13 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 13 of 17 (#62)

**Scope:**

- `Packages/Office/Get-TaniumClientSettingCli-Package.ps1`
- `Packages/Office/Get-TaniumClientSize-Package.ps1`
- `Packages/Office/Get-TaniumClientSoapPort-Package.ps1`
- `Packages/Office/Get-TaniumClientTpython-Package.ps1`
- `Packages/Office/Get-TaniumClientTpythonDebug-Package.ps1`
- `Packages/Office/Get-TaniumClientVdiSetting-Package.ps1`
- `Packages/Office/Get-TaniumClientVersion-Package.ps1`
- `Packages/Office/New-TaniumClientCustomTag-Package.ps1`
- `Packages/Office/Remove-TaniumClientCustomTag-Package.ps1`
- `Packages/Office/Remove-TaniumClientSetting-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 14 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 14 of 17 (#62)

**Scope:**

- `Packages/Office/Remove-TaniumClientVdiSetting-Package.ps1`
- `Packages/Office/Restart-TaniumClient-Package.ps1`
- `Packages/Office/Restart-TaniumClientCx-Package.ps1`
- `Packages/Office/Set-TaniumClientSetting-Package.ps1`
- `Packages/Office/Set-TaniumClientSettingCli-Package.ps1`
- `Packages/Office/Set-TaniumClientVdiSetting-Package.ps1`
- `Packages/Office/Start-TaniumClient-Package.ps1`
- `Packages/Office/TaniumClient.psd1-Package.ps1`
- `Packages/Office/Test-Office64bit-Package.ps1`
- `Packages/Office/Test-TaniumClientDirectoryAccess-Package.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 15 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 15 of 17 (#62)

**Scope:**

- `Packages/Office/Test-TaniumClientPeering-Package.ps1`
- `Packages/Office/Write-TaniumClientCxMailbox-Package.ps1`
- `Packages/Registry/Get-TaniumClientRegistryPath-Package.ps1`
- `Packages/Registry/Get-TaniumClientUninstallRegistry-Package.ps1`
- `Packages/System/DisableSMBv3Compression.ps1`
- `Packages/System/EnableSMBv3Compression.ps1`
- `Packages/System/Get-TaniumClientProcessLoadedModules-Package.ps1`
- `Packages/System/GetWindows10OSSKU-Package.ps1`
- `Packages/System/parseCBSLOG-Package.ps1`
- `Packages/Templates/RateLimiting-Helpers.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 16 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 16 of 17 (#62)

**Scope:**

- `Sensors/Get-ComputerInfo.ps1`
- `Sensors/Get-PrimaryUserManager.ps1`
- `Sensors/Get-RateLimitStatus.ps1`
- `Sensors/GetLastLoggedInUserDetails.ps1`
- `Sensors/GetOSBrandName.ps1`
- `Sensors/GetOSSetupDate.ps1`
- `Sensors/GetPrimaryUserLocation.ps1`
- `Sensors/GetSystemDriveBusandMediaType.ps1`
- `Sensors/Get_SecureBootStatus.ps1`
- `Sensors/HasWirelessAdapter.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.

### Test part 17 of 17

[mode: direct] [model: sonnet] [effort: high]

**Title:** Add behavior tests, part 17 of 17 (#62)

**Scope:**

- `Sensors/System/MIGPendingRebootforTanium-Sensor.ps1`

**Acceptance criteria:**

- Each script gets behavior tests, replacing its parse-only stub where one exists (or as a new test
  file where none does), covering its real success path and at least one failure or edge case,
  without changing the machine the tests run on.
- Tests follow the `Tests/Unit` and `Tests/TestHelpers.psm1` conventions.
- The full Pester suite passes, including the new tests.


## Move parts (out of this repository)

### Move part 1 of 1

[mode: direct] [model: sonnet] [effort: medium]

**Title:** Move generic Windows tooling to powershell-utilities, part 1 of 1

**Scope:**

- `Packages/General/CreateChromeBackupScheduledTask-Package.ps1`
- `Tests/Unit/CreateChromeBackupScheduledTask-Package.Tests.ps1` (removed with the script, so no stub targets a missing file)

**Acceptance criteria:**

- Each script moves to the matching `Scripts/` area of powershell-utilities, with its move recorded
  there in `MIGRATION.md` and its path here removed.
- Its paired test is removed here with it, so the repository hygiene check that every stub targets an
  existing script still passes.
- No Tanium-specific dependency is introduced; any hard-coded path is parameterized as part of the move.
- The destination repository (powershell-utilities) supplies the moved script's comment-based help and
  behavior tests under its own standards; no help or test work for it is tracked in this repository.
- Both repositories' test suites still pass.
