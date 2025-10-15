# Script to categorize Tanium packages into Deploy, Admin, Archive, and Platform categories
$repoRoot = 'D:\Dev\MyGithubRepos\tanium-powershell'

# Category 1: Active Deploy Packages (current software installation)
$activeDeployPatterns = @(
    '*Install-ClicktoRunOffice*.ps1'
)

# Category 2: Obsolete Deploy Packages (archive)
$obsoleteDeployPatterns = @(
    '*Invoke-Win10Upgrade*.ps1'  # Windows 10 is EOL Oct 2025, upgrades obsolete
)

# Category 3: Tanium Client Administration (can't run from within Tanium)
$adminPatterns = @(
    '*TaniumClientDeploy*.ps1',
    '*TaniumClientPatch*.ps1'
)

Write-Host "`n=== ACTIVE DEPLOY PACKAGES (Software Installation) ===" -ForegroundColor Green
$activeDeployScripts = @()
foreach ($pattern in $activeDeployPatterns) {
    $found = Get-ChildItem -Path "$repoRoot\Packages" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
    $activeDeployScripts += $found
}
$activeDeployScripts = $activeDeployScripts | Select-Object -Unique | Sort-Object FullName
Write-Host "Found $($activeDeployScripts.Count) active Deploy Package scripts:"
foreach ($script in $activeDeployScripts) {
    $relativePath = $script.FullName.Replace("$repoRoot\", "")
    Write-Host "  $relativePath"
}

Write-Host "`n=== OBSOLETE DEPLOY PACKAGES (Archive) ===" -ForegroundColor Magenta
$obsoleteDeployScripts = @()
foreach ($pattern in $obsoleteDeployPatterns) {
    $found = Get-ChildItem -Path "$repoRoot\Packages" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
    $obsoleteDeployScripts += $found
}
$obsoleteDeployScripts = $obsoleteDeployScripts | Select-Object -Unique | Sort-Object FullName
Write-Host "Found $($obsoleteDeployScripts.Count) obsolete Deploy Package scripts:"
foreach ($script in $obsoleteDeployScripts) {
    $relativePath = $script.FullName.Replace("$repoRoot\", "")
    Write-Host "  $relativePath (Reason: Windows 10 EOL Oct 2025)"
}

Write-Host "`n=== ADMIN PACKAGES (Tanium Client Administration) ===" -ForegroundColor Yellow
$adminScripts = @()
foreach ($pattern in $adminPatterns) {
    $found = Get-ChildItem -Path "$repoRoot\Packages" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
    $adminScripts += $found
}
$adminScripts = $adminScripts | Select-Object -Unique | Sort-Object FullName
Write-Host "Found $($adminScripts.Count) Admin scripts:"
foreach ($script in $adminScripts) {
    $relativePath = $script.FullName.Replace("$repoRoot\", "")
    Write-Host "  $relativePath"
}

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Active Deploy Packages: $($activeDeployScripts.Count)"
Write-Host "Obsolete Deploy Packages: $($obsoleteDeployScripts.Count)"
Write-Host "Admin Packages: $($adminScripts.Count)"
Write-Host "Platform Packages: (remaining scripts in Packages/)"

Write-Host "`n=== PROPOSED DIRECTORY STRUCTURE ===" -ForegroundColor Cyan
Write-Host "tanium-powershell/"
Write-Host "├── Sensors/                    (data collection, <1000ms)"
Write-Host "├── Packages/                   (platform packages - state changes)"
Write-Host "├── Deploy-Packages/            (active software installation)"
Write-Host "├── Admin/                      (Tanium Client administration)"
Write-Host "├── Archive/"
Write-Host "│   └── Deploy-Packages/        (obsolete deployment packages)"
Write-Host "└── Modules/"
