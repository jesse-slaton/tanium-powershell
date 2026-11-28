#Requires -Version 5.1
<#
.SYNOPSIS
    Shared helpers for the Pester suite. Nothing here runs a script under test.

.DESCRIPTION
    Scripts under Admin/, Packages/, Sensors/, Deploy-Packages/ and Modules/ change the
    machine that runs them, so a test must never dot-source or invoke one. These helpers
    find a script by name and check it with the PowerShell parser, which reads the text and
    runs none of it. Requires Pester 5.
#>

$script:RepoRoot = Split-Path -Parent $PSScriptRoot

function Get-RepoRoot {
    <#
    .SYNOPSIS
        Returns the repository root folder.
    #>
    $script:RepoRoot
}

function Resolve-StubTarget {
    <#
    .SYNOPSIS
        Finds the one script with an exact file name anywhere in the repository, without running it.

    .DESCRIPTION
        Matches the file name exactly and case-sensitively. Files under a Tests folder, under
        .git, and any *.Tests.ps1 file are never candidates. There is no fallback, no suffix
        stripping and no guessing at renames.

        Returns an object with Status (Found, NotFound, Ambiguous or Error; Error means part of the
        tree could not be read, so the result cannot be trusted), Name, Path (the full path
        when Found, otherwise $null), Matches (repo-relative paths of every match) and Message
        (a sentence fit for a test failure).

    .PARAMETER Name
        Script file name with extension, such as Get-TaniumClient-Package.ps1.

    .PARAMETER Root
        Folder to search. Defaults to the repository root; tests pass a TestDrive folder.

    .EXAMPLE
        $target = Resolve-StubTarget -Name 'Get-TaniumClient-Package.ps1'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Root = $script:RepoRoot
    )

    $rootPath = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).ProviderPath.TrimEnd('\', '/')

    # -Force so hidden and dot-prefixed items are seen on every platform (Unix skips them
    # otherwise); the Tests and .git segment exclusions below are then the only filter.
    # Enumeration errors are collected, never swallowed: an unreadable folder could hide a
    # second copy of the target, so it must not be reported as Found.
    $enumErrors = $null
    $files = @(Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force -ErrorAction SilentlyContinue -ErrorVariable enumErrors |
            Where-Object { $_.Name -ceq $Name -and $_.Name -notlike '*.Tests.ps1' })

    $unreadable = @(foreach ($err in @($enumErrors)) {
            $errPath = if ($err.TargetObject -is [string]) { $err.TargetObject } else { [string]$err.Exception.Message }
            $errRelative = if ($errPath.StartsWith($rootPath)) { $errPath.Substring($rootPath.Length).TrimStart('\', '/') } else { $errPath }
            $errSegments = @($errRelative -split '[\\/]')
            if ($errSegments -contains 'Tests' -or $errSegments -contains '.git') { continue }
            $errPath
        })

    $found = @(foreach ($file in $files) {
            $relative = $file.FullName.Substring($rootPath.Length).TrimStart('\', '/')
            $folders = @($relative -split '[\\/]' | Select-Object -SkipLast 1)
            if ($folders -contains 'Tests' -or $folders -contains '.git') { continue }
            [pscustomobject]@{ Relative = ($relative -replace '\\', '/'); Full = $file.FullName }
        })

    $status = 'Found'
    $path = $null
    $message = "Script '$Name' found."
    if ($unreadable.Count -gt 0) {
        $status = 'Error'
        $message = "Script '$Name' could not be resolved reliably; these paths could not be read: $($unreadable -join ', ')."
    }
    elseif ($found.Count -eq 0) {
        $status = 'NotFound'
        $message = "Script '$Name' was not found in the repository (looked for an exact, case-sensitive file name outside Tests/). Rename the stub or remove it."
    }
    elseif ($found.Count -gt 1) {
        $status = 'Ambiguous'
        $message = "Script '$Name' is ambiguous; it matches: $(($found | ForEach-Object { $_.Relative }) -join ', ')."
    }
    else {
        $path = $found[0].Full
    }

    [pscustomobject]@{
        Status  = $status
        Name    = $Name
        Path    = $path
        Matches = @($found | ForEach-Object { $_.Relative })
        Message = $message
    }
}

function Get-ScriptParseResult {
    <#
    .SYNOPSIS
        Parses a script file with the PowerShell parser and reports syntax errors. Never runs the script.

    .DESCRIPTION
        Uses [System.Management.Automation.Language.Parser]::ParseFile, which reads the text
        only. A syntax error is reported in the result, never thrown.

        Returns an object with Path, ErrorCount and Errors (the parser messages with line numbers).

    .PARAMETER Path
        Path of the .ps1 file to check.

    .EXAMPLE
        (Get-ScriptParseResult -Path $target.Path).ErrorCount | Should -Be 0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $fullPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    $tokens = $null
    $parseErrors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($fullPath, [ref]$tokens, [ref]$parseErrors)

    [pscustomobject]@{
        Path       = $fullPath
        ErrorCount = @($parseErrors).Count
        Errors     = @($parseErrors | ForEach-Object { "line $($_.Extent.StartLineNumber): $($_.Message)" })
    }
}

function Get-PowerShellEncodingProblem {
    <#
    .SYNOPSIS
        Returns why a PowerShell file's bytes break the repo's encoding rule, or nothing if they pass.

    .DESCRIPTION
        The rule (issue #34): no UTF-16, valid UTF-8 only, no control character other than tab,
        LF, FF and CR, and a byte order mark (EF BB BF) whenever the text is not pure ASCII,
        because Windows PowerShell 5.1 reads a BOM-less file in the system code page.

        Every check runs on the decoded string with regular expressions rather than a loop over
        the bytes: an interpreted per-byte loop over the whole repo took over 100 s on Windows
        PowerShell 5.1 (powershell-utilities issue #126). A byte above 0x7F in valid UTF-8 always decodes to a
        character above U+007F, so the non-ASCII check on the text matches the byte check exactly.

    .PARAMETER Bytes
        The file's raw bytes.

    .EXAMPLE
        Get-PowerShellEncodingProblem -Bytes ([System.IO.File]::ReadAllBytes($path))
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) { return 'UTF-16LE byte order mark' }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) { return 'UTF-16BE byte order mark' }

    # Strict decoder: throws on invalid UTF-8 instead of substituting U+FFFD. New-Object, not
    # ::new(), so this also runs on Windows PowerShell 5.1.
    $strictUtf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
    try { $text = $strictUtf8.GetString($Bytes) }
    catch [System.Text.DecoderFallbackException] { return 'not valid UTF-8 (UTF-16 without a byte order mark?)' }

    # A byte below 0x20 is never part of a multi-byte UTF-8 sequence, so matching the decoded
    # text finds every such byte. NUL is the usual sign of BOM-less UTF-16.
    if ($text -match '[\x00-\x08\x0B\x0E-\x1F]') {
        return 'control character other than tab, LF, FF or CR (UTF-16 without a byte order mark?)'
    }

    # GetString keeps a leading BOM as U+FEFF; it is the marker, not content.
    $hasBom = $Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF
    $body = if ($hasBom) { $text.Substring(1) } else { $text }
    if (-not $hasBom -and $body -match '[^\x00-\x7F]') {
        return 'non-ASCII UTF-8 text without a byte order mark (Windows PowerShell 5.1 misreads it)'
    }
}

Export-ModuleMember -Function Get-RepoRoot, Resolve-StubTarget, Get-ScriptParseResult, Get-PowerShellEncodingProblem
