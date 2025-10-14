function Start-TaniumClient {
    [cmdletbinding()]
    param()
    $ServiceName = 'Tanium Client'
    $Service = Get-Service -Name $ServiceName
    if ($Service.Status -eq 'Stopped') {
        Write-Verbose "$ServiceName is stopped. Attempting to start."
        $Service | Start-Service
        $Service = Get-Service -Name $ServiceName
        $Service
    }
    else {
        Write-Verbose "$ServiceName is not stopped."
    }
}