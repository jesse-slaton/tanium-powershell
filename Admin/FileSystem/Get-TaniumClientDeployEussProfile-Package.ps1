function Get-TaniumClientDeployEussProfile {
    [cmdletbinding()]
    param(
        [string]$Name,
        [int]$Id
    )
    if (Test-Command -Name 'Invoke-SqliteQuery') {
        $Query = "SELECT * FROM euss_profiles WHERE product = 'Deploy'"
        if ($Name) {
            $Query += " AND name LIKE '%$Name%'"
        }
        if ($Id) {
            $Query += " AND euss_profile_id = $Id"
        }
        $TaniumClientDeployDbPath = Get-TaniumClientDeployDbFile
        $TaniumClientDeployProductInstallId = Invoke-SqliteQuery -Datasource $TaniumClientDeployDbPath -Query $Query
        $TaniumClientDeployProductInstallId
    }
    else {
        Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
    }
}