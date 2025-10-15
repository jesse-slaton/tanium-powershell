# Script to identify software deployment packages
$repoRoot = 'D:\Dev\MyGithubRepos\tanium-powershell'

$deployPatterns = @(
    '*Install*.ps1',
    '*Remove*.ps1',
    '*Uninstall*.ps1',
    '*Update*.ps1',
    '*Upgrade*.ps1',
    '*Deploy*.ps1',
    '*Extract*.ps1',
    'Remove_All_Versions*.ps1'
)

$deployScripts = @()

foreach ($pattern in $deployPatterns) {
    $found = Get-ChildItem -Path "$repoRoot\Packages" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
    $deployScripts += $found
}

# Remove duplicates and sort
$deployScripts = $deployScripts | Select-Object -Unique | Sort-Object FullName

Write-Host "Found $($deployScripts.Count) potential Deploy Package scripts:" -ForegroundColor Cyan
Write-Host ""

foreach ($script in $deployScripts) {
    $relativePath = $script.FullName.Replace("$repoRoot\", "")
    Write-Host $relativePath
}
