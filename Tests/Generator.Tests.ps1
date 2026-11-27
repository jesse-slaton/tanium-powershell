#Requires -Version 5.1
# Pester tests for New-SupportingFiles in Packages/General/Implement-Reorganization-Package.ps1.
# The generator script is never run: its New-SupportingFiles function is lifted out of the parsed
# script and defined here, and the stub writers it calls are mocked. Fixtures live in TestDrive.

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'TestHelpers.psm1') -Force

    $generator = Join-Path (Get-RepoRoot) 'Packages/General/Implement-Reorganization-Package.ps1'
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($generator, [ref]$tokens, [ref]$parseErrors)
    $parseErrors | Should -BeNullOrEmpty
    $definition = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'New-SupportingFiles'
        }, $true)
    $definition | Should -Not -BeNullOrEmpty
    . ([scriptblock]::Create($definition.Extent.Text))

    # Stand-ins for the generator's own helpers, so Mock has commands to replace. Each takes the
    # parameters the generator passes; every call is mocked, so the bodies never run.
    $standIn = { param($Message, $Level, $ScriptName, $OutputPath, $Synopsis) $null = $Message, $Level, $ScriptName, $OutputPath, $Synopsis }
    foreach ($name in 'Write-Log', 'New-TestStub', 'New-DocStub') {
        Set-Item -Path "function:script:$name" -Value $standIn
    }

    function Add-Fixture {
        param([string]$Root, [string]$RelativePath)
        $path = Join-Path $Root $RelativePath
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
        Set-Content -LiteralPath $path -Value '# fixture'
    }
}

Describe 'New-SupportingFiles' {
    BeforeEach {
        # The generator reads these script-level parameters.
        $TargetPath = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $TaniumRepoName = 'tanium-powershell'
        $UtilitiesRepoName = 'powershell-utilities'
        Add-Fixture -Root (Join-Path $TargetPath $TaniumRepoName) -RelativePath 'Sensors/Get-TaniumThing.ps1'
        Add-Fixture -Root (Join-Path $TargetPath $UtilitiesRepoName) -RelativePath 'Scripts/Get-UtilityThing.ps1'

        Mock Write-Host {}
        Mock Write-Log {}
        Mock New-TestStub {}
        Mock New-DocStub {}
    }

    It 'writes a test stub only for the Tanium repository' {
        New-SupportingFiles
        Should -Invoke New-TestStub -Times 1 -Exactly
        Should -Invoke New-TestStub -Times 1 -Exactly -ParameterFilter {
            $ScriptName -eq 'Get-TaniumThing.ps1' -and $OutputPath -like "*$TaniumRepoName*"
        }
        Should -Invoke New-TestStub -Times 0 -Exactly -ParameterFilter { $OutputPath -like "*$UtilitiesRepoName*" }
    }

    It 'still writes a doc stub for both repositories' {
        New-SupportingFiles
        Should -Invoke New-DocStub -Times 2 -Exactly
        Should -Invoke New-DocStub -Times 1 -Exactly -ParameterFilter { $ScriptName -eq 'Get-TaniumThing.ps1' }
        Should -Invoke New-DocStub -Times 1 -Exactly -ParameterFilter { $ScriptName -eq 'Get-UtilityThing.ps1' }
    }
}
