function Start-TaniumClientDeploySelfServiceClient {
    [cmdletbinding()]
    param(
        $TaniumClientEndUserDirectory = "${env:ProgramFiles(x86)}\Tanium\Tanium End User Notification Tools",
        $TaniumClientEndUserExe = "$TaniumClientEndUserDirectory\bin\end-user-notifications.exe",
        $TaniumClientSelfServicePlugin = "plugins\end-user-self-service-plugin.asar"
    )
    begin {}
    process {
        if (Test-Path -Path $TaniumClientEndUserDirectory) {
            if (Test-Path -Path $TaniumClientEndUserExe) {
                if (Test-Path -Path "$TaniumClientEndUserDirectory\$TaniumClientSelfServicePlugin") {
                    Start-Process -FilePath $TaniumClientEndUserExe -WorkingDirectory $TaniumClientEndUserDirectory -ArgumentList "plugin",$TaniumClientSelfServicePlugin -RedirectStandardOutput NUL
                }
                else {
                    Write-Warning "Unable to find $TaniumClientEndUserDirectory\$TaniumClientSelfServicePlugin"
                }
            }
            else {
                Write-Warning "Unable to find $TaniumClientEndUserExe"
            }
        }
        else {
            Write-Warning "Unable to find $TaniumClientEndUserDirectory"
        }
    }
    end {}
}