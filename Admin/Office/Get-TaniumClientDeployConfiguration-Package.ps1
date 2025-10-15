function Get-TaniumClientDeployConfiguration {
    [cmdletbinding()]
    param(
        [string]$Setting,
        [switch]$CurrentProductInstallId
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT * FROM configurations WHERE product = 'Deploy'"
        if ($Setting) {
            $Query += " AND key LIKE '%$Setting%'"
        }
        if ($CurrentProductInstallId.IsPresent) {
            $TaniumClientDeployProductInstallId = Get-TaniumClientDeployProductInstallId
            $Query += " AND product_install_id = '$TaniumClientDeployProductInstallId'"
        }
        $TaniumClientDeployDbFile = Get-TaniumClientDeployDbFile
        $TaniumClientDeployConfiguration = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbFile -Query $Query
        $TaniumClientDeployConfiguration
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}