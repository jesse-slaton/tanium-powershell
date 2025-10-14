function Get-TaniumClientEndpointConfigurationTool {
    [cmdletbinding()]
    param(
        [string]$Tool
    )
    $TaniumClientDirectory = Get-TaniumClientDirectory
    $TaniumClientEndpointConfigurationTool = Get-TaniumClientDbTable -Table v_tool_states -Path "$TaniumClientDirectory\extensions\config\tools.db"
    if ($TaniumClientEndpointConfigurationTool) {
        if ($Tool) {
            $TaniumClientEndpointConfigurationTool | Where-Object -FilterScript { $_.name -like "*$Tool*" }
        }
        else {
            $TaniumClientEndpointConfigurationTool
        }
    }
    else {
        Write-Warning 'Unable to find Endpoint Configuration Tools db'
    }
}