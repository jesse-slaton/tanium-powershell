function Test-TaniumClientPeering {
    [cmdletbinding()]
    param ()
    $TaniumClientPeering = Get-TaniumClientPeer -PeerType Both
    if ($TaniumClientPeering) {
        $TaniumClientPeerAddress = $TaniumClientPeering | Where-Object -FilterScript {$_.Setting -eq 'Status.PeerAddress'} | Select-Object -ExpandProperty Value
        Write-Verbose "Tanium Client Peer Address: $TaniumClientPeerAddress"
        $TaniumClientBackPeerAddress = $TaniumClientPeering | Where-Object -FilterScript {$_.Setting -eq 'Status.BackPeerAddress'} | Select-Object -ExpandProperty Value
        Write-Verbose "Tanium Client Back Peer Address: $TaniumClientBackPeerAddress"
        if ($TaniumClientPeerAddress -eq 'NoAddress_NoAddress' -and $TaniumClientBackPeerAddress -eq 'NoAddress_NoAddress') {
            Write-Verbose 'Tanium client is not peering.'
            Write-Output $false
        }
        else {
            Write-Verbose 'Tanium Client is peering.'
            Write-Output $true
        }
    }
    else {
        Write-Warning 'Unable to determine Tanium client peering'
    }
}