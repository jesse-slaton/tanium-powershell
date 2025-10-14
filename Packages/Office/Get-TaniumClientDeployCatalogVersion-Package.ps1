function Get-TaniumClientDeployCatalogVersion {
    [cmdletbinding()]
    param( )
    $TaniumClientDeployConfigurationRecord = Get-TaniumClientDeployConfiguration -Setting software_package_catalog_version -CurrentProductInstallId
    $TaniumClientDeployConfigurationRecord.value | ConvertFrom-Json
}