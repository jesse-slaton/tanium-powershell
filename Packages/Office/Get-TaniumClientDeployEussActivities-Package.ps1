function Get-TaniumClientDeployEussActivities {
    [cmdletbinding()]
    param (
        [string]$Path = "$env:ProgramData\Tanium\Tanium End User Notification Tools\euss.db",
        [ValidateSet('All','Active','Stale','Pending')]
        [string]$Type = 'All'
    )
    if (Test-Path -Path $Path) {
        switch ($Type) {
            'All' {
                $DeployEussActivities = Get-TaniumClientDbTable -Path $Path -Table 'activities'
            }
            'Active' {
                $Query = "SELECT catalog.title,catalog.inProgressMessage,activities.* from activities INNER JOIN catalog ON activities.catalogId = catalog.id WHERE activities.wasSuccessful IS NULL AND activities.updatedAt >  DATETIME('now', '-1 days')  AND activities.currentActivityScheduledStart < datetime('now')"
                $DeployEussActivities = Invoke-SqliteQuery -DataSource $Path -Query $Query
            }
            'Stale' {
                $Query = "SELECT catalog.title,catalog.inProgressMessage,activities.* from activities INNER JOIN catalog ON activities.catalogId = catalog.id WHERE activities.wasSuccessful IS NULL AND activities.updatedAt <  DATETIME('now', '-1 days')  AND activities.currentActivityScheduledStart < datetime('now')"
                $DeployEussActivities = Invoke-SqliteQuery -DataSource $Path -Query $Query
            }
            'Pending' {
                $Query = "SELECT catalog.title,catalog.inProgressMessage,activities.* from activities INNER JOIN catalog ON activities.catalogId = catalog.id WHERE activities.wasSuccessful IS NULL AND activities.updatedAt >  DATETIME('now', '-1 days')  AND activities.currentActivityScheduledStart > datetime('now')"
                $DeployEussActivities = Invoke-SqliteQuery -DataSource $Path -Query $Query
            }
        }
        $DeployEussActivities
    }
    else {
        Write-Warning "Unable to find $Path"
    }
}