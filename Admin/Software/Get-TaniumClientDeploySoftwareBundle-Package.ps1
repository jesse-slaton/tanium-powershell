function Get-TaniumClientDeploySoftwareBundle {
    [cmdletbinding()]
    param(
        [string]$Name,
        [int]$Id
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT bundle_id,edit_id,name,description FROM bundles WHERE product = 'Deploy'"
        if ($Name) {
            $Query += " name LIKE '%$Name%'"
        }
        if ($Id) {
            $Query += " bundle_id = $Id"
        }
        $TaniumClientDeployDbPath = Get-TaniumClientDeployDbFile
        $TaniumClientDeployProductInstallId = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbPath -Query $Query
        $TaniumClientDeployProductInstallId
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}