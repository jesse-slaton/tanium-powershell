Try {
    $SBStatus = Confirm-SecureBootUEFI
    $Result =  $SBStatus
}

Catch {
    Write-Host "Not Applicable"
}

Finally {
    Write-Host $Result
}