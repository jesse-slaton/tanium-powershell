function Get-TaniumClientCxConfigurationManifestRevision {
    [CmdletBinding()]
    param()
    begin {
        $Message = @"
{
    "format_version": "1",
    "command": "config.get-manifest-revision",
    "command_version": "1",
    "payload": {}
}
"@

    }
    process {
        $TaniumClientDirectory = Get-TaniumClientDirectory
        if (Test-Path $TaniumClientDirectory) {
            Write-Verbose "Getting Tanium Client CX Configuration Revision"
            $Timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $MailboxFile = "config.get-manifest-revision-$Timestamp.txt"
            Write-TaniumClientCxMailbox -Mailbox inbox -File $MailboxFile -Message $Message
            Write-Verbose "Sleeping 3 seconds"
            Start-Sleep -Seconds 3
            $MailboxFileMessage = Read-TaniumClientCxMailbox -Mailbox outbox -File $MailboxFile -Remove
            if ($MailboxFileMessage.contains('|')) {
                $Revision = $MailboxFileMessage.split('|')[0]
                $ServiceUUID = $MailboxFileMessage.split('|')[1]

                $ManifestDirectory = "$TaniumClientDirectory\extensions\config\Manifest"
                if (Test-Path -Path $ManifestDirectory) {
                    $ManifestModifiedTime = Get-Item -Path $ManifestDirectory | Select-Object -ExpandProperty LastWriteTime
                }
                else {
                    $ManifestModifiedTime = 'N/A'
                }

                $TaniumClientCxConfigurationManifestRevisionProperties = [ordered]@{
                    'Revision'             = $Revision
                    'ServiceUUID'          = $ServiceUUID
                    'ManifestModifiedTime' = $ManifestModifiedTime
                }
                $TaniumClientCxConfigurationManifestRevision = New-Object -TypeName pscustomobject -Property $TaniumClientCxConfigurationManifestRevisionProperties
                Write-Output $TaniumClientCxConfigurationManifestRevision
            }
            else {
                Write-Output $MailboxFileMessage
            }
        }
        else {
            Write-Warning "Unable to find the Tanium client directory."
        }
    }
    end {}
}