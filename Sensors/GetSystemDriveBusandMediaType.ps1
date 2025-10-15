Try {
    $SystemDrive = Get-Volume -DriveLetter $($ENV:SystemDrive).Replace(':', '') | Get-Partition | Get-Disk
    $MediaType = (Get-PhysicalDisk | Where-Object { $_.SerialNumber -eq $SystemDrive.SerialNumber }).MediaType
    Write-Output "$($SystemDrive.BusType)|$MediaType"
}
Catch {
    Write-Error "Could not identify system drive type."
}