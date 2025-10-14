function Get-TaniumClientDeploySoftwarePackage {
    [cmdletbinding()]
    param(
        [string]$Name,
        [int]$Id
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT software_package_id,edit_id,product_name,product_vendor,product_version,platform,applicability FROM software_packages WHERE product = 'Deploy'"
        if ($Name) {
            $Query += " AND product_name LIKE '%$Name%'"
        }
        if ($Id) {
            $Query += " AND software_package_id = $Id"
        }
        $TaniumClientDeployDbPath = Get-TaniumClientDeployDbFile
        $TaniumClientDeployProductInstallId = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbPath -Query $Query
        $TaniumClientDeployProductInstallId
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}