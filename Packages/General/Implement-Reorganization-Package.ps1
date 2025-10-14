# NOTE: Requires external repo at D:\dev\repos\Windows-Secure-Host-Baseline
# Original repo: https://git.example.com/sydlexius/Windows-Secure-Host-Baseline.git

# NOTE: Requires external repo at D:\dev\repos\Port_Authority
# Original repo: https://github.com/ACK-J/Port_Authority.git

# NOTE: Requires external repo at D:\dev\repos\LidarrPS
# Original repo: https://git.example.com/sydlexius/LidarrPS.git

#Requires -Version 5.1
<#
.SYNOPSIS
    Automates the reorganization of PowerShell scripts into separate Tanium and Utilities repositories

.DESCRIPTION
    This orchestration script reads the inventory and analysis artifacts to:
    1. Create GitHub repositories for Tanium and Utilities
    2. Handle external repository dependencies
    3. Organize scripts into logical directory structures
    4. Apply naming conventions from RENAME_PLAN.csv
    5. Create test stubs and documentation
    6. Commit and push to GitHub

    The script is designed to be idempotent and can be run with -WhatIf to preview changes.

.PARAMETER SourcePath
    Path to current script location (default: current directory)

.PARAMETER TargetPath
    Path where repos/ folder will be created (default: .\repos)

.PARAMETER ExternalReposPath
    Path where external repos will be moved (default: D:\dev\repos)

.PARAMETER TaniumRepoName
    Name for Tanium repository (default: tanium-powershell)

.PARAMETER UtilitiesRepoName
    Name for utilities repository (default: powershell-utilities)

.PARAMETER GitHubUsername
    GitHub username for repository creation

.PARAMETER WhatIf
    Preview mode - shows what would be done without making changes

.PARAMETER SkipGitPush
    Create repos but don't push to GitHub

.PARAMETER SkipExternalMove
    Don't move external repos, just document them

.EXAMPLE
    .\Implement-Reorganization.ps1 -GitHubUsername "myusername" -WhatIf

.EXAMPLE
    .\Implement-Reorganization.ps1 -GitHubUsername "myusername" -SkipGitPush

.EXAMPLE
    .\Implement-Reorganization.ps1 -GitHubUsername "myusername" -ExternalReposPath "E:\External"
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string]$SourcePath = (Get-Location).Path,

    [Parameter()]
    [string]$TargetPath = (Join-Path (Get-Location).Path "repos"),

    [Parameter()]
    [string]$ExternalReposPath = "D:\dev\repos",

    [Parameter()]
    [string]$TaniumRepoName = "tanium-powershell",

    [Parameter()]
    [string]$UtilitiesRepoName = "powershell-utilities",

    [Parameter(Mandatory)]
    [string]$GitHubUsername,

    [Parameter()]
    [switch]$SkipGitPush,

    [Parameter()]
    [switch]$SkipExternalMove
)

$ErrorActionPreference = 'Stop'
$script:LogFile = Join-Path $SourcePath "Reorganization-Log.txt"
$script:StartTime = Get-Date

# Statistics tracking
$script:Stats = @{
    FilesProcessed = 0
    FilesRenamed = 0
    TestStubsCreated = 0
    DocStubsCreated = 0
    ExternalReposMoved = 0
    ErrorsEncountered = 0
    Warnings = 0
    TaniumSensors = 0
    TaniumPackages = 0
    GeneralUtilities = 0
    NeedsReview = 0
}

#region Helper Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to log file
    $logMessage | Out-File -FilePath $script:LogFile -Append -Encoding UTF8

    # Write to console with colors
    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        default   { 'Cyan' }
    }

    Write-Host $logMessage -ForegroundColor $color
}

function Test-GitHubCLI {
    try {
        $null = gh --version
        Write-Log "GitHub CLI (gh) is available" -Level Success
        return $true
    }
    catch {
        Write-Log "GitHub CLI (gh) not found. Please install: https://cli.github.com/" -Level Error
        return $false
    }
}

function Test-GitInstalled {
    try {
        $null = git --version
        Write-Log "Git is available" -Level Success
        return $true
    }
    catch {
        Write-Log "Git not found. Please install Git first." -Level Error
        return $false
    }
}

function Get-CategoryFolder {
    param([string]$FilePath)

    # Infer category from file path
    if ($FilePath -match 'Registry|reg-') { return 'Registry' }
    if ($FilePath -match 'FileSystem|File|Disk|Drive') { return 'FileSystem' }
    if ($FilePath -match 'Network|IP|DNS|DHCP|Adapter') { return 'Network' }
    if ($FilePath -match 'System|OS|Hardware|CPU|Memory') { return 'System' }
    if ($FilePath -match 'Software|Application|Install|Package') { return 'Software' }
    if ($FilePath -match 'Security|BitLocker|Compliance|Cert') { return 'Security' }
    if ($FilePath -match 'ActiveDirectory|AD|User|Group|Computer') { return 'ActiveDirectory' }
    if ($FilePath -match 'Office|Excel|Outlook|Word') { return 'Office' }

    return 'General'
}

function New-TestStub {
    param(
        [string]$ScriptName,
        [string]$OutputPath
    )

    $testContent = @"
#Requires -Version 5.1
# Pester tests for $ScriptName

BeforeAll {
    `$scriptPath = `$PSScriptRoot.Replace('\Tests', '')
    . (Join-Path `$scriptPath '$ScriptName')
}

Describe "$ScriptName Tests" {
    Context "Script Loading" {
        It "Should load without errors" {
            { . (Join-Path `$PSScriptRoot.Replace('\Tests', '') '$ScriptName') } | Should -Not -Throw
        }
    }

    Context "TODO: Add Functional Tests" {
        It "TODO: Test main functionality" {
            `$true | Should -Be `$true
        }

        It "TODO: Test error handling" {
            `$true | Should -Be `$true
        }

        It "TODO: Test parameter validation" {
            `$true | Should -Be `$true
        }
    }

    Context "TODO: Add Output Tests" {
        It "TODO: Verify output format" {
            `$true | Should -Be `$true
        }
    }
}
"@

    if ($PSCmdlet.ShouldProcess($OutputPath, "Create test stub")) {
        $testContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        Write-Log "Created test stub: $OutputPath" -Level Success
        $script:Stats.TestStubsCreated++
    }
}

function New-DocStub {
    param(
        [string]$ScriptName,
        [string]$OutputPath,
        [string]$Synopsis = "TODO: Add synopsis"
    )

    $docContent = @"
# $ScriptName

## Status

Repository: **[Tanium/Utilities]**
Last Updated: $(Get-Date -Format 'yyyy-MM-dd')

## Synopsis

$Synopsis

## Description

TODO: Add detailed description

## Parameters

TODO: Document parameters

## Examples

TODO: Add usage examples

## Notes

TODO: Add any special notes

## Checklist

- [ ] Comment-based help complete
- [ ] WhatIf support implemented (if state-changing)
- [ ] Pester tests written
- [ ] Cross-version tested (PS 5.1 and 7.x)
- [ ] No hardcoded credentials
- [ ] No hardcoded paths
- [ ] Error handling implemented
- [ ] Output format documented
- [ ] Dependencies documented

## See Also

- DEV_ENVIRONMENT.md for development guidelines
- TANIUM_NAMING_CONVENTION.md for naming standards
"@

    if ($PSCmdlet.ShouldProcess($OutputPath, "Create documentation stub")) {
        $docContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        Write-Log "Created doc stub: $OutputPath" -Level Success
        $script:Stats.DocStubsCreated++
    }
}

function New-GitIgnore {
    param([string]$RepoPath)

    $gitignoreContent = @"
# PowerShell
*.ps1xml
pester-tests.xml

# Build artifacts
bin/
obj/
*.dll
*.exe

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
~`$*

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini
`$RECYCLE.BIN/

# VS Code
.vscode/settings.json
*.code-workspace

# Credentials and secrets
*credential*
*password*
*secret*
*.pfx
*.p12
*.key

# Test results
TestResults.xml
coverage.xml

# Module cache
PSGetModuleInfo.xml
"@

    $gitignorePath = Join-Path $RepoPath ".gitignore"
    if ($PSCmdlet.ShouldProcess($gitignorePath, "Create .gitignore")) {
        $gitignoreContent | Out-File -FilePath $gitignorePath -Encoding UTF8 -Force
        Write-Log "Created .gitignore: $gitignorePath" -Level Success
    }
}

function New-RepositoryReadme {
    param(
        [string]$RepoPath,
        [string]$RepoName,
        [string]$Purpose
    )

    $readmeContent = @"
# $RepoName

## Status

🚧 **Initial import - reorganization in progress** 🚧

This repository was created from a reorganization of a monolithic PowerShell script collection.
Scripts are being refactored and improved according to the standards in DEV_ENVIRONMENT.md.

## Purpose

$Purpose

## Current State

- ✅ Initial import complete
- 🔄 Refactoring in progress
- ⏳ Documentation being added
- ⏳ Tests being written

## Structure

``````
$RepoName/
  Sensors/       # Read-only data collection scripts
  Packages/      # State-changing deployment scripts
  Shared/        # Dual-use scripts
  Modules/       # PowerShell modules
  Tests/         # Pester tests
  docs/          # Documentation
  Templates/     # Script templates
``````

## Getting Started

See [DEV_ENVIRONMENT.md](./DEV_ENVIRONMENT.md) for:
- Required tools (PowerShell, PSScriptAnalyzer, Pester)
- VS Code setup
- Git hooks configuration
- Development workflow

## Contributing

1. Follow the naming conventions in ``docs/TANIUM_NAMING_CONVENTION.md``
2. Write tests for all new scripts
3. Add comment-based help to all functions
4. Run PSScriptAnalyzer before committing
5. Create feature branches for changes

## Documentation

- [DEV_ENVIRONMENT.md](./DEV_ENVIRONMENT.md) - Development environment setup
- [docs/MODULE_OPPORTUNITIES.md](./docs/MODULE_OPPORTUNITIES.md) - Module consolidation plans
- [docs/EXTERNAL_DEPENDENCIES.md](./docs/EXTERNAL_DEPENDENCIES.md) - External dependencies

## Next Steps

See the ``refactoring`` branch for ongoing improvements:
1. Add help documentation to all scripts
2. Implement WhatIf support for state-changing scripts
3. Write Pester tests
4. Consolidate related scripts into modules
5. Remove VBScript dependencies

---

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Baseline: v0.1-baseline
"@

    $readmePath = Join-Path $RepoPath "README.md"
    if ($PSCmdlet.ShouldProcess($readmePath, "Create README.md")) {
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8 -Force
        Write-Log "Created README.md: $readmePath" -Level Success
    }
}

#endregion

#region Stage 1: GitHub Repository Setup

function Initialize-GitHubRepositories {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 1: GitHub Repository Setup" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Log "Starting GitHub repository initialization"

    # Verify prerequisites
    if (-not (Test-GitHubCLI)) { throw "GitHub CLI required" }
    if (-not (Test-GitInstalled)) { throw "Git required" }

    $repos = @(
        @{
            Name = $TaniumRepoName
            Path = Join-Path $TargetPath $TaniumRepoName
            Purpose = "PowerShell sensors and packages for Tanium endpoint management platform"
        },
        @{
            Name = $UtilitiesRepoName
            Path = Join-Path $TargetPath $UtilitiesRepoName
            Purpose = "General-purpose PowerShell utilities for system administration"
        }
    )

    foreach ($repo in $repos) {
        Write-Log "Processing repository: $($repo.Name)"

        # Check if repo exists on GitHub
        $repoExists = $false
        try {
            $null = gh repo view "$GitHubUsername/$($repo.Name)" 2>&1
            $repoExists = $true
            Write-Log "Repository $($repo.Name) already exists on GitHub" -Level Warning
            $script:Stats.Warnings++
        }
        catch {
            Write-Log "Repository $($repo.Name) does not exist, will create"
        }

        # Create repo on GitHub if it doesn't exist
        if (-not $repoExists) {
            if ($PSCmdlet.ShouldProcess("$GitHubUsername/$($repo.Name)", "Create GitHub repository")) {
                try {
                    Write-Log "Creating GitHub repository: $($repo.Name)"
                    $result = gh repo create "$GitHubUsername/$($repo.Name)" --private --description $repo.Purpose
                    Write-Log "Repository created: $($repo.Name)" -Level Success
                }
                catch {
                    Write-Log "Failed to create repository $($repo.Name): $_" -Level Error
                    $script:Stats.ErrorsEncountered++
                    continue
                }
            }
        }

        # Create local directory
        if (-not (Test-Path $repo.Path)) {
            if ($PSCmdlet.ShouldProcess($repo.Path, "Create directory")) {
                New-Item -Path $repo.Path -ItemType Directory -Force | Out-Null
                Write-Log "Created directory: $($repo.Path)" -Level Success
            }
        }

        # Initialize Git repo locally if not already
        $gitDir = Join-Path $repo.Path ".git"
        if (-not (Test-Path $gitDir)) {
            if ($PSCmdlet.ShouldProcess($repo.Path, "Initialize Git repository")) {
                Push-Location $repo.Path
                try {
                    git init
                    git branch -M main
                    git remote add origin "https://github.com/$GitHubUsername/$($repo.Name).git"
                    Write-Log "Initialized Git repository: $($repo.Path)" -Level Success
                }
                catch {
                    Write-Log "Failed to initialize Git repo: $_" -Level Error
                    $script:Stats.ErrorsEncountered++
                }
                finally {
                    Pop-Location
                }
            }
        }

        # Create .gitignore
        New-GitIgnore -RepoPath $repo.Path

        # Create README.md
        New-RepositoryReadme -RepoPath $repo.Path -RepoName $repo.Name -Purpose $repo.Purpose
    }
}

#endregion

#region Stage 1.5: External Repository Handling

function Move-ExternalRepositories {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 1.5: External Repository Handling" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    if ($SkipExternalMove) {
        Write-Log "Skipping external repository moves (SkipExternalMove specified)" -Level Warning
        return
    }

    Write-Log "Searching for external repositories in $SourcePath"

    # Find all directories with .git folders
    $gitDirs = Get-ChildItem -Path $SourcePath -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName ".git") } |
        Where-Object { $_.FullName -notmatch 'repos\\' }  # Don't process already moved repos

    Write-Log "Found $($gitDirs.Count) Git repositories"

    $externalRepos = @()

    foreach ($gitDir in $gitDirs) {
        Push-Location $gitDir.FullName
        try {
            # Get remote origin URL
            $originUrl = git remote get-url origin 2>$null

            if ($originUrl) {
                # Check if it's an external repo (not owned by current user)
                $isExternal = $originUrl -notmatch $GitHubUsername

                if ($isExternal) {
                    $repoInfo = [PSCustomObject]@{
                        Name = $gitDir.Name
                        OriginalPath = $gitDir.FullName
                        NewPath = Join-Path $ExternalReposPath $gitDir.Name
                        OriginUrl = $originUrl
                        DependentScripts = @()
                    }

                    # Find scripts that reference this repo
                    $allScripts = Get-ChildItem -Path $SourcePath -Include *.ps1,*.psm1 -Recurse -File
                    foreach ($script in $allScripts) {
                        $content = Get-Content $script.FullName -Raw -ErrorAction SilentlyContinue
                        if ($content -match [regex]::Escape($gitDir.Name)) {
                            $repoInfo.DependentScripts += $script.FullName.Replace($SourcePath, '').TrimStart('\')
                        }
                    }

                    $externalRepos += $repoInfo

                    Write-Log "Found external repo: $($gitDir.Name) from $originUrl"
                }
            }
        }
        catch {
            Write-Log "Error processing Git directory $($gitDir.FullName): $_" -Level Warning
            $script:Stats.Warnings++
        }
        finally {
            Pop-Location
        }
    }

    if ($externalRepos.Count -eq 0) {
        Write-Log "No external repositories found" -Level Info
        return
    }

    Write-Log "Found $($externalRepos.Count) external repositories to move"

    # Create external repos directory
    if (-not (Test-Path $ExternalReposPath)) {
        if ($PSCmdlet.ShouldProcess($ExternalReposPath, "Create external repos directory")) {
            New-Item -Path $ExternalReposPath -ItemType Directory -Force | Out-Null
            Write-Log "Created external repos directory: $ExternalReposPath" -Level Success
        }
    }

    # Move each external repo
    foreach ($repo in $externalRepos) {
        if (Test-Path $repo.NewPath) {
            Write-Log "Target already exists, skipping: $($repo.NewPath)" -Level Warning
            $script:Stats.Warnings++
            continue
        }

        if ($PSCmdlet.ShouldProcess($repo.OriginalPath, "Move to $($repo.NewPath)")) {
            try {
                Move-Item -Path $repo.OriginalPath -Destination $repo.NewPath -Force
                Write-Log "Moved external repo: $($repo.Name)" -Level Success
                $script:Stats.ExternalReposMoved++

                # Update dependent scripts
                foreach ($scriptPath in $repo.DependentScripts) {
                    $fullScriptPath = Join-Path $SourcePath $scriptPath
                    if (Test-Path $fullScriptPath) {
                        $content = Get-Content $fullScriptPath -Raw
                        $updatedContent = "# NOTE: Requires external repo at $($repo.NewPath)`n# Original repo: $($repo.OriginUrl)`n`n" + $content
                        $updatedContent | Out-File -FilePath $fullScriptPath -Encoding UTF8 -Force
                        Write-Log "Updated script with external dependency: $scriptPath"
                    }
                }
            }
            catch {
                Write-Log "Failed to move external repo $($repo.Name): $_" -Level Error
                $script:Stats.ErrorsEncountered++
            }
        }
    }

    # Create EXTERNAL_REPOS_MOVED.txt
    if ($externalRepos.Count -gt 0) {
        $reportPath = Join-Path $SourcePath "EXTERNAL_REPOS_MOVED.txt"
        if ($PSCmdlet.ShouldProcess($reportPath, "Create external repos report")) {
            $reportContent = @"
External Repositories Moved
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

This file documents external Git repositories that were moved during reorganization.

ACTION ITEMS:
1. Fork these repositories to your GitHub account
2. Star the original repositories
3. Document any local modifications

$(foreach ($repo in $externalRepos) {
@"

----------------------------------------
Repository: $($repo.Name)
Original Location: $($repo.OriginalPath)
New Location: $($repo.NewPath)
Origin URL: $($repo.OriginUrl)

Dependent Scripts:
$(if ($repo.DependentScripts.Count -gt 0) {
    ($repo.DependentScripts | ForEach-Object { "  - $_" }) -join "`n"
} else {
    "  (None found)"
})

TODO:
[ ] Fork to https://github.com/$GitHubUsername/$($repo.Name)
[ ] Star original repo
[ ] Document local modifications (if any)
[ ] Update dependent scripts to reference new location
"@
})
"@
            $reportContent | Out-File -FilePath $reportPath -Encoding UTF8 -Force
            Write-Log "Created external repos report: $reportPath" -Level Success
        }
    }
}

#endregion

#region Stage 2: Directory Structure Creation

function New-DirectoryStructure {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 2: Directory Structure Creation" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Log "Creating directory structures"

    $taniumPath = Join-Path $TargetPath $TaniumRepoName
    $utilitiesPath = Join-Path $TargetPath $UtilitiesRepoName

    # Tanium repository structure
    $taniumDirs = @(
        "Sensors\Registry",
        "Sensors\FileSystem",
        "Sensors\Network",
        "Sensors\System",
        "Sensors\Software",
        "Sensors\Security",
        "Sensors\ActiveDirectory",
        "Sensors\General",
        "Packages\Registry",
        "Packages\FileSystem",
        "Packages\Network",
        "Packages\System",
        "Packages\Software",
        "Packages\Security",
        "Packages\ActiveDirectory",
        "Packages\Office",
        "Packages\General",
        "Shared",
        "Modules",
        "Tests\Unit",
        "Tests\Integration",
        "docs",
        "Templates"
    )

    foreach ($dir in $taniumDirs) {
        $fullPath = Join-Path $taniumPath $dir
        if (-not (Test-Path $fullPath)) {
            if ($PSCmdlet.ShouldProcess($fullPath, "Create directory")) {
                New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
                Write-Log "Created: $dir"
            }
        }
    }

    # Utilities repository structure
    $utilityDirs = @(
        "Modules",
        "Scripts\ActiveDirectory",
        "Scripts\FileSystem",
        "Scripts\Network",
        "Scripts\System",
        "Scripts\Security",
        "Scripts\Office",
        "Scripts\Development",
        "Scripts\General",
        "Tests\Unit",
        "Tests\Integration",
        "docs"
    )

    foreach ($dir in $utilityDirs) {
        $fullPath = Join-Path $utilitiesPath $dir
        if (-not (Test-Path $fullPath)) {
            if ($PSCmdlet.ShouldProcess($fullPath, "Create directory")) {
                New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
                Write-Log "Created: $dir"
            }
        }
    }

    Write-Log "Directory structures created" -Level Success
}

#endregion

#region Stage 3: File Distribution

function Copy-ScriptsToRepositories {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 3: File Distribution" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Log "Starting file distribution"

    # Load inventory
    $inventoryCsv = Join-Path $SourcePath "INVENTORY.csv"
    if (-not (Test-Path $inventoryCsv)) {
        Write-Log "INVENTORY.csv not found at $inventoryCsv" -Level Error
        throw "INVENTORY.csv required"
    }

    $inventory = Import-Csv -Path $inventoryCsv
    Write-Log "Loaded inventory: $($inventory.Count) files"

    # Load rename plan
    $renamePlanCsv = Join-Path $SourcePath "RENAME_PLAN.csv"
    $renamePlan = @{}
    if (Test-Path $renamePlanCsv) {
        $renameData = Import-Csv -Path $renamePlanCsv
        foreach ($item in $renameData) {
            if ($item.NeedsRename -eq 'Yes') {
                $renamePlan[$item.CurrentName] = $item.ProposedName
            }
        }
        Write-Log "Loaded rename plan: $($renamePlan.Count) renames"
    }

    $taniumPath = Join-Path $TargetPath $TaniumRepoName
    $utilitiesPath = Join-Path $TargetPath $UtilitiesRepoName

    $progress = 0
    $total = $inventory.Count

    foreach ($item in $inventory) {
        $progress++
        $percentComplete = ($progress / $total) * 100

        Write-Progress -Activity "Distributing files" -Status "Processing $($item.FileName)" -PercentComplete $percentComplete

        try{
            # Determine target repository and folder
            $targetRepo = $null
            $subFolder = $null

            switch ($item.Recommendation) {
                'Tanium-Sensor' {
                    $targetRepo = $taniumPath
                    $category = Get-CategoryFolder -FilePath $item.FilePath
                    $subFolder = "Sensors\$category"
                    $script:Stats.TaniumSensors++
                }
                'Tanium-Package' {
                    $targetRepo = $taniumPath
                    $category = Get-CategoryFolder -FilePath $item.FilePath
                    $subFolder = "Packages\$category"
                    $script:Stats.TaniumPackages++
                }
                'General-Utility' {
                    $targetRepo = $utilitiesPath
                    $category = Get-CategoryFolder -FilePath $item.FilePath
                    $subFolder = "Scripts\$category"
                    $script:Stats.GeneralUtilities++
                }
                'Needs-Review' {
                    Write-Log "Skipping (needs review): $($item.FilePath)" -Level Warning
                    $script:Stats.NeedsReview++
                    continue
                }
                'Module' {
                    # Handle modules separately
                    $targetRepo = if ($item.TaniumIndicators) { $taniumPath } else { $utilitiesPath }
                    $subFolder = "Modules"
                }
                default {
                    # Default to utilities
                    $targetRepo = $utilitiesPath
                    $subFolder = "Scripts\General"
                }
            }

            if (-not $targetRepo) { continue }

            # Build source and target paths
            $sourceFilePath = Join-Path $SourcePath $item.FilePath
            if (-not (Test-Path $sourceFilePath)) {
                Write-Log "Source file not found: $sourceFilePath" -Level Warning
                $script:Stats.Warnings++
                continue
            }

            # Apply rename if applicable
            $targetFileName = $item.FileName
            if ($renamePlan.ContainsKey($item.FileName)) {
                $targetFileName = $renamePlan[$item.FileName]
                $script:Stats.FilesRenamed++
            }

            $targetFolder = Join-Path $targetRepo $subFolder
            $targetPath = Join-Path $targetFolder $targetFileName

            # Copy file
            if ($PSCmdlet.ShouldProcess($targetPath, "Copy file")) {
                Copy-Item -Path $sourceFilePath -Destination $targetPath -Force

                # Preserve timestamps
                $sourceItem = Get-Item $sourceFilePath
                $targetItem = Get-Item $targetPath
                $targetItem.LastWriteTime = $sourceItem.LastWriteTime
                $targetItem.CreationTime = $sourceItem.CreationTime

                Write-Log "Copied: $($item.FileName) -> $subFolder\$targetFileName"
                $script:Stats.FilesProcessed++
            }

        }
        catch {
            Write-Log "Error processing $($item.FileName): $_" -Level Error
            $script:Stats.ErrorsEncountered++
        }
    }

    Write-Progress -Activity "Distributing files" -Completed
    Write-Log "File distribution complete" -Level Success
}

#endregion

#region Stage 4: Supporting Files Creation

function New-SupportingFiles {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 4: Supporting Files Creation" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Log "Creating test and documentation stubs"

    $taniumPath = Join-Path $TargetPath $TaniumRepoName
    $utilitiesPath = Join-Path $TargetPath $UtilitiesRepoName

    # Process both repositories
    foreach ($repoPath in @($taniumPath, $utilitiesPath)) {
        $scripts = Get-ChildItem -Path $repoPath -Include *.ps1 -Recurse -File | Where-Object { $_.DirectoryName -notmatch '\\Tests\\' }

        Write-Log "Processing $($scripts.Count) scripts in $(Split-Path $repoPath -Leaf)"

        foreach ($script in $scripts) {
            $scriptName = $script.Name
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)

            # Create test stub if not exists
            $testFileName = "$baseName.Tests.ps1"
            $testPath = Join-Path (Join-Path $repoPath "Tests\Unit") $testFileName

            if (-not (Test-Path $testPath)) {
                New-TestStub -ScriptName $scriptName -OutputPath $testPath
            }

            # Create documentation stub
            $docFileName = "$baseName.md"
            $docPath = Join-Path (Join-Path $repoPath "docs") $docFileName

            if (-not (Test-Path $docPath)) {
                # Try to extract synopsis from script
                $content = Get-Content $script.FullName -Raw
                $synopsis = "TODO: Add synopsis"
                if ($content -match '\.SYNOPSIS\s+(.*?)(?=\s*\.|#>)') {
                    $synopsis = $Matches[1].Trim() -replace '\s+', ' '
                }

                New-DocStub -ScriptName $scriptName -OutputPath $docPath -Synopsis $synopsis
            }
        }
    }

    Write-Log "Supporting files creation complete" -Level Success
}

#endregion

#region Stage 5: Documentation Files

function Copy-DocumentationFiles {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 5: Documentation Files" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Log "Copying documentation artifacts"

    $taniumPath = Join-Path $TargetPath $TaniumRepoName
    $utilitiesPath = Join-Path $TargetPath $UtilitiesRepoName

    # Tanium repository docs
    $taniumDocs = @(
        "TANIUM_CANDIDATES.md",
        "TANIUM_NAMING_CONVENTION.md",
        "TANIUM_RENAME_SUMMARY.md",
        "MODULE_OPPORTUNITIES.md",
        "EXTERNAL_DEPENDENCIES.md",
        "DEV_ENVIRONMENT.md",
        "CLEANUP_CANDIDATES.md"
    )

    foreach ($doc in $taniumDocs) {
        $sourcePath = Join-Path $SourcePath $doc
        if (Test-Path $sourcePath) {
            $targetPath = Join-Path (Join-Path $taniumPath "docs") $doc
            if ($PSCmdlet.ShouldProcess($targetPath, "Copy documentation")) {
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
                Write-Log "Copied to Tanium repo: $doc"
            }
        }
    }

    # Utilities repository docs
    $utilityDocs = @(
        "GENERAL_UTILITIES.md",
        "MODULE_OPPORTUNITIES.md",
        "EXTERNAL_DEPENDENCIES.md",
        "DEV_ENVIRONMENT.md",
        "CLEANUP_CANDIDATES.md"
    )

    foreach ($doc in $utilityDocs) {
        $sourcePath = Join-Path $SourcePath $doc
        if (Test-Path $sourcePath) {
            $targetPath = Join-Path (Join-Path $utilitiesPath "docs") $doc
            if ($PSCmdlet.ShouldProcess($targetPath, "Copy documentation")) {
                Copy-Item -Path $sourcePath -Destination $targetPath -Force
                Write-Log "Copied to Utilities repo: $doc"
            }
        }
    }

    # Copy PSScriptAnalyzer settings
    $analyzerSettings = Join-Path $SourcePath ".PSScriptAnalyzerSettings.psd1"
    if (Test-Path $analyzerSettings) {
        foreach ($repoPath in @($taniumPath, $utilitiesPath)) {
            $targetPath = Join-Path $repoPath ".PSScriptAnalyzerSettings.psd1"
            if ($PSCmdlet.ShouldProcess($targetPath, "Copy PSScriptAnalyzer settings")) {
                Copy-Item -Path $analyzerSettings -Destination $targetPath -Force
            }
        }
    }

    Write-Log "Documentation files copied" -Level Success
}

#endregion

#region Stage 6: External Dependencies Handling

function Update-ExternalDependencies {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 6: External Dependencies Handling" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Log "Processing external dependencies"

    $taniumPath = Join-Path $TargetPath $TaniumRepoName
    $utilitiesPath = Join-Path $TargetPath $UtilitiesRepoName

    # Create EXTERNAL_REPOS.txt for manual action
    $externalReposList = @"
# External Repositories - Manual Action Required

This file lists external repositories that need to be forked/starred on GitHub.

Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Action Items

1. Fork the following repositories to your GitHub account
2. Star the original repositories for updates
3. Document any local modifications in your forks

## Repositories

### Port_Authority
- Original: (Check EXTERNAL_DEPENDENCIES.md for URL)
- Status: [ ] Forked [ ] Starred
- Local Path: $ExternalReposPath\Port_Authority

### Windows-Secure-Host-Baseline
- Original: https://github.com/nsacyber/Windows-Secure-Host-Baseline
- Status: [ ] Forked [ ] Starred
- Local Path: $ExternalReposPath\Windows-Secure-Host-Baseline

## Required PowerShell Modules

See EXTERNAL_DEPENDENCIES.md for full list of required modules:
- ActiveDirectory
- LidarrPS
- AWSPowerShell
- TaniumClient
- GroupPolicy
- PSWindowsUpdate

Install with: Install-Module <ModuleName> -Scope CurrentUser
"@

    foreach ($repoPath in @($taniumPath, $utilitiesPath)) {
        $externalReposPath = Join-Path $repoPath "EXTERNAL_REPOS.txt"
        if ($PSCmdlet.ShouldProcess($externalReposPath, "Create external repos list")) {
            $externalReposList | Out-File -FilePath $externalReposPath -Encoding UTF8 -Force
            Write-Log "Created: $externalReposPath"
        }

        # Update README.md with Prerequisites section
        $readmePath = Join-Path $repoPath "README.md"
        if (Test-Path $readmePath) {
            $readmeContent = Get-Content $readmePath -Raw
            if ($readmeContent -notmatch '## Prerequisites') {
                $prerequisitesSection = @"

## Prerequisites

### Required PowerShell Modules

``````powershell
# Install required modules
Install-Module PSScriptAnalyzer, Pester -Scope CurrentUser -Force

# For specific scripts, you may also need:
# Install-Module ActiveDirectory, LidarrPS, AWSPowerShell -Scope CurrentUser
``````

### External Repositories

Some scripts depend on external repositories. See ``EXTERNAL_REPOS.txt`` for:
- Repositories to fork/star
- Installation instructions
- Local path requirements

"@
                $readmeContent = $readmeContent -replace '(## Getting Started)', "$prerequisitesSection`n`$1"
                if ($PSCmdlet.ShouldProcess($readmePath, "Update README with prerequisites")) {
                    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8 -Force
                    Write-Log "Updated README with prerequisites: $readmePath"
                }
            }
        }
    }

    Write-Log "External dependencies processed" -Level Success
}

#endregion

#region Stage 7: Git Operations

function Invoke-GitOperations {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "STAGE 7: Git Operations" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Log "Performing Git operations"

    $taniumPath = Join-Path $TargetPath $TaniumRepoName
    $utilitiesPath = Join-Path $TargetPath $UtilitiesRepoName

    foreach ($repoPath in @($taniumPath, $utilitiesPath)) {
        $repoName = Split-Path $repoPath -Leaf

        Write-Log "Processing Git operations for: $repoName"

        Push-Location $repoPath
        try {
            # Get count of scripts for commit message
            $scriptCount = (Get-ChildItem -Path $repoPath -Include *.ps1,*.psm1 -Recurse -File).Count

            # Stage all files
            if ($PSCmdlet.ShouldProcess($repoPath, "Git add all files")) {
                git add -A
                Write-Log "Staged all files in $repoName"
            }

            # Create commit
            $commitMessage = @"
Initial import from reorganization

- Imported $scriptCount scripts
- Applied naming conventions
- Created test stubs
- Added documentation stubs

This is the baseline before refactoring begins.
All scripts need: help documentation, WhatIf support, and tests.

See docs/ for reorganization artifacts and plans.
"@

            if ($PSCmdlet.ShouldProcess($repoPath, "Git commit")) {
                git commit -m $commitMessage
                Write-Log "Created initial commit for $repoName" -Level Success
            }

            # Create refactoring branch
            if ($PSCmdlet.ShouldProcess($repoPath, "Create refactoring branch")) {
                git checkout -b refactoring
                git checkout main
                Write-Log "Created refactoring branch for $repoName"
            }

            # Create baseline tag
            if ($PSCmdlet.ShouldProcess($repoPath, "Create baseline tag")) {
                git tag v0.1-baseline -m "Baseline before refactoring"
                Write-Log "Created v0.1-baseline tag for $repoName"
            }

            # Push to GitHub (unless skipped)
            if (-not $SkipGitPush) {
                if ($PSCmdlet.ShouldProcess($repoPath, "Push to GitHub")) {
                    Write-Log "Pushing $repoName to GitHub..."
                    git push -u origin main
                    git push origin refactoring
                    git push origin v0.1-baseline
                    Write-Log "Pushed $repoName to GitHub" -Level Success
                }
            } else {
                Write-Log "Skipped push for $repoName (SkipGitPush specified)" -Level Warning
            }
        }
        catch {
            Write-Log "Git operations failed for $repoName : $_" -Level Error
            $script:Stats.ErrorsEncountered++
        }
        finally {
            Pop-Location
        }
    }

    Write-Log "Git operations complete" -Level Success
}

#endregion

#region Summary Report

function Show-SummaryReport {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "REORGANIZATION SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    $duration = (Get-Date) - $script:StartTime

    Write-Host "Execution Time: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host ""
    Write-Host "Files Processed:" -ForegroundColor Yellow
    Write-Host "  Total Processed: $($script:Stats.FilesProcessed)" -ForegroundColor White
    Write-Host "  Files Renamed: $($script:Stats.FilesRenamed)" -ForegroundColor White
    Write-Host "  Tanium Sensors: $($script:Stats.TaniumSensors)" -ForegroundColor Green
    Write-Host "  Tanium Packages: $($script:Stats.TaniumPackages)" -ForegroundColor Green
    Write-Host "  General Utilities: $($script:Stats.GeneralUtilities)" -ForegroundColor Green
    Write-Host "  Needs Manual Review: $($script:Stats.NeedsReview)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Supporting Files Created:" -ForegroundColor Yellow
    Write-Host "  Test Stubs: $($script:Stats.TestStubsCreated)" -ForegroundColor White
    Write-Host "  Doc Stubs: $($script:Stats.DocStubsCreated)" -ForegroundColor White
    Write-Host ""
    Write-Host "External Repositories:" -ForegroundColor Yellow
    Write-Host "  Moved: $($script:Stats.ExternalReposMoved)" -ForegroundColor White
    Write-Host ""
    Write-Host "Issues:" -ForegroundColor Yellow
    Write-Host "  Errors: $($script:Stats.ErrorsEncountered)" -ForegroundColor $(if ($script:Stats.ErrorsEncountered -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Warnings: $($script:Stats.Warnings)" -ForegroundColor $(if ($script:Stats.Warnings -gt 0) { 'Yellow' } else { 'Green' })
    Write-Host ""
    Write-Host "Repositories Created:" -ForegroundColor Yellow
    Write-Host "  Tanium: $TaniumRepoName" -ForegroundColor White
    Write-Host "  Utilities: $UtilitiesRepoName" -ForegroundColor White
    Write-Host ""
    Write-Host "Repository Locations:" -ForegroundColor Yellow
    Write-Host "  Local: $TargetPath" -ForegroundColor White
    Write-Host "  GitHub: https://github.com/$GitHubUsername/" -ForegroundColor White
    if ($script:Stats.ExternalReposMoved -gt 0) {
        Write-Host "  External Repos: $ExternalReposPath" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Review EXTERNAL_REPOS_MOVED.txt and fork/star repositories" -ForegroundColor White
    Write-Host "2. Review scripts in 'Needs Review' category" -ForegroundColor White
    Write-Host "3. Check out 'refactoring' branch to begin improvements" -ForegroundColor White
    Write-Host "4. Add help documentation to scripts (see docs/)" -ForegroundColor White
    Write-Host "5. Write Pester tests for critical scripts" -ForegroundColor White
    Write-Host "6. Set up Git hooks (see DEV_ENVIRONMENT.md)" -ForegroundColor White
    Write-Host ""
    Write-Host "Log File: $script:LogFile" -ForegroundColor Gray
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Write summary to log
    Write-Log "========================================" -Level Info
    Write-Log "REORGANIZATION COMPLETE" -Level Success
    Write-Log "Files Processed: $($script:Stats.FilesProcessed)" -Level Info
    Write-Log "Errors: $($script:Stats.ErrorsEncountered)" -Level $(if ($script:Stats.ErrorsEncountered -gt 0) { 'Error' } else { 'Info' })
    Write-Log "Warnings: $($script:Stats.Warnings)" -Level $(if ($script:Stats.Warnings -gt 0) { 'Warning' } else { 'Info' })
    Write-Log "Duration: $($duration.ToString('hh\:mm\:ss'))" -Level Info
    Write-Log "========================================" -Level Info
}

#endregion

#region Main Execution

try {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  PowerShell Repository Reorganization  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

    Write-Log "========================================" -Level Info
    Write-Log "Starting Repository Reorganization" -Level Info
    Write-Log "Source: $SourcePath" -Level Info
    Write-Log "Target: $TargetPath" -Level Info
    Write-Log "External Repos: $ExternalReposPath" -Level Info
    Write-Log "GitHub User: $GitHubUsername" -Level Info
    Write-Log "WhatIf: $($PSCmdlet.ShouldProcess('test', 'test'))" -Level Info
    Write-Log "========================================" -Level Info

    # Execute stages
    Initialize-GitHubRepositories
    Move-ExternalRepositories
    New-DirectoryStructure
    Copy-ScriptsToRepositories
    New-SupportingFiles
    Copy-DocumentationFiles
    Update-ExternalDependencies
    Invoke-GitOperations

    # Show summary
    Show-SummaryReport

    if ($script:Stats.ErrorsEncountered -gt 0) {
        Write-Host "Reorganization completed with errors. Check log file for details." -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "Reorganization completed successfully!" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Log "CRITICAL ERROR: $_" -Level Error
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error
    Write-Host "`nCritical error occurred. Check log file: $script:LogFile" -ForegroundColor Red
    exit 1
}

#endregion



