<#
.SYNOPSIS
    Installs the pinned Pester and PSScriptAnalyzer versions used by this test suite.

.DESCRIPTION
    Installs Pester and PSScriptAnalyzer for the current user from the PowerShell Gallery
    unless the pinned versions are already present. CI runs this before Invoke-Pester so
    local and CI runs use the same versions.

    Installs with Install-PSResource (PSResourceGet) when it is available. It ships with
    PowerShell 7.4 and later. Windows PowerShell 5.1 without PSResourceGet falls back to
    Install-Module (PowerShellGet), and the output names the command each install used.
    PowerShell 7 without PSResourceGet stops with an error instead of falling back.

.PARAMETER PesterVersion
    Pester version to install. The suite uses Pester 5 syntax.

.PARAMETER ScriptAnalyzerVersion
    PSScriptAnalyzer version to install.

.EXAMPLE
    ./Tests/Install-TestDependencies.ps1

    Installs the pinned versions if they are missing.

.EXAMPLE
    ./Tests/Install-TestDependencies.ps1 -PesterVersion 5.7.1

    Installs a different Pester 5 release, for example to try an upgrade.

.NOTES
    Needs network access to the PowerShell Gallery. Installs to the CurrentUser scope,
    so no admin rights are required. PowerShell 7.0 to 7.3 need the
    Microsoft.PowerShell.PSResourceGet module installed first, or an upgrade to 7.4+.
#>
[CmdletBinding()]
param(
    [version]$PesterVersion = '5.6.1',
    [version]$ScriptAnalyzerVersion = '1.23.0'
)

# No session-wide $ErrorActionPreference: the script is also dot-sourced, and a Stop set
# here would leak into the caller's Pester run (CI runs the suite with the default
# Continue). Each call that must stop on failure says so with -ErrorAction Stop.

# PSResourceGet when present; Install-Module only as the Windows PowerShell 5.1 fallback,
# because stock 5.1 ships PowerShellGet 1.0.0.1 without PSResourceGet. Never a silent
# fallback: the chosen command is printed, and PowerShell 7 without it is an error.
# Chosen only when a module is actually missing, so an up-to-date host needs neither.
function Get-TestDependencyInstaller {
    if (Get-Command -Name Install-PSResource -ErrorAction SilentlyContinue) {
        'Install-PSResource'
    }
    elseif ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Command -Name Install-Module -ErrorAction SilentlyContinue)) {
        'Install-Module'
    }
    else {
        throw "Install-PSResource is not available in PowerShell $($PSVersionTable.PSVersion). Install the Microsoft.PowerShell.PSResourceGet module or upgrade to PowerShell 7.4 or later."
    }
}
$TestDependencyInstaller = $null

foreach ($module in @(
        @{ Name = 'Pester'; Version = $PesterVersion }
        @{ Name = 'PSScriptAnalyzer'; Version = $ScriptAnalyzerVersion }
    )) {
    if (Get-Module -ListAvailable -Name $module.Name | Where-Object Version -EQ $module.Version) {
        Write-Host "$($module.Name) $($module.Version) already installed"
        continue
    }
    if (-not $TestDependencyInstaller) {
        $TestDependencyInstaller = Get-TestDependencyInstaller
    }
    Write-Host "Installing $($module.Name) $($module.Version) with $TestDependencyInstaller"
    # -Repository PSGallery: without it both commands take the first match from any registered
    # repository, so a pinned version could come from a different source.
    if ($TestDependencyInstaller -eq 'Install-PSResource') {
        # An exact -Version installs that version only. PSResourceGet has no publisher check,
        # so the old, differently signed Pester 3.4 in Windows PowerShell 5.1 does not block it.
        Install-PSResource -Name $module.Name -Version $module.Version.ToString() -Repository PSGallery -Scope CurrentUser -TrustRepository -AcceptLicense -Quiet -ErrorAction Stop
    }
    else {
        # -SkipPublisherCheck: Windows PowerShell 5.1 ships an old, differently signed Pester 3.4.
        Install-Module -Name $module.Name -RequiredVersion $module.Version -Repository PSGallery -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber -ErrorAction Stop
    }
}

# Load the pinned versions into this session so a dot-sourced run (. ./Tests/Install-TestDependencies.ps1)
# uses them instead of whichever version autoloads first. CI imports them again in its own test step.
foreach ($module in @(
        @{ Name = 'Pester'; Version = $PesterVersion }
        @{ Name = 'PSScriptAnalyzer'; Version = $ScriptAnalyzerVersion }
    )) {
    Get-Module -Name $module.Name | Where-Object Version -NE $module.Version | Remove-Module -Force -ErrorAction Stop
    Import-Module -Name $module.Name -RequiredVersion $module.Version -Force -Global -ErrorAction Stop
}
