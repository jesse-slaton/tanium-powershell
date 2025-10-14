function Get-TaniumClientPatchTswDb {
    [cmdletbinding()]
    param (
        [string]$Name
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
    $TaniumClientPatchTswManifest = Get-TaniumClientPatchTswManifest
    $TswDbPath = "$TaniumClientPatchDirectory\scans\tanium-scan"

    if ($Name) {
        $TaniumClientPatchApplicableProducts = Get-TaniumClientPatchApplicableProducts | Where-Object -FilterScript { $_.name -like "*$Name*" }
    }
    else {
        $TaniumClientPatchApplicableProducts = Get-TaniumClientPatchApplicableProducts
    }
    
    if ($TaniumClientPatchApplicableProducts -and $TaniumClientPatchTswManifest) {
        foreach ($TaniumClientPatchApplicableProduct in $TaniumClientPatchApplicableProducts) {
            Write-Verbose "Checking $($TaniumClientPatchApplicableProduct.name)"
            $ApplicableProductTswManifest = $TaniumClientPatchTswManifest | Where-Object -FilterScript { $_.applicabilityKey -eq $TaniumClientPatchApplicableProduct.guid }
            Write-Verbose "$($TaniumClientPatchApplicableProduct.name) has guid $($TaniumClientPatchApplicableProduct.guid) and applicablityKey $($ApplicableProductTswManifest.applicabilityKey)"
            Write-Verbose "Checking to see if $($TaniumClientPatchApplicableProduct.name) has a populated id field"
            if ($ApplicableProductTswManifest.id) {
                Write-Verbose "$($TaniumClientPatchApplicableProduct.name) does have a populated id field."
                $ApplicableProductTswManifestDbPath = "$TswDbPath\$($ApplicableProductTswManifest.id).db"
                $TaniumClientTswDbPathProperties = @{
                    Name             = $TaniumClientPatchApplicableProduct.name
                    guid             = $TaniumClientPatchApplicableProduct.guid
                    id               = $ApplicableProductTswManifest.id
                    applicabilityKey = $ApplicableProductTswManifest.applicabilityKey
                    uncompressedHash = $ApplicableProductTswManifest.uncompressedHash
                    hash             = $ApplicableProductTswManifest.hash
                    path             = $ApplicableProductTswManifestDbPath
                }
                $TaniumClientTswDbPath = New-Object -TypeName PSObject -Property $TaniumClientTswDbPathProperties
                Write-Output $TaniumClientTswDbPath
            }
            else {
                Write-Verbose "$($TaniumClientPatchApplicableProduct.name) does not have a populated id field. Skipping."
            }
            
        }
    }
    else {
        Write-Warning "Unable to find Tanium Scan Database."
    }
}