function New-TaniumClientDeployDeployment {
    [cmdletbinding()]
    param (
        [int]$Id = 999,
        [string]$Name = 'Manual',
        [int[]]$PackageId = 1172,
        [int]$DeploymentLengthInHours = 1
    )
    begin {
        $TaniumClientDeployConfiguration = @"
{
    "action_type": "deployment",
    "action_data": {
        "deployment_id": 999,
        "name": "Manual Deployment",
        "download_immediately": false,
        "euss_available_before_start": false,
        "euss_hide_from_activity": false,
        "distribute_over_time_seconds": null,
        "override_maintenance_windows": true,
        "product": "Deploy",
        "product_install_id": "e70123f4-d79e-45bc-b042-a95d591c2cc5",
        "start_time": "2020-07-31T08:00:00-07:00",
        "end_time": "2020-07-31T12:00:00-07:00",
        "stopped_at": null,
        "tasks": []
    }
}
"@ | ConvertFrom-Json
        $TasksConfiguration = @"
{
    "task_type": "software_package",
    "options": {
        "software_package_id": 1554,
        "software_package_edit_id": 1,
        "platform": "windows",
        "operation": "install"
    },
    "on_failure": "exit",
    "dependencies": null
}
"@ | ConvertFrom-Json

        # Updating Json with parameter data
        $EndTime = (Get-Date ((Get-Date).AddHours($DeploymentLengthInHours)) -format "yyyy-MM-ddTHH:mm:ss").toString()
        $TaniumClientDeployConfiguration.action_data.deployment_id = $Id
        $TaniumClientDeployConfiguration.action_data.name = $Name
        $TaniumClientDeployConfiguration.action_data.end_time = $EndTime

        foreach ($Package in $PackageId) {
            Write-Verbose "Adding Package Id $Package to json"
            $TaskConfiguration = $TasksConfiguration.PsObject.Copy()
            $TaskConfiguration.options.software_package_id = $Package
            $TaniumClientDeployConfiguration.action_data.tasks += $TaskConfiguration
        }        
    }
    process {
        $TaniumClientDeployDirectory = Get-TaniumClientDeployDirectory
        if ($TaniumClientDeployDirectory) {
            Write-Verbose 'Found Tanium client Deploy directory'
            # Assuming Deploy 2 at this point  
            Write-Verbose "Generating deployment json file"
            $TaniumClientDeployConfiguration | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path "$TaniumClientDeployDirectory\data\actions\deploy-deployment-$Id.json" -Force
            #Start-TaniumClientDeployWakeup
        }
        else {
            Write-Warning 'Aborting. Unable to find Tanium client deploy directory.'
        }
    }
    end {}
}