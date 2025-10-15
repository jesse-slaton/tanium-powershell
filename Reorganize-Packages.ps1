# Script to reorganize Tanium packages into proper directory structure
$repoRoot = 'D:\Dev\MyGithubRepos\tanium-powershell'

# Active Deploy Packages
$activeDeployScripts = @(
    'Packages\Software\Install-ClicktoRunOffice-NoVisioOrProject-Package.ps1',
    'Packages\Software\Install-ClicktoRunOffice-Package.ps1'
)

# Obsolete Deploy Packages
$obsoleteDeployScripts = @(
    'Packages\Network\Invoke-Win10Upgrade-Package.ps1'
)

# Admin Packages (Tanium Client administration)
$adminPatterns = @('*TaniumClientDeploy*.ps1', '*TaniumClientPatch*.ps1')

Write-Host "`n=== MOVING ADMIN SCRIPTS ===" -ForegroundColor Yellow
$adminScripts = @()
foreach ($pattern in $adminPatterns) {
    $found = Get-ChildItem -Path "$repoRoot\Packages" -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
    $adminScripts += $found
}

$movedCount = 0
foreach ($script in $adminScripts) {
    $relativePath = $script.FullName.Replace("$repoRoot\Packages\", "")
    $targetPath = Join-Path "$repoRoot\Admin" $relativePath
    $targetDir = Split-Path $targetPath -Parent

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }

    Move-Item -Path $script.FullName -Destination $targetPath -Force
    Write-Host "  Moved: $relativePath"
    $movedCount++
}
Write-Host "Moved $movedCount admin scripts to Admin/" -ForegroundColor Green

Write-Host "`n=== MOVING ACTIVE DEPLOY SCRIPTS ===" -ForegroundColor Green
$movedCount = 0
foreach ($scriptPath in $activeDeployScripts) {
    $fullPath = Join-Path $repoRoot $scriptPath
    if (Test-Path $fullPath) {
        $fileName = Split-Path $scriptPath -Leaf
        $targetPath = Join-Path "$repoRoot\Deploy-Packages" $fileName

        Move-Item -Path $fullPath -Destination $targetPath -Force
        Write-Host "  Moved: $fileName"
        $movedCount++
    }
}
Write-Host "Moved $movedCount active deploy scripts to Deploy-Packages/" -ForegroundColor Green

Write-Host "`n=== MOVING OBSOLETE DEPLOY SCRIPTS ===" -ForegroundColor Magenta
$movedCount = 0
foreach ($scriptPath in $obsoleteDeployScripts) {
    $fullPath = Join-Path $repoRoot $scriptPath
    if (Test-Path $fullPath) {
        $fileName = Split-Path $scriptPath -Leaf
        $packageName = $fileName -replace '-Package\.ps1$', ''
        $targetDir = Join-Path "$repoRoot\Archive\Deploy-Packages" $packageName

        if (-not (Test-Path $targetDir)) {
            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        }

        $targetPath = Join-Path $targetDir $fileName
        Move-Item -Path $fullPath -Destination $targetPath -Force
        Write-Host "  Archived: $fileName -> Archive/Deploy-Packages/$packageName/"
        $movedCount++
    }
}
Write-Host "Archived $movedCount obsolete deploy scripts" -ForegroundColor Green

Write-Host "`n=== CLEANUP EMPTY DIRECTORIES ===" -ForegroundColor Cyan
Get-ChildItem -Path "$repoRoot\Packages" -Recurse -Directory |
    Where-Object { (Get-ChildItem $_.FullName -File -Recurse).Count -eq 0 } |
    Sort-Object -Property FullName -Descending |
    ForEach-Object {
        $relativePath = $_.FullName.Replace($repoRoot + '\', '')
        Write-Host "  Removing empty: $relativePath"
        Remove-Item $_.FullName -Force
    }

Write-Host "`n=== REORGANIZATION COMPLETE ===" -ForegroundColor Green
