Try {
    $InstallDate = (Get-CimInstance -Namespace root/CIMV2 -ClassName  Win32_OperatingSystem).InstallDate
    Get-Date $InstallDate -Format "ddd, dd MMM yyyy" # zzz"

}
Catch {
    Write-Error "Could not determine the setup date."
}