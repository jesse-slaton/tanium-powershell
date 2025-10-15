function Get-TaniumClientPatchCabFileSize {
    [CmdletBinding()]
    param( 
        [ValidateSet('Local', 'CDN')]  
        [string[]]$Source = @('Local','CDN')
    
    )
    foreach ($S in $Source) {
        switch ($S) {
            'CDN' {
                $Path = 'http://download.windowsupdate.com/microsoftupdate/v6/wsusscan/wsusscn2.cab'
                Write-Verbose "Attempting to read file size from $Path"
                try {
                    $Size = (Invoke-WebRequest -Uri $Path -Method Head -ErrorAction Stop -UseBasicParsing).Headers.'Content-Length'
                    $TaniumClientPatchCabFileSizeProperties = @{
                        'Source' = $S
                        'Size'   = $Size
                    }
                    $TaniumClientPatchCabFileSize = New-Object -TypeName PSObject -Property $TaniumClientPatchCabFileSizeProperties
                    Write-Output $TaniumClientPatchCabFileSize
                }
                catch {
                    Write-Warning "Unable to read cab file size from $Path"
                }
            }
            'Local' {
                $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
                $Path = "$TaniumClientPatchDirectory\scans\wsusscn2.cab"
                if (Test-Path $Path) {
                    Write-Verbose "Attempting to read file size from $Path"
                    $Size = (Get-Item -Path $Path).Length
                    $TaniumClientPatchCabFileSizeProperties = @{
                        'Source' = $S
                        'Size'   = $Size
                    }
                    $TaniumClientPatchCabFileSize = New-Object -TypeName PSObject -Property $TaniumClientPatchCabFileSizeProperties
                    Write-Output $TaniumClientPatchCabFileSize
                }
                else {
                    Write-Warning "Unable to find $Path"
                }
            }
        }
    }
}