function Get-TaniumClientDeployProductInstallId {
    [cmdletbinding()]
    param()
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT current_install_id FROM product_install_ids WHERE product = 'Deploy'"
        $TaniumClientDeployDbPath = Get-TaniumClientDeployDbFile
        $TaniumClientDeployProductInstallId = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbPath -Query $Query
        $TaniumClientDeployProductInstallId | Select-Object -ExpandProperty 'current_install_id'
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}