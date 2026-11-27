#Requires -Version 5.1
# Pester tests for Get-TaniumClientPatchScanResults-Package.ps1
# Behavior tests: see jesse-slaton/tanium-powershell#62 (M7).

BeforeAll {
    Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestHelpers.psm1') -Force
    $script:Target = Resolve-StubTarget -Name 'Get-TaniumClientPatchScanResults-Package.ps1'
}

Describe 'Get-TaniumClientPatchScanResults-Package.ps1 Tests' {
    Context 'Script Parsing' {
        It 'Should be found exactly once in the repository' {
            $script:Target.Status | Should -Be 'Found' -Because $script:Target.Message
        }

        It 'Should parse without errors and without being run' {
            $script:Target.Status | Should -Be 'Found' -Because $script:Target.Message
            $parse = Get-ScriptParseResult -Path $script:Target.Path
            $parse.ErrorCount | Should -Be 0 -Because ($parse.Errors -join '; ')
        }
    }
}
