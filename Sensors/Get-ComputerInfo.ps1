$ComputerSystem = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem -ErrorAction Stop
    switch ($ComputerSystem.Manufacturer) {
        default { $BestModel = $system.Model }
        'Lenovo' {
            if ($system.SystemFamily -match 'filled by') {
                $BestModel = $system.Model
            } else {
                $BestModel = $system.SystemFamily
            }
        }
}
Write-Host $BestModel