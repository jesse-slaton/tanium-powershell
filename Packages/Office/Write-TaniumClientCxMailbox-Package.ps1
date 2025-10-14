function Write-TaniumClientCxMailbox {
    [cmdletbinding()]
    param (
        [parameter(mandatory=$true)]
        [ValidateSet('inbox','outbox')]
        [string]$Mailbox,
        [string]$File,
        [string]$Message
    )
    $TaniumClientDirectory = Get-TaniumClientDirectory
    if (Test-Path $TaniumClientDirectory) {
        $MailboxDirectory = "$TaniumClientDirectory\extensions\core\mailbox\$Mailbox"
        if (Test-Path $MailboxDirectory) {
            Write-Verbose "Found $Mailbox at $MailboxDirectory"
            $MailboxFile = "$MailboxDirectory\$File"
            if (Test-Path $MailboxFile) {
                Write-Warning "$MailboxFile already exists in $MailboxDirectory"
            }
            else {
                Write-Verbose "Creating message file in $Mailbox"
                Set-Content -Path $MailboxFile -Value $Message
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