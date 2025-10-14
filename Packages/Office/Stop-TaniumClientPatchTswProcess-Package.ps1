function Stop-TaniumClientPatchTswProcess {
    [CmdletBinding()]
    param()
    begin {
        $Message = @"
{
    "format_version": "1",
    "command": "software_manager.stop-update-service",
    "command_version": "1",
    "payload": {}
}
"@

    }
    process {
        $TaniumClientPatchTswProcess = Get-TaniumClientPatchTswProcess
        if ($TaniumClientPatchTswProcess) {
            Write-Verbose "The Tanium client Patch TSW process is running."
            $TaniumClientDirectory = Get-TaniumClientDirectory
            if (Test-Path $TaniumClientDirectory) {
                $Timestamp = Get-Date -Format 'yyyyMMddHHmmss'
                $MailboxFile = "start-update-service-$Timestamp.txt"
                Write-TaniumClientCxMailbox -Mailbox inbox -File $MailboxFile -Message $Message
                Start-Sleep -Seconds 3
                $MailboxFileMessage = Read-TaniumClientCxMailbox -Mailbox outbox -File $MailboxFile -Remove
                $MailboxFileMessage
            }
            else {
                Write-Warning "Unable to find the Tanium client directory."
            }
        }
        else {
            Write-Warning "The Tanium client Patch TSW process is not running"
        }
    }
    end {} 
}