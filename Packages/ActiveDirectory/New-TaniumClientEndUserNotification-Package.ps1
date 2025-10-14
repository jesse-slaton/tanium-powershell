function New-TaniumClientEndUserNotification {
    [cmdletbinding()]
    param (
        [string]$Title = 'Notification Title',
        [string]$Body = 'Notification Body',
        [ValidateSet('notice', 'restart', 'install')]
        [string]$Type = 'notice',
        [ValidateSet('modal', 'toast')]
        [string]$UI = 'modal',
        [string]$NotificationId = [guid]::NewGuid().guid,
        [string]$NotificationXmlFile = "$env:TEMP\notification-$NotificationId.xml",
        [ValidatePattern('\d+$')]
        [string]$PostponeDurationInMinutes = '300',
        [switch]$AllowPostponement,
        [ValidatePattern('\d+$')]
        [string]$CountdownToDeadlineInMinutes = '10',
        [ValidatePattern('\d+$')]
        [string]$UserPostponementPeriodInMinutesOne = '60',
        [ValidatePattern('\d+$')]
        [string]$UserPostponementPeriodInMinutesTwo = '120',
        [ValidatePattern('\d+$')]
        [string]$UserPostponementPeriodInMinutesThree = '240',
        [ValidatePattern('\d+$')]
        [string]$GentleNotificationDurationInMinutes = '0.75'
    )
    # beginning of helper functions

    function Get-TaniumClientEndUserNotificationProcessPid {
        param (
            $NotificationXmlFile
        )
        try {
            $Query = "SELECT ProcessId FROM win32_process WHERE CommandLine LIKE ""%end-user-notifications.exe% --xml-path %$NotificationId%"""
            Write-Verbose "Looking for PID for EUN with NotificationId $NotificationId"
            if (Test-Command -Name 'Get-CimInstance') {
                Get-CimInstance -Query $Query | Select-Object -ExpandProperty ProcessId
            }
            elseif (Test-Command -Name 'Get-WmiObject') {
                Get-WmiObject -Query $Query | Select-Object -ExpandProperty ProcessId
            }
            else {
                Write-Warning 'Unable to find Get-CimInstance or Get-WmiObject command.'
            }
        }
        catch {
            Write-Warning 'Unable to find PID for end-user-notifications.exe'
        }
    }
    function Get-Notification {
        param (
            $NotificationXmlFile
        )
        if (Test-Path -Path $NotificationXmlFile) {
            Write-Verbose "Found $NotificationXmlFile"
            [xml]$NotificationXml = Get-Content -Path $NotificationXmlFile
            $Notification = $NotificationXml.Notification
            $Notification
        }
        else {
            Write-Verbose "Unable to find $NotificationXmlFile"
        }
    }
    # end of helper functions

    # begin main
    if (Test-InteractiveLogonUser) {
        Write-Verbose 'Found interactive logon user explorer process(es). Continuing.'
        $NotficationXmlString = @"
<Notification id="999">
    <allowPostpone>false</allowPostpone>
    <postponeDurationInMinutes>1440</postponeDurationInMinutes>
    <countdownToDeadlineInMinutes>10</countdownToDeadlineInMinutes>
    <gentleNotificationDurationInMinutes>0.5</gentleNotificationDurationInMinutes>
    <userPostponementPeriodInMinutesOne>60</userPostponementPeriodInMinutesOne>
    <userPostponementPeriodInMinutesTwo>120</userPostponementPeriodInMinutesTwo>
    <userPostponementPeriodInMinutesThree>240</userPostponementPeriodInMinutesThree>
    <title>Restart Required</title>
    <icon></icon>
    <body>A restart is required to finish applying updates.</body>
    <bodyImage></bodyImage>
    <type>notice</type>
    <deadline>2021-09-12 20:09:25Z</deadline>
</Notification>
"@


        $ClientUIPath = 'C:\Program Files (x86)\Tanium\Tanium End User Notification Tools'
        $ClientUIExe = 'bin\end-user-notifications.exe'
        $ClientUIStatusFile = 'notification-statuses.xml'
        $UserSessionProxyExe = 'UserSessionProxy.exe'
        $TaniumClientDirectory = Get-TaniumClientDirectory

        if (Test-Path $ClientUIPath\$ClientUIExe) {
            Write-Verbose "Found EUN binary $ClientUIPath\$ClientUiExe"
            $Notification = Get-Notification -NotificationXmlFile $NotificationXmlFile
            if ($Notification.id -eq $NotificationId) {
                Write-Verbose "Notification ID $NotificationId file already exists. Using existing file."
            }
            else {
                Write-Verbose "Notification ID $NotificationId does not exist. Creating notification file."
                [xml]$NotificationXml = $NotficationXmlString
                $NotificationXml.Notification.title = $Title
                $NotificationXml.Notification.id = $NotificationId
                $NotificationXml.Notification.Body = $Body
                $NotificationXml.Notification.type = $Type
                if ($UI -eq 'toast') {
                    $NotificationXml.Notification.gentleNotificationDurationInMinutes = $GentleNotificationDurationInMinutes
                }
                if ($AllowPostponement.IsPresent) {
                    $NotificationXml.Notification.allowPostpone = 'true'
                    $NotificationXml.Notification.postponeDurationInMinutes = $PostponeDurationInMinutes
                    $NotificationXml.Notification.deadline = (Get-Date (Get-Date).ToUniversalTime().AddMinutes($PostponeDurationInMinutes) -Format 'yyyy-MM-dd HH:mm:ssZ').ToString()
                    $NotificationXml.Notification.countdownToDeadlineInMinutes = $CountdownToDeadlineInMinutes
                    $NotificationXml.Notification.userPostponementPeriodInMinutesOne = $UserPostponementPeriodInMinutesOne
                    $NotificationXml.Notification.userPostponementPeriodInMinutesTwo = $UserPostponementPeriodInMinutesTwo
                    $NotificationXml.Notification.userPostponementPeriodInMinutesThree = $UserPostponementPeriodInMinutesThree
                }
                $NotificationConfiguration = $NotificationXml.Notification.OuterXml
                Set-Content -Path $NotificationXmlFile -Value $NotificationConfiguration -Force | Out-Null
            }
            if (Test-Path -Path $NotificationXmlFile) {
                Write-Verbose "Found notification file $NotificationXmlFile"
                $CurrentUser = [System.Security.Principal.WindowsIdentity]::getcurrent().name
                Write-Verbose "Current User: $CurrentUser"
                if ($CurrentUser -eq 'NT AUTHORITY\SYSTEM') {
                    Write-Verbose "Running as $CurrentUser. Attempting to run notification as logged in user."
                    & "$ClientUiPath\$UserSessionProxyExe" "$ClientUIPath\$ClientUIExe"  --xml-path "$NotificationXmlFile" --write-status "$ClientUIPath\$ClientUIStatusFile" $UI
                }
                else {
                    Write-Verbose "Running as $CurrentUser. Attempting to run notification as current user."
                    & "$ClientUIPath\$ClientUIExe"  --xml-path "$NotificationXmlFile" --write-status "$ClientUIPath\$ClientUIStatusFile" $UI
                }
                Write-Verbose "Checking to see if the notificaton process is still running before proceeding."
                $EunPid = Get-TaniumClientEndUserNotificationProcessPid -NotificationId $NotificationId
                if ($EunPid) {
                    Write-Verbose "Found PID $EunPid for notification. Waiting for the process to exit."
                    Wait-Process -Id $EunPid
                    Write-Verbose "Notification process $EunPid has exited."
                }
                else {
                    Write-Verbose "Notification process is no longer running."
                }
            }
            else {
                Write-Warning "Unable to find $NotificationXmlFile"
            }
        }
        else {
            Write-Warning 'Unable to find End-User Notification Tools'
        }
    }
    else {
        Write-Warning "No interactive logged in users found. Skipping End-user notification."
    }
}