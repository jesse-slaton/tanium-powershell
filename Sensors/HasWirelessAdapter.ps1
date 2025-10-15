If (Get-NetAdapter | Where-Object { $_.PhysicalMediaType -eq 'Native 802.11' }) {
    $True
}
Else { $False }