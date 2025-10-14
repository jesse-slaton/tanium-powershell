# Example PowerShell script to decode UTF-8 username and schedule a task

param (
    [Parameter(Mandatory=$true)]
    [string]$encodedUsername
)

# Decode the username
$decodedBytes = [System.Convert]::FromBase64String($encodedUsername)
$decodedUsername = [System.Text.Encoding]::UTF8.GetString($decodedBytes)

# Path to your PowerShell script you want to schedule
$scriptPath = "C:\Contoso\BackupChromeBookmarks.ps1"

# Check if the script file exists in the specified path
if (-not (Test-Path $scriptPath)) {
    # Copy the script file from the current path to the specified path
    Copy-Item -Path .\BackupChromeBookmarks.ps1 -Destination $scriptPath
}

# Define the action to execute the script under the PowerShell executable
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# Define the trigger for the task (e.g., at logon)
$trigger = New-ScheduledTaskTrigger -AtLogon

# Register the scheduled task to run under the current user
# Note: This part assumes the script is run by the target user or an admin who specifies the correct user context
Register-ScheduledTask -TaskName "Tanium-BackupChromeBookmarks" -Action $action -Trigger $trigger -User $decodedUsername -RunLevel Highest

Write-Output "Scheduled task created for user: $decodedUsername"
