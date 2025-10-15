#Requires -RunAsAdministrator
$parameters = @{
    Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    Name  = 'DisableCompression'
    Type  = 'DWORD'
    Value = 0
    Force = $true
}
Set-ItemProperty @parameters