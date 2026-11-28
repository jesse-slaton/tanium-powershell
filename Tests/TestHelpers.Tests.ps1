#Requires -Version 5.1
# Pester tests for Tests/TestHelpers.psm1. Every fixture is synthetic and lives in TestDrive;
# no repository script is read or run.

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'TestHelpers.psm1') -Force

    function Add-Fixture {
        param([string]$Root, [string]$RelativePath, [string]$Content = '# fixture')
        $path = Join-Path $Root $RelativePath
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force
        Set-Content -LiteralPath $path -Value $Content
        $path
    }
}

Describe 'Get-RepoRoot' {
    It 'returns the folder that holds Tests/' {
        Test-Path -LiteralPath (Join-Path (Get-RepoRoot) 'Tests/TestHelpers.psm1') | Should -BeTrue
    }
}

Describe 'Resolve-StubTarget' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:Root
    }

    It 'finds a script by exact name in any top-level folder' {
        $expected = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.ps1'
        $result = Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root
        $result.Status | Should -Be 'Found'
        $result.Path | Should -Be $expected
        $result.Matches | Should -Be @('Sensors/Get-Thing.ps1')
    }

    It 'reports NotFound with a message that names the script' {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Other.ps1'
        $result = Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root
        $result.Status | Should -Be 'NotFound'
        $result.Path | Should -BeNullOrEmpty
        $result.Message | Should -BeLike "*'Get-Thing.ps1'*was not found*"
    }

    It 'does not strip suffixes or guess renames' {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.ps1'
        (Resolve-StubTarget -Name 'Get-Thing-Package.ps1' -Root $script:Root).Status | Should -Be 'NotFound'
        (Resolve-StubTarget -Name 'Get-Thing' -Root $script:Root).Status | Should -Be 'NotFound'
    }

    It 'matches the name case-sensitively' {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.ps1'
        (Resolve-StubTarget -Name 'get-thing.ps1' -Root $script:Root).Status | Should -Be 'NotFound'
    }

    It 'reports Ambiguous and lists every match' {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.ps1'
        $null = Add-Fixture -Root $script:Root -RelativePath 'Packages/Get-Thing.ps1'
        $result = Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root
        $result.Status | Should -Be 'Ambiguous'
        $result.Path | Should -BeNullOrEmpty
        $result.Matches | Should -HaveCount 2
        $result.Message | Should -BeLike '*Sensors/Get-Thing.ps1*'
        $result.Message | Should -BeLike '*Packages/Get-Thing.ps1*'
    }

    It 'ignores files under Tests and .git, and *.Tests.ps1 files' {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Tests/Unit/Get-Thing.ps1'
        $null = Add-Fixture -Root $script:Root -RelativePath '.git/Get-Thing.ps1'
        $null = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.Tests.ps1'
        (Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root).Status | Should -Be 'NotFound'
        (Resolve-StubTarget -Name 'Get-Thing.Tests.ps1' -Root $script:Root).Status | Should -Be 'NotFound'
    }

    It 'still finds a real script when a decoy sits under Tests' {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Tests/Unit/Get-Thing.ps1'
        $expected = Add-Fixture -Root $script:Root -RelativePath 'Packages/Get-Thing.ps1'
        $result = Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root
        $result.Status | Should -Be 'Found'
        $result.Path | Should -Be $expected
    }

    It 'ignores a script under a dot-prefixed .git folder on every platform' {
        $null = Add-Fixture -Root $script:Root -RelativePath '.git/hooks/Get-Thing.ps1'
        $expected = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.ps1'
        $result = Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root
        $result.Status | Should -Be 'Found'
        $result.Path | Should -Be $expected
    }

    It 'reports Error, not Found, when enumeration reports an unreadable path' {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.ps1'
        Mock -ModuleName TestHelpers Get-ChildItem {
            Write-Error -Message 'Access denied' -TargetObject (Join-Path $LiteralPath 'Locked') -ErrorAction SilentlyContinue
            [pscustomobject]@{ Name = 'Get-Thing.ps1'; FullName = (Join-Path $LiteralPath 'Sensors/Get-Thing.ps1') }
        }
        $result = Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root
        $result.Status | Should -Be 'Error'
        $result.Path | Should -BeNullOrEmpty
        $result.Message | Should -BeLike '*could not be read*Locked*'
    }

    # $env:OS, not $IsWindows: $IsWindows does not exist in Windows PowerShell 5.1, where it is
    # $null and the skip would never fire. chmod is Unix-only, and root can read a 000 folder.
    It 'reports Error, not Found, when a real folder cannot be read' -Skip:($env:OS -eq 'Windows_NT' -or $env:USER -eq 'root') {
        $null = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Get-Thing.ps1'
        $locked = Join-Path $script:Root 'Locked'
        $null = Add-Fixture -Root $script:Root -RelativePath 'Locked/Get-Thing.ps1'
        chmod 000 $locked
        try {
            $result = Resolve-StubTarget -Name 'Get-Thing.ps1' -Root $script:Root
        }
        finally {
            chmod 755 $locked
        }
        $result.Status | Should -Be 'Error'
        $result.Message | Should -BeLike '*Locked*'
    }

    It 'searches the real repo root by default without throwing' {
        { Resolve-StubTarget -Name 'No-Such-Script-Anywhere.ps1' } | Should -Not -Throw
        (Resolve-StubTarget -Name 'No-Such-Script-Anywhere.ps1').Status | Should -Be 'NotFound'
    }
}

Describe 'Get-ScriptParseResult' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:Root
    }

    It 'reports zero errors for valid syntax' {
        $path = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Ok.ps1' -Content 'function Get-A { 1 }'
        $result = Get-ScriptParseResult -Path $path
        $result.ErrorCount | Should -Be 0
    }

    It 'reports a syntax error without throwing' {
        $path = Add-Fixture -Root $script:Root -RelativePath 'Sensors/Bad.ps1' -Content 'function Get-A { '
        { Get-ScriptParseResult -Path $path } | Should -Not -Throw
        $result = Get-ScriptParseResult -Path $path
        $result.ErrorCount | Should -BeGreaterOrEqual 1
        $result.Errors[0] | Should -BeLike 'line *'
    }

    It 'never executes the script: a top-level side effect leaves no marker' {
        $marker = Join-Path $script:Root 'executed.marker'
        $quoted = $marker.Replace("'", "''")
        $null = Add-Fixture -Root $script:Root -RelativePath 'Packages/Side-Effect.ps1' -Content "Set-Content -LiteralPath '$quoted' -Value 'ran'"
        $target = Resolve-StubTarget -Name 'Side-Effect.ps1' -Root $script:Root
        $target.Status | Should -Be 'Found'
        (Get-ScriptParseResult -Path $target.Path).ErrorCount | Should -Be 0
        Test-Path -LiteralPath $marker | Should -BeFalse
    }
}

Describe 'Get-PowerShellEncodingProblem' {
    BeforeAll {
        $script:Bom = [byte[]](0xEF, 0xBB, 0xBF)
        # 'caf' + U+00E9 + newline, as UTF-8 bytes: non-ASCII text.
        $script:NonAscii = [byte[]](0x63, 0x61, 0x66, 0xC3, 0xA9, 0x0A)
        $script:Ascii = [System.Text.Encoding]::ASCII.GetBytes("Write-Output 'hi'`r`n`t`f")
    }

    It 'passes <Case>' -TestCases @(
        @{ Case = 'pure ASCII without a BOM'; Make = { $script:Ascii } }
        @{ Case = 'pure ASCII with a BOM'; Make = { [byte[]]($script:Bom + $script:Ascii) } }
        @{ Case = 'non-ASCII UTF-8 with a BOM'; Make = { [byte[]]($script:Bom + $script:NonAscii) } }
        @{ Case = 'a file that is only a BOM'; Make = { $script:Bom } }
        @{ Case = 'an empty file'; Make = { [byte[]]@() } }
    ) {
        # @() then [byte[]]: an empty array returned from a scriptblock would otherwise unroll to $null.
        $bytes = [byte[]]@(& $Make)
        Get-PowerShellEncodingProblem -Bytes $bytes | Should -BeNullOrEmpty
    }

    It 'rejects <Case>' -TestCases @(
        @{ Case = 'non-ASCII UTF-8 without a BOM'; Expected = 'non-ASCII UTF-8 text without a byte order mark*'; Make = { $script:NonAscii } }
        @{ Case = 'UTF-16LE with a BOM'; Expected = 'UTF-16LE byte order mark'; Make = { [byte[]](0xFF, 0xFE, 0x41, 0x00) } }
        @{ Case = 'UTF-16BE with a BOM'; Expected = 'UTF-16BE byte order mark'; Make = { [byte[]](0xFE, 0xFF, 0x00, 0x41) } }
        @{ Case = 'BOM-less UTF-16LE ASCII text'; Expected = 'control character other than tab, LF, FF or CR*'; Make = { [System.Text.Encoding]::Unicode.GetBytes('param()') } }
        @{ Case = 'BOM-less UTF-16BE ASCII text'; Expected = 'control character other than tab, LF, FF or CR*'; Make = { [System.Text.Encoding]::BigEndianUnicode.GetBytes('param()') } }
        @{ Case = 'invalid UTF-8'; Expected = 'not valid UTF-8*'; Make = { [byte[]](0x41, 0xC3, 0x28) } }
        @{ Case = 'a DEL byte (U+007F) in ASCII text'; Expected = 'control character other than tab, LF, FF or CR*'; Make = { [byte[]](0x41, 0x7F, 0x42) } }
        @{ Case = 'a C1 control (U+0085) in BOM-prefixed UTF-8'; Expected = 'control character other than tab, LF, FF or CR*'; Make = { [byte[]](0xEF, 0xBB, 0xBF, 0x41, 0xC2, 0x85, 0x42) } }
        @{ Case = 'a control byte in ASCII text'; Expected = 'control character other than tab, LF, FF or CR*'; Make = { [byte[]](0x41, 0x01, 0x42) } }
    ) {
        $bytes = [byte[]]@(& $Make)
        Get-PowerShellEncodingProblem -Bytes $bytes | Should -BeLike $Expected
    }
}

Describe 'Get-Utf16ByteOrderMark' {
    It 'classifies <Case> as <Expected>' -TestCases @(
        @{ Case = 'a UTF-16LE BOM'; Expected = 'UTF-16LE'; Make = { [byte[]](0xFF, 0xFE, 0x41, 0x00) } }
        @{ Case = 'a UTF-16BE BOM'; Expected = 'UTF-16BE'; Make = { [byte[]](0xFE, 0xFF, 0x00, 0x41) } }
        @{ Case = 'just the two LE BOM bytes'; Expected = 'UTF-16LE'; Make = { [byte[]](0xFF, 0xFE) } }
        @{ Case = 'a UTF-8 BOM'; Expected = ''; Make = { [byte[]](0xEF, 0xBB, 0xBF, 0x41) } }
        @{ Case = 'an empty file'; Expected = ''; Make = { [byte[]]@() } }
        @{ Case = 'a one-byte file starting FF'; Expected = ''; Make = { [byte[]](0xFF) } }
        @{ Case = 'plain ASCII'; Expected = ''; Make = { [byte[]](0x68, 0x69) } }
    ) {
        $bytes = [byte[]]@(& $Make)
        $result = Get-Utf16ByteOrderMark -Bytes $bytes
        if ($Expected) { $result | Should -Be $Expected } else { $result | Should -BeNullOrEmpty }
    }
}
