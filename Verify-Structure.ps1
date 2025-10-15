$repoRoot = 'D:\Dev\MyGithubRepos\tanium-powershell'

Write-Host "`n=== DIRECTORY STRUCTURE ===" -ForegroundColor Cyan

$directories = @('Sensors', 'Packages', 'Deploy-Packages', 'Admin', 'Archive', 'Modules')

foreach ($dir in $directories) {
    $path = Join-Path $repoRoot $dir
    if (Test-Path $path) {
        $scriptCount = (Get-ChildItem -Path $path -Filter '*.ps1' -Recurse -File | Measure-Object).Count
        Write-Host "$dir/ - $scriptCount scripts" -ForegroundColor Green
    } else {
        Write-Host "$dir/ - Not found" -ForegroundColor Red
    }
}

Write-Host "`n=== DETAILED COUNTS ===" -ForegroundColor Cyan
Write-Host "Admin/: $(Get-ChildItem -Path "$repoRoot\Admin" -Filter '*.ps1' -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count) scripts"
Write-Host "Deploy-Packages/: $(Get-ChildItem -Path "$repoRoot\Deploy-Packages" -Filter '*.ps1' -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count) scripts"
Write-Host "Archive/Deploy-Packages/: $(Get-ChildItem -Path "$repoRoot\Archive\Deploy-Packages" -Filter '*.ps1' -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count) scripts"
Write-Host "Packages/: $(Get-ChildItem -Path "$repoRoot\Packages" -Filter '*.ps1' -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count) scripts (Platform Packages)"
Write-Host "Sensors/: $(Get-ChildItem -Path "$repoRoot\Sensors" -Filter '*.ps1' -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count) scripts"
