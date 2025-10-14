function Read-TaniumClientCxMailbox {
    [cmdletbinding()]
    param (
        [parameter(mandatory=$true)]
        [ValidateSet('inbox','outbox')]
        [string]$Mailbox,
        [string]$File,
        [switch]$Remove
    )
    $TaniumClientDirectory = Get-TaniumClientDirectory
    if (Test-Path $TaniumClientDirectory) {
        $MailboxDirectory = "$TaniumClientDirectory\extensions\core\mailbox\$Mailbox"
        if (Test-Path $MailboxDirectory) {
            Write-Verbose "Found $Mailbox at $MailboxDirectory"
            $MailboxFile = "$MailboxDirectory\$File"
            if (Test-Path $MailboxFile) {
                Write-Verbose "Reading Mailbox File $MailboxFile"
                $MailboxFileMessage = Get-Content -Path $MailboxFile
                $MailboxFileMessage
                if ($Remove) {
                    Remove-Item -Path $MailboxFile
                }
            }
            else {
                Write-Warning "Unable to find $MailboxFile"
            }
        }
        else {
            Write-Warning "Unable to find $Mailbox at $MailboxPath"
        }
    }
    else {
        Write-Warning 'Unable to find the Tanium client directory.'
    }
}