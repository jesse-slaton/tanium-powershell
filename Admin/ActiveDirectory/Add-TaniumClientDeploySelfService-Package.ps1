function Add-TaniumClientDeploySelfServiceProfile {
    [cmdletbinding()]
    param (
        [int]$Id = 999,
        [string]$Name = 'Manual',
        [int[]]$PackageId = 1172,
        [int[]]$BundleId
    )
    begin {
        $TaniumClientDeployConfiguration = @"
{
    "action_type": "euss_profile",
    "action_data": {
        "id": 999,
        "edit_id": 1,
        "product": "Deploy",
        "product_install_id": "e70123f4-d79e-45bc-b042-a95d591c2cc5",
        "name": "Manual",
        "software": {
            "packages": [],
            "bundles": []
        },
        "definition_last_modified": "2020-08-01T00:13:23.455"
    }
}
"@ | ConvertFrom-Json
        $PackagesConfiguration = @"
{
    "id": 1,
    "install": true,
    "update": true,
    "remove": true,
    "restart": false
}
"@ | ConvertFrom-Json
        $BundlesConfiguration = @"
{
    "id": 1,
    "install": true,
    "restart": false
}
"@ | ConvertFrom-Json


        # Updating Json with parameter data
        $TaniumClientDeployConfiguration.action_data.id = $Id
        $TaniumClientDeployConfiguration.action_data.name = $Name

        foreach ($Package in $PackageId) {
            Write-Verbose "Adding Package Id $Package to json"
            $PackageConfiguration = $PackagesConfiguration.PsObject.Copy()
            $PackageConfiguration.id = $Package
            $TaniumClientDeployConfiguration.action_data.software.packages += $PackageConfiguration
        }
        
        foreach ($Bundle in $BundleId) {
            Write-Verbose "Adding Bundle Id $Package to json"
            $BundleConfiguration = $BundlesConfiguration.PsObject.Copy()
            $BundleConfiguration.id = $Bundle
            $TaniumClientDeployConfiguration.action_data.software.bundles += $BundleConfiguration
        }
        
    }
    process {
        $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
        if ($TaniumClientDeployDirectory) {
            Write-Verbose 'Found Tanium client Deploy directory'
            # Assuming Deploy 2 at this point  
            Write-Verbose "Generating euss profile json file"
            $TaniumClientDeployConfiguration | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path "$TaniumClientDeployDirectory\data\actions\deploy-euss-profile-$Id.json" -Force
            Start-TaniumClientDeployWakeup
        }
        else {
            Write-Warning 'Aborting. Unable to find Tanium client deploy directory.'
        }
    }
    end {}
}