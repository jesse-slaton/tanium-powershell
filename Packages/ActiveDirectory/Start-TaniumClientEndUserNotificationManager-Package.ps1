<#
.SYNOPSIS
A generatic manager function to display Tanium End-User Notifications.
.DESCRIPTION
A generatic manager function to display Tanium End-User Notifications.
Features
 * Display customized EUN notification as modal or toast
 * Provide full postponement functionality
 * Support the install and restart actions
 * Logging of activity and buttons pushed by user

Goal: Provide similar EUN functionality that Deploy and Patch offer but standalone and
customizable.
.PARAMETER Title
Enter a title for the notification
.PARAMETER Body
Enter the text for the body of the notification
.PARAMETER Type
Notice - a one-time notification with an OK button
Restart - a one-time or multiple notification if $AllowPostponement is $true. When accepted
or deadline is reached the computer will restart.
Install - a one-time or multiple notification if $AllowPostponement is $true. When accepted
or deadline is reached the computer will proceed to next command.
.PARAMETER UI
Modal - a modal pop up is displayed
Toast - a toast notification is displayed
.PARAMETER NotificationId
Specify a notification ID if necessary. By default a GUID will be generated to ensure uniqueness.
.PARAMETER NotificationXmlFile
Enter a path where to save the generated notification xml file. Defaults to $env:temp
.PARAMETER AllowPostponement
Use this switch to allow postponement of the notification action (i.e. Restart)
.PARAMETER PostponeDurationInMinutes
Enter a number of minutes that will specify the deadline for the notification (i.e. how long until
the notification action must take place)
.PARAMETER CountdownToDeadlineInMinutes
Enter a number of minutes before the deadline to show the countdown timer.
.PARAMETER UserPostponementPeriodInMinutesOne
Enter a number of minutes the first postponement option (i.e 60 minutes)
.PARAMETER UserPostponementPeriodInMinutesTwo
Enter a number of minutes the second postponement option (i.e 120 minutes)
.PARAMETER UserPostponementPeriodInMinutesThree
Enter a number of minutes the third postponement option (i.e 240 minutes)
.PARAMETER GentleNotificationDurationInMinutes
Enter a number of minutes that a toast notification should appear, after which the notification will
automatically dismiss.
.PARAMETER SleepInterval
Enter a number of seconds to sleep during the main loop.
.NOTES
Created by: Jason Wasser @wasserja
Modified: 2021-08-09
#>
function Start-TaniumClientEndUserNotificationManager {
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
        [switch]$AllowPostponement,
        [ValidatePattern('\d+$')]
        [string]$PostponeDurationInMinutes = '300',
        [ValidatePattern('\d+$')]
        [string]$CountdownToDeadlineInMinutes = '10',
        [ValidatePattern('\d+$')]
        [string]$UserPostponementPeriodInMinutesOne = '60',
        [ValidatePattern('\d+$')]
        [string]$UserPostponementPeriodInMinutesTwo = '120',
        [ValidatePattern('\d+$')]
        [string]$UserPostponementPeriodInMinutesThree = '240',
        [ValidatePattern('\d+$')]
        [string]$GentleNotificationDurationInMinutes = '0.75',
        [int]$SleepInterval = 60
    )
    # begin helper functions
    function Get-NotificationStatus {
        param (
            $NotificationId
        )
        if (Test-Path -Path $NotificationStatusFile) {
            Write-Verbose "Found $NotificationStatusFile"
            [xml]$NotificationStatusXml = Get-Content -Path $NotificationStatusFile
            $CurrentNotificationStatusXml = $NotificationStatusXml.NotificationStatus | Where-Object -FilterScript { $_.id -eq $NotificationId }
            $ValidResponses = @('acceptedAt', 'postponedUntil', 'dismissedAt')
            $Response = $CurrentNotificationStatusXml | Get-Member | Where-Object -FilterScript { $_.Name -in $ValidResponses } | Select-Object -ExpandProperty Name
            $ResponseTime = [datetime]::ParseExact($CurrentNotificationStatusXml.$Response, 'yyyy-MM-dd HH:mm:ssZ', $null)
            Write-Verbose "Response: $Response"
            Write-Verbose "Response Time: $ResponseTime"
            $NotificationStatusProperties = @{
                Id           = $CurrentNotificationStatusXml.Id
                Response     = $Response
                ResponseTime = $ResponseTime
            }
            $NotificationStatus = New-Object -Type pscustomobject -Property $NotificationStatusProperties
            $NotificationStatus
        }
        else {
            Write-Warning "Unable to read $NotificationStatusFile"
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
            Write-Warning "Unable to find $NotificationXmlFile"
        }
    }
    function Test-NotificationDeadline {
        param (
            $NotificationXmlFile
        )
        Write-Verbose "Found $NotificationXmlFile. Checking deadline."
        $Deadline = [datetime]::ParseExact($(Get-Notification -NotificationXmlFile $NotificationXmlFile).deadline, 'yyyy-MM-dd HH:mm:ssZ', $null)
        Write-Verbose "Deadline: $Deadline"
        if ((Get-Date) -ge $Deadline) {
            Write-Verbose "Deadline $Deadline has been exceeded."
            $DeadlineExceeded = $true
        }
        else {
            Write-Verbose "Deadline $Deadline has not exceeded."
            $DeadlineExceeded = $false
        }
        Write-Output $DeadlineExceeded
    }
    function Test-NotificationPostponementElapsed {
        param (
            $NotificationId
        )
        $NotificationStatus = Get-NotificationStatus -NotificationId $NotificationId
        if ((Get-Date) -ge $NotificationStatus.ResponseTime) {
            Write-Verbose "Notification time $($NotificationStatus.ResponseTime) has elapsed."
            Write-Output $true
        }
        else {
            Write-Verbose "Notification time $($NotificationStatus.ResponseTime) has not elapsed."
            Write-Output $false
        }
    }
    # end of helper functions

    # Begin main

    # Gather all parameters and values except for SleepInterval
    $params = @{}
    foreach ($h in $MyInvocation.MyCommand.Parameters.GetEnumerator()) {
        try {
            $key = $h.Key
            $val = Get-Variable -Name $key -ErrorAction Stop | Select-Object -ExpandProperty Value -ErrorAction Stop
            if (([String]::IsNullOrEmpty($val) -and (!$PSBoundParameters.ContainsKey($key)))) {
                throw "A blank value that wasn't supplied by the user."
            }
            Write-Verbose "$key => '$val'"
            $params[$key] = $val
        }
        catch {}
    }
    $params.Remove('SleepInterval')


    $ClientUIPath = 'C:\Program Files (x86)\Tanium\Tanium End User Notification Tools'
    $ClientUIStatusFileName = 'notification-statuses.xml'
    $NotificationStatusFile = "$ClientUIPath\$ClientUIStatusFileName"
    #$PreviousClientUIStatusFileName = 'previous-notification-status'
    #$PreviousNotificationStatusFile = "$ClientUIPath\$PreviousClientUIStatusFileName"
    $DeadlineExceeded = $false
    $PostponementElapsed = $true
    $FirstRun = $true

    do {
        Write-Verbose "Beginning loop"
        if (Test-InteractiveLogonUser) {
            Write-Verbose 'Found interactive logon user explorer process(es). Continuing.'
        }
        else {
            Write-Warning "No interactive logged in users found. Skipping End-user notification."
            break
        }
        if ($FirstRun) {
            # Do first run checks here
            $FirstRun = $false
            Write-Verbose "First run of loop"
        }
        else {
            # Do the subsequent jobs here.
            $DeadlineExceeded = Test-NotificationDeadline -NotificationXmlFile $NotificationXmlFile
            if ($DeadlineExceeded) {
                Write-Verbose "Deadline $Deadline exceeded. Exiting loop."
                return
            }
            $PostponementElapsed = Test-NotificationPostponementElapsed -NotificationId $NotificationId
        }

        if ($FirstRun -or $PostponementElapsed) {
            Write-Verbose "Generating notification"
            New-TaniumClientEndUserNotification @params
            Write-Verbose "Reading generated notification xml file $NotificationXmlFile"
            $DeadlineExceeded = Test-NotificationDeadline -NotificationXmlFile $NotificationXmlFile
            Write-Verbose "Reading Notification Status File $NotificationStatusFile"
            $NotificationStatus = Get-NotificationStatus -NotificationId $NotificationId
            Write-Verbose "At $(Get-Date) the notification response was $($NotificationStatus.Response). Next action at $($NotificationStatus.ResponseTime)"
            if ($NotificationStatus.Response -eq 'acceptedAt' -or $DeadlineExceeded) {
                Write-Verbose "Notification has been accepted or has reached the deadline."
            }
            else {
                Write-Verbose "Notification status: $($NotificationStatus.Response)"
                Write-Verbose "Sleeping for $SleepInterval seconds until $((Get-Date).AddSeconds($SleepInterval))"
                Start-Sleep -Seconds $SleepInterval
            }
        }
        else {
            Write-Verbose "Postponement period has not elapsed."
            Write-Verbose "Sleeping for $SleepInterval seconds until $((Get-Date).AddSeconds($SleepInterval))"
            Start-Sleep -Seconds $SleepInterval
        }
    } until ($NotificationStatus.Response -eq 'acceptedAt' -or $DeadlineExceeded)
    if ($Type -eq 'restart') {
        Write-Verbose "Proceeding with system restart."
        Restart-Computer -Force
    }
    elseif ($Type -eq 'install') {
        Write-Verbose "$Type not yet supported. Exiting."

    }
    else {
        Write-Verbose 'Exiting'
    }
}