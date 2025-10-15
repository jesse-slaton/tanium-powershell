$Path = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"
$reg = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Registry64')
$regkey = $reg.OpenSubKey($Path)

Try {
    $regdata = $regkey.GetValue("DisplayVersion") 
}
Catch {
    $regdata = $regkey.GetValue("ReleaseId")
}
Finally {
    If ($regdata) { Write-Output $regdata }
    Else { Write-Warning 'Unknown release' }
}