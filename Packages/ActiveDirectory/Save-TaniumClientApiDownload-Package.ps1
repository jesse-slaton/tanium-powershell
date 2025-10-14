function Save-TaniumClientApiDownload {
    [cmdletbinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]$Uri,
        [parameter(Mandatory = $true)]
        [string]$Path,
        [string]$FileName,
        [int]$DownloadTimeout = 900,
        [int]$SleepIntervalInSeconds = 60
    )

    New-Download -Uri $Uri -Path $Path -FileName $FileName -DownloadTimeout $DownloadTimeout -SleepIntervalInSeconds $SleepIntervalInSeconds -Method tanium
}