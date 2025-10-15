function Get-TaniumClientPatchConfiguration {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [ValidateSet('deployment','scan','blocklist','maintenancewindow','patchlist')]
        [string]$ConfigurationType,
        [parameter(Mandatory=$true)]
        [string]$Id
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory

    switch ($ConfigurationType) {
        'deployment' {
            $ConfigurationFilePath = "$TaniumClientPatchDirectory\deployments\configurations\deployment-$Id.xml"
            $Element = 'Deployment'
        }
        'scan' {
            $ConfigurationFilePath = "$TaniumClientPatchDirectory\scans\configurations\scan-configuration-$Id.xml"
            $Element = 'ScanConfiguration'
        }
        'blocklist' {
            $ConfigurationFilePath = "$TaniumClientPatchDirectory\blacklists\configurations\blacklist-$Id.xml"
            $Element = 'Blacklist'
        }
        'maintenancewindow' {
            $ConfigurationFilePath = "$TaniumClientPatchDirectory\maintenance-windows\configurations\maintenance-window-$Id.xml"
            $Element = 'MaintenanceWindow'
        }
        'patchlist' {
            $ConfigurationFilePath = "$TaniumClientPatchDirectory\patchlists\configurations\patchlist-$Id.xml"
            $Element = 'PatchList'
        }
    }

    if (Test-Path $ConfigurationFilePath) {
        Write-Verbose "Tanium Client Patch $ConfigurationType $Id found"
        $TaniumClientPatchConfiguration = Read-XmlFile -Path $ConfigurationFilePath
        $TaniumClientPatchConfiguration.$Element
    }
    else {
        Write-Warning "Tanium Client Patch configuration $ConfigurationType $Id doesn't exist"
    }
}