function Get-TaniumClientDbTable {
    [cmdletbinding()]
    param(
        [string]$Table,
        [parameter(mandatory = $true)]
        [string]$Path
    )
    if (Test-Path $Path) {
        if (Test-Command -Name 'Invoke-SqliteQuery') {
            if ($Table) {
                $Query = "SELECT * from $Table"
            }
            else {
                $Query = "SELECT name FROM sqlite_master WHERE type = 'table'"
            }
            $Results = Invoke-SqliteQuery -Datasource $Path -Query $Query
            $Results
        }
        else {
            Write-Warning 'Unable to find cmdlet Invoke-SqliteQuery. Install-Module PSSQLite'
        }
    }
    else {
        Write-Warning "Unable to find $Path"
    }
}