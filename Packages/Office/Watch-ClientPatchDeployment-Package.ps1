<#
.SYNOPSIS
Monitor a Tanium Patch deployment using Tanium End-User Notifications tools for logged in user.
.DESCRIPTION
Monitor a Tanium Patch deployment using Tanium End-User Notifications tools for logged in user. The function
can be used to give the logged in user occasional EUN "toast" notifications for an ongoing specified
Patch deployment. Notification intervals are customizable by parameter.
.PARAMETER DeploymentId
Specify a Patch deployment ID
.PARAMETER SleepInterval
Specify the sleep interval for the monitor loop. The monitor loop checks if the patch deployment status has changed
or the NotificationInterval has elapsed.
.PARAMETER NotificationInterval
Specify the notification interval for how often the toast notification should appear for the user.
.PARAMETER Timeout
Specify how long the function should loop monitoring the specified patch deployment. Once the timeout is reached, the function
will exit.
.NOTES
Created by: Jason Wasser @wasserja
#>
function Watch-TaniumClientPatchDeployment {
    [cmdletbinding()]
    param (
        $DeploymentId = 999,
        $SleepInterval = 60,
        $NotificationInterval = 120,
        $Timeout = 1800
    )

    if (Get-TaniumClientPatchDeployment -Id $DeploymentId) {
        $TimeoutExceeded = $false
        $StartTime = Get-Date
        $EndTime = $StartTime.AddSeconds($Timeout)
        $PreviousDeploymentStatus = 'No Status'
        $DeploymentStatusChanged = $false
        $NextNotificationTime = Get-Date
        do {
            Write-Verbose "$(Get-Date) Beginning Patch deployment loop"
            $DeploymentStatus = Get-TaniumClientPatchDeploymentStatus -id $DeploymentId
            if ((Get-Date) -ge $EndTime) {
                Write-Host 'Timeout Exceeded'
                $TimeoutExceeded = $true
            }
            else {
                if ($DeploymentStatus.status -ne $PreviousDeploymentStatus) {
                    Write-Verbose "Deployment status changed. Previous: $PreviousDeploymentStatus Current: $($DeploymentStatus.status)"
                    $DeploymentStatusChanged = $true
                    $PreviousDeploymentStatus = $DeploymentStatus.status
                }
                else {
                    Write-Verbose "Deployment status has not changed: $($DeploymentStatus.status)"
                    $DeploymentStatusChanged = $false
                }
                $NotificationTimeElapsed = (Get-Date) -ge $NextNotificationTime
                if ($NotificationTimeElapsed) {
                    Write-Verbose "$(Get-Date) - Notification interval has elapsed: $NextNotificationTime"
                }
                else {
                    Write-Verbose "$(Get-Date) - Notification interval has not elapsed: $NextNotificationTime"
                }
                # Check to see if the notification interval has elapsed or the deployment status has changed. if either are true then show the notification.
                if ($NotificationTimeElapsed -or $DeploymentStatusChanged) {
                    $Body = "Deployment $DeploymentId Last Update $($DeploymentStatus.updatedAt) - $($DeploymentStatus.parentStatus): $($DeploymentStatus.status)"
                    Write-Verbose "Popping toast notification: $Body"
                    New-TaniumClientEndUserNotification -Title 'Patch Deployment Status' -Body $Body -Type notice -UI toast
                    Write-Verbose "Sleeping for $SleepInterval seconds until $((Get-Date).AddSeconds($SleepInterval))"
                    $NextNotificationTime = (Get-Date).AddSeconds($NotificationInterval)
                    Write-Verbose "Next notification message at: $NextNotificationTime"
                }
                else {
                    Write-Verbose "Deployment status has not changed, and it is not time for the next notification. Sleeping for $SleepInterval seconds until $((Get-Date).AddSeconds($SleepInterval))."
                }
                Start-Sleep -Seconds $SleepInterval
            }
        }
        until ($DeploymentStatus.parentStatus -eq 'Complete' -or $DeploymentStatus.parentStatus -eq 'Not Applicable' -or $DeploymentStatus.status -eq 'Pending Restart, Awaiting User Acceptance' -or $TimeoutExceeded)
        if ($TimeoutExceeded) {
            Write-Verbose "Timeout exceeded: $Timeout seconds"
        }
        if ($DeploymentStatus.parentStatus -eq 'Complete') {
            Write-Verbose "Deployment $DeploymentId is Complete"
        }
        if ($DeploymentStatus.parentStatus -eq 'Not Applicable') {
            Write-Verbose "Deployment $DeploymentId is Not Applicable"
        }
    }
    else {
        Write-Warning "Unable to find Patch deployment $DeploymentId"
    }
}