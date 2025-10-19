function New-TaniumDeployMetadata {
    <#
    .SYNOPSIS
        Generates Tanium Deploy JSON metadata for Windows updates.

    .DESCRIPTION
        Creates metadata JSON for Tanium Deploy packages including install/remove operations,
        disk space requirements, and verification queries. Can generate metadata with or without
        downloaded files.

    .PARAMETER Update
        Update object from Get-MSCatalogUpdate containing title, size, classification, etc.

    .PARAMETER KB
        KB number (e.g., 'KB5066835' or '5066835')

    .PARAMETER InstallScript
        Name of the install wrapper script

    .PARAMETER RemoveScript
        Name of the remove wrapper script

    .PARAMETER UpdateFileName
        Name of the update file (e.g., 'windows11.0-kb5066835-x64.msu')

    .PARAMETER UpdateFilePath
        Path to the downloaded update file. Optional - if not provided, SHA256 will be null.

    .PARAMETER DownloadUrl
        Download URL for the update file

    .EXAMPLE
        # Generate metadata with downloaded file (includes SHA256)
        $metadata = New-TaniumDeployMetadata -Update $update -KB "KB5066835" `
            -InstallScript "Install-KB5066835.ps1" -RemoveScript "Remove-KB5066835.ps1" `
            -UpdateFileName "update.msu" -UpdateFilePath "C:\Temp\update.msu" `
            -DownloadUrl "https://..."

    .EXAMPLE
        # Generate metadata without file (SHA256 will be null)
        $metadata = New-TaniumDeployMetadata -Update $update -KB "KB5066835" `
            -InstallScript "Install-KB5066835.ps1" -RemoveScript "Remove-KB5066835.ps1" `
            -UpdateFileName "update.msu" -DownloadUrl "https://..."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$KB,

        [Parameter(Mandatory)]
        [string]$InstallScript,

        [Parameter(Mandatory)]
        [string]$RemoveScript,

        [Parameter(Mandatory)]
        [string]$UpdateFileName,

        [Parameter()]
        [string]$UpdateFilePath,

        [Parameter(Mandatory)]
        [string]$DownloadUrl
    )

    $KBNumber = $KB -replace 'KB', ''

    # Calculate SHA-256 hash of the downloaded file if path is provided
    $sha256Hash = $null
    if ($UpdateFilePath -and (Test-Path $UpdateFilePath)) {
        Write-Verbose "Calculating SHA-256 hash for $UpdateFileName..."
        $sha256Hash = (Get-FileHash -Path $UpdateFilePath -Algorithm SHA256).Hash
        Write-Verbose "SHA-256: $sha256Hash"
    } elseif ($UpdateFilePath) {
        Write-Warning "File not found: $UpdateFilePath - SHA256 will be null"
    } else {
        Write-Verbose "No file path provided - SHA256 will be null"
    }

    # Parse OS and architecture from title using helper functions
    $osShort = Get-CompactOSName -String $Update.Title
    $arch = Get-ArchitectureFromString -String $Update.Title

    # Create compact self-service name (≤25 chars): "KB5066835 Win11 x64"
    $selfServiceName = "$KB $osShort $arch"

    # Microsoft Support KB URL
    $supportUrl = "https://support.microsoft.com/kb/$KBNumber"

    # Parse size and estimate disk space using helper function
    $sizeMB = Get-SizeInMB -SizeString $Update.Size
    # Estimate disk space (3x the download size for extraction and installation)
    $diskSpaceMB = [math]::Max($sizeMB * 3, 100)

    $metadata = @{
        vendor               = "Microsoft"
        productName          = $Update.Title -replace "\($KB\)", '' -replace $KB, '' | ForEach-Object { $_.Trim() }
        productVersion       = $KB
        architecture         = $arch
        diskSpaceMB          = $diskSpaceMB
        memoryMB             = 512
        downloadUrl          = $DownloadUrl
        sha256               = $sha256Hash
        additionalDetails    = $supportUrl
        installOperation     = @{
            command      = "powershell.exe -ExecutionPolicy Bypass -File `".\$InstallScript`""
            timeout      = 3600
            successCodes = @(0, 3010)
        }
        removeOperation      = @{
            command      = "powershell.exe -ExecutionPolicy Bypass -File `".\$RemoveScript`""
            timeout      = 1800
            successCodes = @(0, 3010)
        }
        osRequirements       = @{
            editionId   = $null
            productName = $null
            build       = $null
        }
        selfService          = @{
            name = $selfServiceName
            icon = $null
        }
        installRequirements  = 'Registry Path exists "HKLM\Path\Does\Not\Exist"'
        installVerification  = "SELECT HotFixID FROM Win32_QuickFixEngineering WHERE HotFixID=`"KB$KBNumber`""
        updateDetection      = $null
    }

    return $metadata
}
