
<#
.SYNOPSIS
Start a Tanium Patch scan.
.DESCRIPTION
This script will generate a Tanium Patch scan configuration and force an immediate scan
on an endpoint. The generated scan configuration file will be removed after the scan.
.PARAMETER ScanConfigurationId
Enter a scan ID only if the default of 999 is already in use.
.PARAMETER ScanMethod
Choose the scan method/technique to use for scanning. The default is to use cab scan which assumes
the latest CAB file is already present by normal Tanium Patch processes.
The tanium scan method may need to be run twice. The first pass does a product applicability scan,
and the second pass does the actually scan.
.PARAMETER Force
Use the Force option if you want to stop an already running Tanium patch manager process.
The patch manager process may already be running a scan or a deployment.
.NOTES
Created by: Jason Wasser
Modified: 2020-05-01
.EXAMPLE
Start-TaniumPatchScan

Start a Tanium Patch scan using the offline cab file method.
.EXAMPLE
Start-TaniumPatchScan -ScanMethod tanium

Start a Tanium Patch scan using the Tanium Scan for Windows technique.
.EXAMPLE
Start-TaniumPatchScan -ScanMethd tanium -ScanConfigurationId 1001 -Force

Start a Tanium Patch scan using the Tanium Scan for Windows method, specifying a specific scan id,
and stopping any existing patch manager process.
#>
function Start-TaniumClientPatchScan {
    [cmdletbinding()]
    param(
        [string]$ScanConfigurationId = '999',
        [ValidateSet('cab', 'tanium', 'wsus', 'online')]
        [string]$ScanMethod = 'cab',
        [switch]$Force,
        [bool]$SkipCleanup = $false
    )

    # ScanConfiguration data
    $ScanConfiguration = @"
<ScanConfiguration id="999" version="2" enforcedGroupIds="102">
    <name>Manual CAB Scan</name>
    <scanUponNewCab>true</scanUponNewCab>
    <technique>cab</technique>
    <frequencyInHours>8</frequencyInHours>
    <randomScanDelayMinutes>0</randomScanDelayMinutes>
    <maxAgeMinutes></maxAgeMinutes>
    <requireWsusPatchApproval>true</requireWsusPatchApproval>
    <postTaniumScanWsusScan>false</postTaniumScanWsusScan>
    <useSnapshotForDeployment>false</useSnapshotForDeployment>
    <directDownload>false</directDownload>
    <schedule></schedule>
</ScanConfiguration>
"@

    [xml]$ScanConfigurationXML = $ScanConfiguration
    $ScanConfigurationXML.ScanConfiguration.name = "Manual $ScanMethod Scan"
    $ScanConfigurationXML.ScanConfiguration.id = [string]$ScanConfigurationId
    $ScanConfigurationXML.ScanConfiguration.technique = $ScanMethod
    $ScanConfiguration = $ScanConfigurationXML.ScanConfiguration.OuterXml
    # end of scan configuration data

    # Helper functions
    function Start-PatchScan {
        # test if file scan configuration exists first
        $ScanConfigurationFilePath = "$ScansDirectory\configurations\scan-configuration-$ScanConfigurationId.xml"
        if (Test-Path $ScanConfigurationFilePath) {
            Write-Verbose "$ScanConfigurationFilePath already exists. Skipping scan."
        }
        else {
            Write-Verbose "$ScanConfigurationFilePath doesn't exists. Continuing to scan."

            # Generate File for scanning
            Set-Content -Path $ScanConfigurationFilePath -Value $ScanConfiguration | Out-Null
            $ScanConfigurationFile = Get-Item -Path $ScanConfigurationFilePath

            # Intiate scan
            $ScanCommand = "$ENV:WINDIR\system32\cscript.exe //nologo `"$TaniumClientPatchDirectory\tools\run-patch-manager.min.vbs`" /Operation:scan /ScanConfigID:$ScanConfigurationId /LogLevel:3 /ExecTimeoutInSeconds:45"
            if ($ScanMethod -eq 'tanium') {
                $PatchScanTime = Get-TaniumClientFileModificationTime -Path "$TaniumClientPatchDirectory\scans\patch-scan-results.txt"
                $ProductScanTime = Get-TaniumClientFileModificationTime -Path "$TaniumClientPatchDirectory\scans\tsw-product-applicability-results.txt"
                if ($PatchScanTime -and ($ProductScanTime -gt $PatchScanTime)) {
                    Write-Verbose "Executing $ScanCommand"
                    Invoke-Expression $ScanCommand
                    Write-Verbose "Patch scan completed."
                }
                else {
                    Write-Verbose "Executing $ScanCommand product applicability scan"
                    Invoke-Expression $ScanCommand
                    Write-Verbose "Product applicability scan completed."
                    # May have to regenerate the scan configuration here in case ECF deleted it
                    if (Test-Path -Path $ScanConfigurationFilePath) {
                        Write-Verbose "$ScanConfigurationFilePath still exists. Continuing with patch scan."
                    }
                    else {
                        Write-Verbose "$ScanConfigurationFilePath does not exist. Regenerating configuration file."
                        Set-Content -Path $ScanConfigurationFilePath -Value $ScanConfiguration | Out-Null
                    }
                    Write-Verbose "Executing $ScanCommand patch scan"
                    Invoke-Expression $ScanCommand
                    Write-Verbose "Patch scan completed."
                }
            }
            else {
                Write-Verbose "Executing $ScanCommand"
                Invoke-Expression $ScanCommand
                Write-Verbose "Patch scan completed."
            }
            if ($SkipCleanup -eq $false) {
                if (Test-Path -Path $ScanConfigurationFile) {
                    Write-Verbose "Cleaning up scan configuration file."
                    Remove-Item -Path $ScanConfigurationFile
                }
                else {
                    Write-Verbose "$ScanConfigurationFile has already been removed. Skipping cleanup."
                }
            }
            else {
                Write-Verbose "Skipping removal of scan configuration: $SkipCleanup"
            }
        }
    }
    # End of helper functions

    # Begin main execution code
    # Get Tanium client directory
    $TaniumClientDirectory = Get-TaniumClientDirectory
    if ($TaniumClientDirectory) {
        # Set Patch directory
        $TaniumClientPatchDirectory = "$TaniumClientDirectory\Patch"
        # Set Patch scans directory
        $ScansDirectory = "$TaniumClientPatchDirectory\Scans"
        # Validate full path to Patch scans directory
        if (Test-Path $ScansDirectory) {
            # Get Patch Manager Process
            $PatchManagerProcess = Get-TaniumClientPatchManagerProcess
            # If the Patch manager process is already running and Force parameter exists, stop
            # the patch manager process and proceed with scan.
            if ($PatchManagerProcess -and $Force.IsPresent) {
                Write-Verbose 'Found Tanium patch manager process. Stopping Tanium patch manager process.'
                Stop-Process -Id $PatchManagerProcess.ProcessId -Force
                Start-PatchScan
            }
            # If the patch manager process is already running and no Force paramter exists, abort scan.
            elseif ($PatchManagerProcess -and $Force.IsPresent -eq $false) {
                Write-Verbose 'Found Tanium patch manager process running. Aborting.'
            }
            # If the patch manager process is not already running, proceed with scan.
            else {
                Write-Verbose 'Tanium Patch manager process not running, continuing.'
                Start-PatchScan
            }
        }
        # No Patch scans folder.
        else {
            Write-Verbose "Unable to find $ScansDirectory"
        }
    }
    # No Tanium client folder found
    else {
        Write-Verbose "Unable to determine Tanium Client directory."
    }
    # end of main
}