function Update-TaniumClientPatchCabFile {
    [CmdletBinding()]
    param(
        [string]$Uri = 'http://download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab',
        [ValidateSet('web', 'bits', 'tanium')]
        [string]$Method = 'web',
        [int]$DownloadTimeout = 900
    )
    $TaniumClientDirectory = Get-TaniumClientDirectory
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $CabFilePath = "$TaniumClientPatchDirectory\scans\"
    New-Download -Uri $Uri -Path $CabFilePath -Method $Method -DownloadTimeout $DownloadTimeout
}