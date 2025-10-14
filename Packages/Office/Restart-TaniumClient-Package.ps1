function Restart-TaniumClient {
    param()
    Stop-TaniumClient
    Start-TaniumClient
}