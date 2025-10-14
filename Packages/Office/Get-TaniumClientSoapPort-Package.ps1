function Get-TaniumClientSoapPort {
    [cmdletbinding()]
    param ( )
    $TaniumClientSoapPort = (Get-TaniumClientListenPort) + 1
    $TaniumClientSoapPort
}