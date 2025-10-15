<#
.SYNOPSIS
Install Click-to-Run Office as part of Tanium Deploy.
.DESCRIPTION
Install Click-to-Run Office products as part of Tanium Deploy. Supported operations include install, update, and remove for the
supported channels of Office.
.NOTES
Prerequisites
 * Office Deployment Tool (ODT)
 * Required file list
 * TaniumClient PowerShell module

Created by: Jason Wasser
Modified: 2022-05-16
.PARAMETER Operation
Choose desired operation: Install, Update, Remove
.PARAMETER Channel
Specify the Office channel: Current, SemiAnnual, SemiAnnualPreview, MonthlyEnterprise, PerpetualVL2019, PerpetualVL2021
.PARAMETER Arch
Choose the Office architecture: 32 or 64
.PARAMETER Version
Specify the version of Office version. See https://config.office.com for available versions.
.PARAMETER LogPath
Enter a path for logging. Default log will be <Tanium Client>\SoftwareManagement\logs\Install-ClicktoRunOffice.log.
.PARAMETER ForceCloseApps
Adds the ForceCloseApps to the configuration.xml to ensure all Office apps are closed to complete the operation.
.PARAMETER DownloadTimeOut
Specify a download timeout in seconds.
.PARAMETER MaxDownloadAttempts
Specify a maximum number of download attempts/retries.
.PARAMETER DownloadMethod
auto - Detects if a Tanium client is peering. If peering, default to Tanium client API download. If not peering, then validate Office CDN connectivity and download directly. Falls back to Tanium client API downloads if unable to connect directly.
web - The ODT setup.exe will download any necessary files directly. Falls back to Tanium client API downloads if unable to connect directly.
tanium - Use Tanium client API architecture to download required files.
.PARAMETER DownloadOnly
This switch can be used to download the required files for future installation.
.EXAMPLE
.\Install-ClicktoRunOffice.ps1 -Operation Install -Channel PerpetualVL2021 -Arch 64 -Version 16.0.14332.20110 -ForceCloseApps -DownloadMethod auto
Installs Office 2021 x64 version 16.0.14332.20110 and forces the close of any Office apps. Download method will be automatically determined by Tanium client peering and Office CDN connectivity.
.EXAMPLE
.\Install-ClicktoRunOffice.ps1 -Operation Install -Channel PerpetualVL2021 -Arch 64 -Version 16.0.14332.20110 -ForceCloseApps -DownloadMethod web
Installs Office 2021 x64 version 16.0.14332.20110 and forces the close of any Office apps. The ODT setup.exe will attempt to download necessary files directly, but will fall back to Tanium Client API download method if unable to connect.
#>
[cmdletbinding()]
param (
    [Parameter(Mandatory)]
    [ValidateSet('Install', 'Update', 'Remove')]
    [string]$Operation,
    [ValidateSet('Current', 'SemiAnnual', 'SemiAnnualPreview', 'MonthlyEnterprise', 'PerpetualVL2019', 'PerpetualVL2021')]
    [string]$Channel = 'Current',
    [ValidateSet('64', '32')]
    [string]$Arch = '64',
    [ValidatePattern('\d+\.\d+\.\d+\.\d+')]
    [string]$Version = '16.0.13929.20296',
    [string]$LogPath = 'Office.log',
    [switch]$ForceCloseApps,
    [int]$DownloadTimeout = 14400,
    [int]$MaxDownloadAttempts = 3,
    [ValidateSet('auto', 'web', 'tanium')]
    [string]$DownloadMethod = 'auto',
    [switch]$DownloadOnly
)

<# To Do
* Add ability to install visio, project, and/or additional language packs and proof packs via parameters
#>

#Requires -Modules TaniumClient

# Begin Helper Functions
function Write-Log {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [Alias('LogPath')]
        [string]$Path = 'C:\Logs\PowerShellLog.log',

        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info")]
        [string]$Level = "Info",

        [Parameter(Mandatory = $false)]
        [switch]$NoClobber
    )

    Begin {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process {

        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
        }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            New-Item $Path -Force -ItemType File | Out-Null
        }

        else {
            # Nothing to see here yet.
        }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
            }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
            }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
            }
        }
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End {}
}

function Test-OfficeCdnConnectivity {
    param (
        $Uri = 'https://officecdn.microsoft.com/pr/wsus/ofl.cab'
    )
    Write-Verbose "Attempting to read file size from $Uri"
    try {
        [int]$Size = (Invoke-WebRequest -Uri $Uri -Method Head -ErrorAction Stop -UseBasicParsing).Headers.'Content-Length' | Select-String -Pattern '\d+' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value }
        Write-Verbose "ofl.cab has size $Size"
        if ($Size -gt 0) {
            Write-Verbose "Size is greater than 0"
            Write-Output $true
        }
        else {
            Write-Warning "Size is not greater than 0"
            Write-Output $false
        }
    }
    catch {
        Write-Warning "Unable to read file size from $Uri"
        Write-Output $false
    }
}

function Get-OfficeConfiguration {
    param (
        [string]$Path = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration',
        [string]$Value
    )
    Write-Log -Message "Getting Office Configuration $Value"
    $RegistryData = (Get-ItemProperty -Path $Path -Name $Value).$Value
    if ($RegistryData) {
        Write-Log -Message "Office Configuration for $Value is $RegistryData"
        Write-Output $RegistryData
    }
    else {
        Write-Log -Message "Unable to find office configuration data for $Value" -Level Warn
    }
}

function Get-TaniumClientDirectory {
    [CmdletBinding()]
    param()

    if (Test-Path -Path 'HKLM:\Software\WOW6432Node\Tanium\Tanium Client') {
        $TaniumClientRegistryPath = 'HKLM:\Software\WOW6432Node\Tanium\Tanium Client'
    }
    elseif (Test-Path -Path 'HKLM:\Software\Tanium\Tanium Client') {
        $TaniumClientRegistryPath = 'HKLM:\Software\Tanium\Tanium Client'
    }
    else {
        Write-Log 'Unable to determine the Tanium client registry path' -Level Warn
    }
    if ($TaniumClientRegistryPath) {
        $TaniumClientDirectory = (Get-ItemProperty -Path $TaniumClientRegistryPath -Name Path).Path
        Write-Output $TaniumClientDirectory
    }
}
function Get-Click2RunFileList {
    param (
        [ValidateSet('Current', 'SemiAnnual', 'SemiAnnualPreview', 'MonthlyEnterprise', 'PerpetualVL2019', 'PerpetualVL2021')]
        $Channel = 'Current',
        $Version,
        $Arch = '64',
        [switch]$AllLanguages
    )
    if ($AllLanguages.IsPresent) {
        $Uri = "https://config.office.com/api/filelist?Channel=$Channel&Version=$Version&Arch=$Arch&AllLanguages=True"
    }
    else {
        $Uri = "https://config.office.com/api/filelist?Channel=$Channel&Version=$Version&Arch=$Arch&AllLanguages=False"
    }
    Invoke-RestMethod -Uri $Uri
}
function Invoke-OfficeDeploymentTool {
    $OdtCommand = '.\setup.exe'
    $OdtArguments = '/configure configuration.xml'
    Write-Log -Message 'Executing setup.exe /configure configuration.xml'
    $OdtProcess = Start-Process -FilePath $OdtCommand -ArgumentList $OdtArguments -Wait -NoNewWindow -PassThru
    if ($OdtProcess.ExitCode -eq 0) {
        Write-Log "Command completed successfully with exit code $($OdtProcess.ExitCode)"
    }
    else {
        Write-Log "Command completed unsuccessfully with exit code $($OdtProcess.ExitCode)" -Level Error
        Write-Log "Review Office Logs at %WINDIR%\TEMP\%COMPUTERNAME%-YYYYMMDD-hhmm.log"
    }
    $Script:ExitCode = $OdtProcess.ExitCode
    Write-Log "Finished operation $Operation of Office $Channel $Arch $Version."
}
function Request-TaniumFile {
    param (
        [string]$Uri,
        [string]$Path = $CurrentWorkingDirectory,
        [string]$FileName
    )
    if (!($FileName)) {
        $FileName = $($Uri.Split('/')[-1])
    }

    Write-Log "Checking $Path for $FileName"
    if (Test-Path -Path "$Path\$FileName") {
        Write-Log "$FileName already exists in $Path. Skipping download."
    }
    else {
        Write-Log "$Filename does not already exist in $Path. Requesting file now."
        Write-Log "Beginning downloading of $Uri"
        New-Download -Uri $Uri -Path $Path -Method $DownloadMethod -DownloadTimeout $DownloadTimeout -FileName $FileName | Tee-Object -FilePath $LogPath -Append
        if (Test-Path -Path "$Path\$FileName") {
            Write-Log "Completed download of $Uri"
        }
        else {
            Write-Log "Download timed out or failed for $Uri."
        }
    }
}
function Test-RequiredFile {
    param (
        [string[]]$Uri
    )
    $AllRequiredFilesPresent = $true
    $IsRequiredFilePresent = $false
    foreach ($File in $Uri) {
        $FileName = $($File.Split('/')[-1])
        Write-Log "Checking $CurrentWorkingDirectory for $FileName"
        if (Test-Path -Path "$CurrentWorkingDirectory\$FileName") {
            Write-Log "$FileName exists in $CurrentWorkingDirectory"
            $IsRequiredFilePresent = $true
        }
        else {
            Write-Log "$Filename does not exist in $CurrentWorkingDirectory"
            $IsRequiredFilePresent = $false
        }
        if ($IsRequiredFilePresent) {
            $IsRequiredFilePresent = $false
        }
        else {
            $AllRequiredFilesPresent = $false
        }
    }
    Write-Output $AllRequiredFilesPresent
}
function Expand-Cab {
    param (
        $Path,
        $Destination
    )
    if (Test-Path -Path $Path) {
        # Found Cab file
        Write-Log "Found cab file $Path"
        # Find expand.exe path
        $ExpandExe = "$env:windir\system32\expand.exe"
        if (Test-Path -Path $ExpandExe) {
            Write-Log "Found Expand.exe. Proceeding with extracting $Path"
            & "$ExpandExe" "$Path" -F:* "$Destination"
        }
        else {
            Write-Log "Unable to find expand.exe" -Level Warn
        }
    }
    else {
        Write-Log "Unable to find $Path" -Level Warn
    }
}
function Get-Click2RunChannelUrl {
    param (
        [string]$Path,
        [string]$Channel
    )
    [xml]$XmlObject = Get-Content -Path $Path
    if ($Channel) {
        $ChannelUrl = $XmlObject.UpdateFiles.BaseUrl | Where-Object -FilterScript { $_.branch -eq $Channel }
    }
    else {
        $ChannelUrl = $XmlObject.UpdateFiles.BaseUrl
    }
    $ChannelUrl
}
function Get-Click2RunLanguageFile {
    param (
        [string]$Path,
        [string]$LanguageId
    )
    [xml]$XmlObject = Get-Content -Path $Path
    $LanguageFile = $XmlObject.UpdateFiles.File | Where-Object -FilterScript { $_.language -eq $LanguageId }
    $LanguageFile
}
function Get-MissingRequiredFiles {
    Write-Log "Checking for required files"
    $MissingRequiredFiles = @()
    foreach ($File in $RequiredFiles) {
        if ($null -ne $File.rename) {
            $RelativePath = ($CurrentWorkingDirectory + $File.relativePath + $File.rename).replace('%version%', $Version)
            $PackageFilePath = $CurrentWorkingDirectory + '\' + $File.rename
        }
        else {
            $RelativePath = ($CurrentWorkingDirectory + $File.relativePath + $File.name).replace('%version%', $Version)
            $PackageFilePath = $CurrentWorkingDirectory + '\' + $File.name
        }
        if (Test-Path -Path $PackageFilePath) {
            Write-Log "Found $PackageFilePath. Moving to $RelativePath"
            Move-Item -Path $PackageFilePath -Destination $RelativePath
        }
        if (Test-Path -Path $RelativePath) {
            Write-Log "Found existing $RelativePath"
        }
        else {
            Write-Log "Missing $RelativePath"
            $MissingRequiredFiles += $File
        }
    }
    $MissingRequiredFiles
}
function Get-InstallationFiles {

    # Prequisite Files
    $FileList = $Channel + '_' + $Arch + '_' + $Version + '.json'
    Write-Log $FileList
    $PrerequisiteFiles = @(
        $FileList
    )

    # Validate that all prerequisite files are present
    foreach ($File in $PrerequisiteFiles) {
        if (Test-Path -Path "$CurrentWorkingDirectory\$File" ) {
            Write-Log "Found prerequisite file $File"
        }
        else {
            Write-Warning "Prerequisite file $File is missing"
            $Script:ExitCode = 1
            return
        }
    }

    # Load filelist.json
    $FileListJson = Get-Content -Path "$CurrentWorkingDirectory\$FileList" | ConvertFrom-Json

    # Parse file list for required information
    # Get Channel base URL
    Write-Log "Getting Channel Url from filelist.json"
    $ChannelUrl = $FileListJson.baseUrl

    if ($ChannelUrl) {
        Write-Log "Channel Url for $Channel is $ChannelUrl"
    }
    else {
        Write-Log "Unable to determine channel url. Exiting." -Level Warn
        $Script:ExitCode = 1
        return
    }

    # Get required language neutral files
    Write-Log "Building list of language neutral files for $Arch bit"
    $LanguageNeutralFiles = $FileListJson.files | Where-Object -FilterScript { $_.LCID -eq 0 }

    # Get required language specific files
    # Need a function to determine language code (or make it a parameter maybe)
    <# Install Operation
        - If a configuration.xml exists, parse it for language packs
        - else get the current OS language
            - If the current OS language isn't an option for Office, default to english
            - otherwise set the language to the current OS
       Update Operation
       - Gather installed language packs and add those to the required files list
    #>
    # save this line for future MatchOS support
    #$OsCulture = Get-Culture

    Write-Log "Building list of language specific files for $Arch bit"

    $Languages = $OfficeConfigurationXml.Configuration.Add.Product.Language.Id | Select-Object -Unique
    $LanguageSpecificFiles = @()
    foreach ($Language in $Languages) {
        $CultureInfo = [System.Globalization.CultureInfo]::GetCultureInfo($Language)
        Write-Log "Adding Language $($CultureInfo.DisplayName) $($CultureInfo.Name) with LCID $($CultureInfo.LCID)"
        $LanguageSpecificFiles += $FileListJson.files | Where-Object -FilterScript { $_.LCID -eq $CultureInfo.LCID }
    }

    $RequiredFiles = @()
    $RequiredFiles += $LanguageNeutralFiles
    $RequiredFiles += $LanguageSpecificFiles

    # Build/verify local folder structure (i.e. Office\data\version)
    $ClickToRunFolderStructure = "$CurrentWorkingDirectory\office\data\$Version"
    Write-Log "Checking local office folder structure: $ClickToRunFolderStructure"
    if (!(Test-Path -Path $ClickToRunFolderStructure)) {
        Write-Log "Office folder structure not present, creating now."
        New-Item -Name "office\data\$Version" -ItemType Directory -Force | Out-Null
    }
    else {
        Write-Log "Local office folder structure exists"
    }

    # Check to see if if we are missing any required files and download if missing
    $DownloadAttempts = 0

    do {
        $MissingRequiredFiles = Get-MissingRequiredFiles
        if ($MissingRequiredFiles) {
            if ($DownloadAttempts -le $MaxDownloadAttempts) {
                # Download Required Files
                # Build Url for each of the files
                $DownloadAttempts++
                Write-Log "Downloading missing required files attempt $DownloadAttempts"
                foreach ($File in $MissingRequiredFiles) {
                    if ($null -ne $File.rename) {
                        [string]$Uri = ($ChannelUrl + $File.relativePath + $File.rename).replace('%version%', $Version)
                    }
                    else {
                        [string]$Uri = ($ChannelUrl + $File.relativePath + $File.name).replace('%version%', $Version)
                    }
                    Write-Log "Downloading $Uri via tanium"
                    $DownloadPath = ($CurrentWorkingDirectory + $File.relativePath).replace('%version%', $Version)
                    Request-TaniumFile -Uri $Uri -Path $DownloadPath
                }
            }
        }
        else {
            Write-Log "No missing files, proceeding."
        }
    } until ($MissingRequiredFiles.Count -eq 0 -or $DownloadAttempts -ge $MaxDownloadAttempts)

    if ($MissingRequiredFiles.Count -eq 0) {
        Write-Log "All required files present."
        Write-Output $true
    }
    elseif ($DownloadAttempts -ge $MaxDownloadAttempts ) {
        Write-Log "Maximum download attempts reached."
        Write-Output $false
    }
    else {
        # Nothing here yet
    }
}
# End Helper Functions

# Log to \Tanium Client\Tools\SoftwareManagement\logs\Install-ClicktoRunOffice.log if path exists
$TaniumClientDirectory = Get-TaniumClientDirectory
if (Test-Path -Path $TaniumClientDirectory) {
    $DeployOfficeLogPath = "$TaniumClientDirectory\Tools\SoftwareManagement\logs"
    if (Test-Path -Path $DeployOfficeLogPath) {
        $LogPath = "$DeployOfficeLogPath\Install-ClicktoRunOffice.log"
    }
}

# Set default Path parameter for Write-Log
if ($null -eq $PSDefaultParameterValues['Write-Log:Path']) {
    $PSDefaultParameterValues.Add('Write-Log:Path', $LogPath)
}
else {
    $PSDefaultParameterValues['Write-Log:Path'] = $LogPath
}

##### Begin Main Script #####
Write-Log -Message '############################################'
Write-Log -Message 'Beginning ClicktoRun Office Script'
Write-Log -Message "Operation: $Operation"
Write-Log -Message "Channel: $Channel"
Write-Log -Message "Arch: $Arch"
Write-Log -Message "Version: $Version"
Write-Log -Message "LogPath: $LogPath"

$CurrentWorkingDirectory = $PSScriptRoot
$ExitCode = 0

# Determine download method
# web - use the ODT to download directly
# tanium - use the Tanium client to download required setup files
# if not peering AND can reach Office CDN the use web, otherwise use tanium
if ($DownloadMethod -eq 'auto') {
    Write-Log "Download method: $DownloadMethod. Evaluating now."
    $IsTaniumClientPeering = Test-TaniumClientPeering
    if ($IsTaniumClientPeering) {
        Write-Log 'Tanium client is peering. Continuing with Tanium download method.'
        $DownloadMethod = 'tanium'
    }
    else {
        Write-Log 'Tanium client is not peering. Verifying connectivity to Office CDN.'
        if (Test-OfficeCdnConnectivity) {
            Write-Log 'Verified connectivty to Office CDN. Continuing with direct download.'
            $DownloadMethod = 'web'
        }
        else {
            Write-Log 'Unable to verify connectivity to Office CDN. Defaulting to Tanium download method'
            $DownloadMethod = 'tanium'
        }
    }
}
elseif ($DownloadMethod -eq 'web') {
    Write-Log "Download method: $DownloadMethod. Verifying connectivity to Office CDN."
    if (Test-OfficeCdnConnectivity) {
        Write-Log 'Verified connectivty to Office CDN. Continuing with direct download.'
        $DownloadMethod = 'web'
    }
    else {
        Write-Log 'Unable to verify connectivity to Office CDN. Defaulting to Tanium download method'
        $DownloadMethod = 'tanium'
    }
}
else {
    # Continue with tanium client download method
    Write-Log "Download method: $DownloadMethod. Continuing."
}


# Verify ODT setup.exe is present in current directory, if not abort.
if (Test-Path -Path '.\setup.exe') {
    Write-Log -Message 'Found setup.exe in current working directory. Proceeding'
}
else {
    Write-Log -Message 'Unable to find setup.exe in current working directory. Exiting' -Level Error
    $ExitCode = 1
    Write-Log "End $Operation Office $Channel $Arch $Version"
    Write-Log -Message '############################################'
    Exit $ExitCode
}

# Proceed by selected Operation (i.e. Install, Update, Remove)
switch ($Operation) {
    'Install' {
        Write-Log 'Install Operation'
        # Check for an existing or supplied configuration.xml in the current working directory
        Write-Log -Message 'Checking for existing configuration.xml'
        if (Test-Path -Path '.\configuration.xml') {
            Write-Log -Message "Found existing configuration.xml."
            Write-Log -Message 'Modifying configuration.xml'
            [xml]$OfficeConfigurationXml = Get-Content -Path '.\configuration.xml'
            $OfficeConfigurationXml.Configuration.Add.SetAttribute('Channel', $Channel)
            $OfficeConfigurationXml.Configuration.Add.SetAttribute('Version', $Version)
            $OfficeConfigurationXml.Configuration.Add.SetAttribute('OfficeClientEdition', $Arch)
            $OfficeConfigurationXml.Configuration.Add.SetAttribute('ForceUpgrade', 'TRUE')
            
            # Set local path for ODT to install from source files downloaded through Tanium Client API
            if ($DownloadMethod -eq 'tanium') {
                $OfficeConfigurationXml.Configuration.Add.SetAttribute('AllowCDNFallback', 'FALSE')
                $OfficeConfigurationXml.Configuration.Add.SetAttribute('SourcePath', $CurrentWorkingDirectory)
            }
            # Ensure that SourcePath and AllowCDNFallback attributes are not present in existing configuration.xml
            if ($DownloadMethod -eq 'web') {
                $OfficeConfigurationXml.Configuration.Add.RemoveAttribute('AllowCDNFallback')
                $OfficeConfigurationXml.Configuration.Add.RemoveAttribute('SourcePath')
            }

            # Output Office Configuration file as xml
            Write-Log -Message 'Writing out configuration.xml'
            Set-Content -Path '.\configuration.xml' -Value $OfficeConfigurationXml.Configuration.OuterXml | Out-Null
        }
        # If no configuration.xml file is found in current working directory, then generate a safe default.
        else {
            Write-Log -Message "No existing configuration.xml found. Generating a default configuration.xml"
            # Build Office Configuration
            $OfficeConfiguration = @"
<Configuration>
    <Add Version="16.0.13901.20400" Channel="Current" OfficeClientEdition="64" ForceUpgrade="TRUE">
        <Product ID="O365ProPlusRetail">
            <Language ID="en-us" />
            <ExcludeApp ID="groove" />
        </Product>
    </Add>
    <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

            Write-Log -Message 'Modifying configuration.xml'
            [xml]$OfficeConfigurationXml = $OfficeConfiguration
            $OfficeConfigurationXml.Configuration.Add.Channel = $Channel
            $OfficeConfigurationXml.Configuration.Add.Version = $Version
            $OfficeConfigurationXml.Configuration.Add.OfficeClientEdition = $Arch
            $OfficeConfigurationXml.Configuration.Add.ForceUpgrade = 'TRUE'

            if ($DownloadMethod -eq 'tanium') {
                $OfficeConfigurationXml.Configuration.Add.SetAttribute('AllowCDNFallback', 'FALSE')
                $OfficeConfigurationXml.Configuration.Add.SetAttribute('SourcePath', $CurrentWorkingDirectory)
            }

            switch ($Channel) {
                'PerpetualVL2019' {
                    $ProductID = 'ProPlus2019Volume'
                }
                'PerpetualVL2021' {
                    $ProductID = 'ProPlus2021Volume'
                }
                default {
                    $ProductID = 'O365ProPlusRetail'
                }
            }
            $OfficeConfigurationXml.Configuration.Add.Product.ID = $ProductID

            # Force Apps Close
            if ($ForceCloseApps.IsPresent) {
                Write-Log -Message 'ForceCloseApps switch present. Adding FORCEAPPSHUTDOWN element to configuration'
                $AddConfigurationElement = $OfficeConfigurationXml.Configuration.AppendChild($OfficeConfigurationXml.CreateElement("Property"))
                $AddConfigurationElement.SetAttribute('Name', 'FORCEAPPSHUTDOWN')
                $AddConfigurationElement.SetAttribute('Value', 'TRUE')
            }
            # End Office Configuration

            # Output Office Configuration file as xml
            Write-Log -Message 'Writing out configuration.xml'
            Set-Content -Path '.\configuration.xml' -Value $OfficeConfigurationXml.Configuration.OuterXml | Out-Null
        }
        Write-Log "Beginning $Operation of Office"
        if (Test-Path -Path '.\configuration.xml') {
            Write-Log -Message 'Found configuration.xml, continuing.'
            if ($DownloadMethod -eq 'tanium') {
                $InstallationFilesPresent = Get-InstallationFiles
                if ($InstallationFilesPresent) {
                    if ($DownloadOnly.IsPresent) {
                        Write-Log 'All installation files verified. DownloadOnly switch present. Skipping installation.'
                    }
                    else {
                        Write-Log 'All installation files verified. Proceeding with installation.'
                        Invoke-OfficeDeploymentTool
                    }
                }
                else {
                    Write-Log -Level Warn 'Installation files not available. Not proceeding with installation.'
                    $ExitCode = 1
                }
            }
            else {
                Invoke-OfficeDeploymentTool
            }
        }
        else {
            Write-Log -Message 'Unable to find configuration.xml' -Level Error
            $ExitCode = 1
        }
    }
    'Update' {
        Write-Log 'Update Operation'
        # Requires gathering information as to what is currently installed
        # Product IDs, Language Packs, ExcludeApps, Proof Packs
        $OfficeRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
        Write-Log -Message 'Verifying Office ClickToRun registry exists'
        # Verify Office ClickToRun is already installed by checking registry path
        if (Test-Path -Path $OfficeRegistryPath) {
            Write-Log -Message 'Found Office ClickToRun registry location'
            # Get ProductReleaseIds
            Write-Log -Message 'Gathering installed ProductReleaseIDs'
            $ProductReleaseIds = 'O365ProPlusRetail'
            $VersionToReport = Get-OfficeConfiguration -Path $OfficeRegistryPath -Value 'VersionToReport'
            [string]$Platform = Get-OfficeConfiguration -Path $OfficeRegistryPath -Value 'Platform'
            $ClientCulture = Get-OfficeConfiguration -Path $OfficeRegistryPath -Value 'ClientCulture'
            $CDNBaseUrl = Get-OfficeConfiguration -Path $OfficeRegistryPath -Value 'CDNBaseUrl'

            # Ensure that we are updating whatever platform/arch is already installed
            switch ($Platform) {
                'x86' {
                    $Arch = '32'
                }
                'x64' {
                    $Arch = '64'
                }
            }

            # Gathering Excluded apps per product installed
            Write-Log -Message 'Gathering existing Excluded Apps'
            $ExcludedApps = @()
            foreach ($ProductReleaseId in $ProductReleaseIds) {
                $ProductReleaseIdExcludedApps = (Get-OfficeConfiguration -Path "$OfficeRegistryPath" -Value "$ProductReleaseId.ExcludedApps").split(',')
                $ExcludedAppsProperties = @{
                    'ProductReleaseId' = $ProductReleaseId
                    'ExcludedApps'     = $ProductReleaseIdExcludedApps
                }
                $ExcludedApp = New-Object -TypeName pscustomobject -Property $ExcludedAppsProperties
                $ExcludedApps += $ExcludedApp
            }

            $ActiveConfiguration = Get-OfficeConfiguration -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs\" -Value 'ActiveConfiguration'
            $InstalledCultures = (Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\ProductReleaseIDs\$ActiveConfiguration\culture").PSChildName

            # Process Installed Cultures to determine language packs and proof packs
            Write-Log -Message 'Process Installed Cultures to determine language packs and proof packs'
            $LanguagePacks = @()
            $ProofPacks = @()
            foreach ($InstalledCulture in $InstalledCultures) {
                Write-Log "Installed Culture: $InstalledCulture"
                if ($InstalledCulture -notmatch 'x-none') {
                    if ($InstalledCulture -match 'proof') {
                        $ProofPacks += ($InstalledCulture).split('.')[0]
                    }
                    else {
                        $LanguagePacks += ($InstalledCulture).split('.')[0]
                    }
                }
            }
            Write-Log "Proof packs: $ProofPacks"
            Write-Log "Language Packs: $LanguagePacks"

            # Starter XML Configuration for Update operation
            $OfficeConfiguration = @"
<Configuration>
    <Add Version="16.0.13901.20400" Channel="SemiAnnual" OfficeClientEdition="64" ForceUpgrade="TRUE">
    </Add>
    <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@
            Write-Log -Message 'Generating upgrade configuration.xml'
            [xml]$OfficeConfigurationXml = $OfficeConfiguration
            $OfficeConfigurationXml.Configuration.Add.Channel = $Channel
            $OfficeConfigurationXml.Configuration.Add.Version = $Version
            $OfficeConfigurationXml.Configuration.Add.OfficeClientEdition = $Platform
            $OfficeConfigurationXml.Configuration.Add.ForceUpgrade = 'TRUE'

            if ($DownloadMethod -eq 'tanium') {
                $OfficeConfigurationXml.Configuration.Add.SetAttribute('AllowCDNFallback', 'FALSE')
                $OfficeConfigurationXml.Configuration.Add.SetAttribute('SourcePath', $CurrentWorkingDirectory)
            }

            # Adding Product IDs
            foreach ($ProductReleaseId in $ProductReleaseIds) {
                Write-Log -Message "Adding Product ID $ProductReleaseId to configuration"
                $AddProductElement = $OfficeConfigurationXml.Configuration.Add.AppendChild($OfficeConfigurationXml.CreateElement("Product"))
                $AddProductElement.SetAttribute('ID', $ProductReleaseId)
                foreach ($LanguagePack in $LanguagePacks) {
                    # Process any Language packs for the current ProductReleaseID
                    Write-Log -Message "Adding Language Pack $LanguagePack for the $ProductReleaseId"
                    $AddProductLanguagePackElement = $AddProductElement.AppendChild($OfficeConfigurationXml.CreateElement("Language"))
                    $AddProductLanguagePackElement.SetAttribute('ID', $LanguagePack)
                }
                $ProductReleaseIdExcludedApps = $ExcludedApps | Where-Object -FilterScript { $_.ProductReleaseId -eq $ProductReleaseId }
                foreach ($ExcludedApp in $ProductReleaseIdExcludedApps.ExcludedApps) {
                    # Process any excluded apps for the current ProductReleaseID
                    Write-Log -Message "Adding excluded app $ExcludedApp for the $ProductReleaseId"
                    $AddProductExcludeAppElement = $AddProductElement.AppendChild($OfficeConfigurationXml.CreateElement("ExcludeApp"))
                    $AddProductExcludeAppElement.SetAttribute('ID', $ExcludedApp)
                }
            }
            foreach ($ProofPack in $ProofPacks) {
                Write-Log -Message "Adding Proofing Tools for $ProofPack to configuration"
                $AddProductElement = $OfficeConfigurationXml.Configuration.Add.AppendChild($OfficeConfigurationXml.CreateElement("Product"))
                $AddProductElement.SetAttribute('ID', 'ProofingTools')
                $AddProductProofPackElement = $AddProductElement.AppendChild($OfficeConfigurationXml.CreateElement("Language"))
                $AddProductProofPackElement.SetAttribute('ID', $Proofpack)
            }
            # Force Apps Close
            if ($ForceCloseApps.IsPresent) {
                Write-Log -Message 'ForceCloseApps switch present. Adding FORCEAPPSHUTDOWN element to configuration'
                $AddConfigurationElement = $OfficeConfigurationXml.Configuration.AppendChild($OfficeConfigurationXml.CreateElement("Property"))
                $AddConfigurationElement.SetAttribute('Name', 'FORCEAPPSHUTDOWN')
                $AddConfigurationElement.SetAttribute('Value', 'TRUE')
            }
            # End Office Configuration

            # Output Office Configuration file as xml
            Write-Log -Message 'Writing out configuration.xml'
            Set-Content -Path '.\configuration.xml' -Value $OfficeConfigurationXml.Configuration.OuterXml | Out-Null
            if (Test-Path -Path '.\configuration.xml') {
                Write-Log -Message 'Found configuration.xml, continuing.'
                if ($DownloadMethod -eq 'tanium') {
                    $InstallationFilesPresent = Get-InstallationFiles
                    if ($InstallationFilesPresent) {
                        if ($DownloadOnly.IsPresent) {
                            Write-Log 'All installation files verified. DownloadOnly switch present. Skipping installation.'
                        }
                        else {
                            Write-Log 'All installation files verified. Proceeding with installation.'
                            Invoke-OfficeDeploymentTool
                        }
                    }
                    else {
                        Write-Log -Level Warn 'Installation files not available. Not proceeding with installation.'
                        $ExitCode = 1
                    }
                }
                else {
                    Invoke-OfficeDeploymentTool
                }
            }
            else {
                Write-Log -Message 'Unable to find configuration.xml' -Level Error
                $ExitCode = 1
            }
        }
        # Unable to find an existing Office ClickToRun registry
        else {
            Write-Log -Message 'Unable to find Office registry location' -Level Error
            $ExitCode = 1
        }
    }
    'Remove' {
        Write-Log 'Remove Operation'
        # Generate configuration.xml to remove ALL Office ClickToRun Products
        Write-Log 'Generate configuration.xml to remove ALL Office ClickToRun Products'
        $OfficeConfiguration = @"
<Configuration>
    <Remove All="TRUE" />
    <Display Level="None" AcceptEULA="TRUE" />
    <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
</Configuration>
"@
        # Output Office Configuration file as xml
        Write-Log -Message 'Writing out configuration.xml'
        Set-Content -Path 'configuration.xml' -Value $OfficeConfiguration | Out-Null
        Write-Log "Begin $Operation Office"
        Invoke-OfficeDeploymentTool
    }
}
# Final Steps
Write-Log "End $Operation Office $Channel $Arch $Version"
Write-Log -Message '############################################'
Exit $ExitCode
