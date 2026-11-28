BeforeAll {
    $script:ScriptPath = Join-Path $PSScriptRoot 'Install-TestDependencies.ps1'
    $script:Stubbed = [System.Collections.Generic.List[string]]::new()

    # Pester's Mock needs the command to exist before it can be mocked. Stock Windows
    # PowerShell 5.1 has no Install-PSResource, and recent PowerShell 7 releases no longer
    # ship Install-Module (PowerShellGet v2). A stub stands in only for whichever is
    # missing, so a command that really exists is never replaced: on Windows 5.1 the tests
    # mock the real Install-Module and the stub Install-PSResource.
    function Register-CommandStub {
        param(
            [string[]]$Name,
            [string[]]$Parameter = @(),
            [string[]]$Switch = @()
        )
        foreach ($commandName in $Name) {
            if (Get-Command -Name $commandName -ErrorAction SilentlyContinue) { continue }
            $declarations = @(foreach ($p in $Parameter) { "[Parameter()] `$$p" })
            $declarations += foreach ($s in $Switch) { "[Parameter()] [switch] `$$s" }
            $declarations += '[Parameter(ValueFromRemainingArguments = $true)] $StubRemainingArguments'
            $body = "[CmdletBinding()] param($($declarations -join ', ')) throw ""'$commandName' is a test stub; Mock it before calling it."""
            Set-Item -Path "Function:\global:$commandName" -Value ([scriptblock]::Create($body))
            $script:Stubbed.Add($commandName)
        }
    }
    function Remove-CommandStub {
        param([string[]]$Name)
        foreach ($commandName in $Name) {
            if ($script:Stubbed.Contains($commandName)) {
                Remove-Item -LiteralPath "Function:\$commandName"
                $null = $script:Stubbed.Remove($commandName)
            }
        }
    }

    Register-CommandStub -Name Install-PSResource -Parameter Name, Version, Repository, Scope -Switch TrustRepository, AcceptLicense, Quiet
    Register-CommandStub -Name Install-Module -Parameter Name, RequiredVersion, Repository, Scope -Switch Force, SkipPublisherCheck, AllowClobber

    # Runs the installer with every install, load and unload call mocked, and returns what it
    # printed. Unless a test mocks Get-Module -ListAvailable itself, nothing is installed yet.
    function Invoke-Installer {
        Mock Get-Module -ParameterFilter { -not $ListAvailable } { }
        if (-not $script:PinnedVersionsInstalled) {
            Mock Get-Module -ParameterFilter { $ListAvailable } { }
        }
        Mock Install-PSResource { }
        Mock Install-Module { }
        Mock Remove-Module { }
        Mock Import-Module { }
        & $script:ScriptPath 6>&1 | ForEach-Object { "$_" }
    }
}

AfterAll {
    Remove-CommandStub -Name Install-PSResource, Install-Module
}

Describe 'Install-TestDependencies.ps1' {
    Context 'when Install-PSResource is available' {
        BeforeAll {
            Mock Get-Command -ParameterFilter { $Name -eq 'Install-PSResource' } { [pscustomobject]@{ Name = 'Install-PSResource' } }
            $script:Output = Invoke-Installer
        }

        It 'installs each pinned version with Install-PSResource from PSGallery for the current user' {
            Should -Invoke Install-PSResource -Times 1 -Exactly -Scope Context -ParameterFilter {
                $Name -eq 'Pester' -and $Version -eq '5.6.1' -and $Repository -eq 'PSGallery' -and $Scope -eq 'CurrentUser' -and $TrustRepository
            }
            Should -Invoke Install-PSResource -Times 1 -Exactly -Scope Context -ParameterFilter {
                $Name -eq 'PSScriptAnalyzer' -and $Version -eq '1.23.0' -and $Repository -eq 'PSGallery' -and $Scope -eq 'CurrentUser' -and $TrustRepository
            }
        }

        It 'never calls Install-Module' {
            Should -Invoke Install-Module -Times 0 -Exactly -Scope Context
        }

        It 'names the install command in its output' {
            $script:Output | Should -Contain 'Installing Pester 5.6.1 with Install-PSResource'
            $script:Output | Should -Contain 'Installing PSScriptAnalyzer 1.23.0 with Install-PSResource'
        }

        It 'loads the pinned versions into the session' {
            Should -Invoke Import-Module -Times 1 -Exactly -Scope Context -ParameterFilter { $Name -eq 'Pester' -and $RequiredVersion -eq '5.6.1' -and $Global }
            Should -Invoke Import-Module -Times 1 -Exactly -Scope Context -ParameterFilter { $Name -eq 'PSScriptAnalyzer' -and $RequiredVersion -eq '1.23.0' -and $Global }
        }
    }

    Context 'when the pinned versions are already installed' {
        BeforeAll {
            Mock Get-Command -ParameterFilter { $Name -eq 'Install-PSResource' } { [pscustomobject]@{ Name = 'Install-PSResource' } }
            $script:PinnedVersionsInstalled = $true
            Mock Get-Module -ParameterFilter { $ListAvailable } {
                switch ($Name) {
                    'Pester' { [pscustomobject]@{ Name = 'Pester'; Version = [version]'5.6.1' } }
                    'PSScriptAnalyzer' { [pscustomobject]@{ Name = 'PSScriptAnalyzer'; Version = [version]'1.23.0' } }
                }
            }
            $script:Output = Invoke-Installer
        }

        AfterAll {
            $script:PinnedVersionsInstalled = $false
        }

        It 'installs nothing' {
            Should -Invoke Install-PSResource -Times 0 -Exactly -Scope Context
            Should -Invoke Install-Module -Times 0 -Exactly -Scope Context
            $script:Output | Should -Contain 'Pester 5.6.1 already installed'
        }
    }

    Context 'when Install-PSResource is missing' {
        BeforeAll {
            Mock Get-Command -ParameterFilter { $Name -eq 'Install-PSResource' } { }
        }

        It 'falls back to Install-Module on Windows PowerShell 5.1 and says so' -Skip:($PSVersionTable.PSEdition -ne 'Desktop') {
            $output = Invoke-Installer
            Should -Invoke Install-PSResource -Times 0 -Exactly
            Should -Invoke Install-Module -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Pester' -and $RequiredVersion -eq '5.6.1' -and $Repository -eq 'PSGallery' -and $Scope -eq 'CurrentUser' -and $SkipPublisherCheck
            }
            $output | Should -Contain 'Installing Pester 5.6.1 with Install-Module'
        }

        It 'needs no install command when the pinned versions are already installed' {
            $script:PinnedVersionsInstalled = $true
            try {
                Mock Get-Module -ParameterFilter { $ListAvailable } {
                    switch ($Name) {
                        'Pester' { [pscustomobject]@{ Name = 'Pester'; Version = [version]'5.6.1' } }
                        'PSScriptAnalyzer' { [pscustomobject]@{ Name = 'PSScriptAnalyzer'; Version = [version]'1.23.0' } }
                    }
                }
                Mock Get-Command -ParameterFilter { $Name -eq 'Install-Module' } { }
                { Invoke-Installer } | Should -Not -Throw
                Should -Invoke Install-PSResource -Times 0 -Exactly
                Should -Invoke Install-Module -Times 0 -Exactly
                Should -Invoke Import-Module -Times 2 -Exactly
            }
            finally {
                $script:PinnedVersionsInstalled = $false
            }
        }

        It 'stops with an error on PowerShell 7 instead of falling back' -Skip:($PSVersionTable.PSEdition -ne 'Core') {
            { Invoke-Installer } | Should -Throw '*Install the Microsoft.PowerShell.PSResourceGet module*'
            Should -Invoke Install-Module -Times 0 -Exactly
            Should -Invoke Install-PSResource -Times 0 -Exactly
        }
    }
}
