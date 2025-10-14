function Get-TaniumClientListenPort {
    [cmdletbinding()]
    param ( )
    [int]$TaniumClientListenPort = (Get-TaniumClientSetting -Setting Status.ClientAddress).Value.split(':')[1]
    $TaniumClientListenPort
}