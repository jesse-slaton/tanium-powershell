function Restart-TaniumClientCx {
    [CmdletBinding()]
    param()
    begin {
        $Message = @"
{
    "format_version": "1",
    "command": "core.restart",
    "command_version": "1",
    "payload": {}
}
"@

    }
    process {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        if (Test-Path $TaniumClientDirectory) {
            Write-Verbose "Sending command to restart Tanium Client CX"
            $Timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $MailboxFile = "core.restart-$Timestamp.txt"
            Write-TaniumClientCxMailbox -Mailbox inbox -File $MailboxFile -Message $Message
            Write-Verbose "Sleeping 3 seconds"
            Start-Sleep -Seconds 3
            $MailboxFileMessage = Read-TaniumClientCxMailbox -Mailbox outbox -File $MailboxFile -Remove
            $MailboxFileMessage
        }
        else {
            Write-Warning "Unable to find the Tanium client directory."
        }
    }
    end {} 
}