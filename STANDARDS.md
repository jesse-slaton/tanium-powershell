# PowerShell coding standard

This file is the coding standard for every PowerShell file in this repository
(`.ps1`, `.psm1`, `.psd1`). It applies to new and changed code. Untouched legacy
files are tracked in a baseline (rule R-31) and are brought into line when a PR
edits them.

Contents: [Scope](#scope) | [Script categories](#script-categories) | [About the checks](#about-the-checks) | [Cross-cutting rules](#cross-cutting-rules) | [Execution context](#execution-context) | [Sensors](#sensors) | [Platform packages](#platform-packages) | [Deploy packages](#deploy-packages) | [Admin and API scripts](#admin-and-api-scripts) | [Package and sensor combo](#package-and-sensor-combo) | [Enforcement](#enforcement)

## Scope

The standard covers the four script categories in this repository:

- `Sensors/` (and its subfolders): read-only data collection.
- `Packages/<area>/`: state-changing platform packages.
- `Deploy-Packages/`: software install, update, and remove through Tanium Deploy.
- `Admin/`: admin and API scripts run from an admin workstation.

It also covers shared code under `Modules/` and the copy-paste helpers under
`Packages/Templates/`, where the rules apply to a file's role. This repository has
no `Scripts/` directory.

Rules apply to new and modified files. Legacy scripts and content under `Archive/`
are not proof of compliance, and a file only has to satisfy every rule once a PR
edits it (rule R-31). `Tests/**` is exempt from rule R-01 (Pester needs
`<Name>.Tests.ps1`) and from the header part of rule R-07, because Pester files and
fixtures are not scripts a user runs.

Rule keywords follow RFC 2119. **MUST** is a hard requirement, **SHOULD** is the
expected default with exceptions that need a reason, and **MAY** is optional.

## Script categories

Classify a script before applying its rules:

| Category | Purpose | Runs | Changes state? | Help | Directory |
| --- | --- | --- | --- | --- | --- |
| Sensor | Read endpoint state, return it | On the endpoint, under Tanium | Never (read-only) | Comment-based help block | `Sensors/` |
| Platform package | Change endpoint state (config, registry, services) | On the endpoint, under Tanium | Yes | Comment-based help block | `Packages/<area>/` |
| Deploy package | Install, update, or remove software | On the endpoint, through Tanium Deploy | Yes | Comment-based help block | `Deploy-Packages/` |
| Admin/API script | Manage the Tanium Client or call the Tanium API | Admin workstation, outside Tanium | Yes | Full comment-based help (Get-Help) | `Admin/` |

Selection rules:

- If the script only reads endpoint state, it is a sensor.
- If the script changes endpoint state directly, it is a platform package.
- If the script installs, updates, or removes software through Tanium Deploy, it is
  a deploy package.
- If the script runs outside Tanium or manages the Tanium Client itself, it is an
  admin/API script.
- If a read operation exceeds the sensor runtime limit, use the package and sensor
  combo pattern (rule R-30).

A `-Package.ps1` suffix does not prove a file executes an action. Files under
`Packages/` and `Admin/` that only define functions must say so in their header
(rule R-07).

## About the checks

Each rule below ends with a **Checked by** line. The automated checks are delivered
as the M3 parts of issue #43. A rule that no part automates is **Checked by review**,
which means a reviewer applies it by hand until a check lands.

| Part | What it checks |
| --- | --- |
| #44 | Baseline mechanism, the analyzer settings file, and layout rules: indentation, whitespace, braces, trailing whitespace, line endings, and approved verbs. |
| #45 | Output streams, aliases, positional parameters, error handling (empty catch), and the header rule (help block presence). |
| #46 | Tanium AST checks: sensor read-only and no prompts, platform package `SupportsShouldProcess`, no `Invoke-Expression`, and the Sysnative relaunch exception. |
| #47 | File names, strict mode, and casing. |
| #48 | Comment-based help grading (fail below Complete). |

## Cross-cutting rules

### R-01 File names

Rule: name each script `Verb-Noun.ps1`. The verb is an approved verb, the noun is a
singular PascalCase noun. `-Sensor` and `-Package` are the only allowed suffixes after
the noun. No spaces, no underscores.

```powershell
Get-InstalledSoftware-Package.ps1     # good: package suffix
Get-AttachedMonitorInfo-Sensor.ps1    # good: sensor suffix
get_installed_softwares.ps1           # bad: underscores, lower case, plural noun
Fetch-Data.ps1                        # bad: Fetch is not an approved verb
```

Why: `Verb-Noun` names sort and tab-complete predictably, and they match the function
inside. The suffix tells a reader, and the Tanium convention, which category a file
belongs to.

Checked by #47. Existing files with names that would break a deployed Tanium name
are baselined, not renamed (rule R-31).

### R-02 Indentation

Rule: 4 spaces per level, no tabs. A pipeline continuation line is indented one
extra level.

```powershell
Get-CimInstance -ClassName Win32_Service |
    Where-Object { $_.State -eq 'Running' } |
    Select-Object -Property Name, StartMode
```

Checked by #44 (`PSUseConsistentIndentation`), which also adds the `.editorconfig`
that sets the same width in editors.

### R-03 Output streams

Rule: `Write-Host` is banned, except in interactive TUI or menu scripts under
`Admin/` (rule R-28).

- Data goes to the pipeline (implicit output or `Write-Output`).
- Diagnostics go to `Write-Verbose`.
- Problems go to `Write-Warning` or `Write-Error`.
- Long runs report with `Write-Progress`.

Sensors never use `Write-Host`, even though they are not interactive (rule R-19).

Checked by #45 (`PSAvoidUsingWriteHost`, with the interactive admin exception).
Sensors are additionally checked by #46, which has no `Write-Host` exception.

### R-04 Legacy APIs

Rule: these are banned. Each check message names the replacement.

| Banned | Use instead |
| --- | --- |
| `Get-WmiObject`, `Remove-WmiObject`, `Set-WmiInstance`, `Invoke-WmiMethod`, `Register-WmiEvent`, `[wmi]`, `[wmiclass]`, `[wmisearcher]` | `Get-CimInstance`, `Set-CimInstance`, `New-CimInstance`, `Remove-CimInstance`, `Invoke-CimMethod`, `Register-CimIndicationEvent` |
| `Net.WebClient`, `HttpWebRequest` | `Invoke-RestMethod`, `Invoke-WebRequest` |
| `New-Object PSObject` followed by `Add-Member` | `[pscustomobject]@{ ... }` |
| `wmic`, `reg.exe`, `net.exe` where a cmdlet exists | the matching cmdlet |
| `Invoke-Expression` | a direct call, `&`, or a parameter |
| `[Reflection.Assembly]::LoadWithPartialName` | `Add-Type -AssemblyName` |

Sensors SHOULD prefer CIM over WMI (CIM works in both Windows PowerShell 5.1 and
PowerShell 7, and is faster for the read-only queries sensors make).

Checked by #46 (`Invoke-Expression`); the remaining replacements are checked by
review.

### R-05 Aliases and positional parameters

Rule: no aliases in committed code. Write `Where-Object`, not `?` or `where`;
`ForEach-Object`, not `%`; `Get-ChildItem`, not `ls` or `dir`. A positional
parameter is allowed only for the obvious first parameter; name every other one.

Checked by #45 (`PSAvoidUsingCmdletAliases`, `PSAvoidUsingPositionalParameters`).

### R-06 Errors

Rule:

- Where a failure matters, use `-ErrorAction Stop` inside `try`/`catch`.
- A failure on one item writes `Write-Error -ErrorAction Continue` and the loop
  continues. A failure of the whole run throws or exits non-zero.
- No empty `catch` blocks.
- Setting `SilentlyContinue` or `Ignore` by any route needs an explanatory comment
  on the same line or the line directly above.
- Sensor and Deploy-package scripts end with an explicit top-level `exit` code
  (rules R-21 and R-27).

Checked by #45 (`PSAvoidUsingEmptyCatchBlock`); the `SilentlyContinue` comment rule
and the top-level `exit` rule are checked by review.

### R-07 Header and comment-based help

Rule: every script starts with a comment-based help block, which is the script's
header. There is no separate `# Author` / `# Created` / `# Modified` comment block;
those lines now live in the `.NOTES` section of the help block, because a separate
header duplicated and conflicted with comment-based help.

```powershell
<#
.SYNOPSIS
    One-line description.

.DESCRIPTION
    Detailed description.

.PARAMETER Name
    Description of the parameter.

.EXAMPLE
    .\Script-Name.ps1 -Name Value

.NOTES
    Author: Jesse Slaton
    Created: YYYY-MM-DD
    Modified: YYYY-MM-DD

    Prerequisites:
    - List requirements
#>
```

Admin and API scripts additionally MUST support `Get-Help` with at least two
examples (rule R-29). Sensors, platform packages, and deploy packages need the help
block but are not run interactively, so their `.NOTES` records the prerequisites
and Tanium specifications instead.

Checked by #45 (help block presence) and #48 (grade Complete). The `.NOTES`
author and date content is checked by review.

### R-08 Strict mode

Rule: call `Set-StrictMode -Version 3.0` at the top level of every module `.psm1`
and every new or ported script. Pin `3.0`; do not use `-Version Latest`. Existing
scripts adopt it when a PR edits them.

Checked by #47.

### R-09 Braces and whitespace

Rule: one true brace style (OTBS): the opening brace stays on the line of the
statement, and `else`, `elseif`, `catch`, and `finally` go on the line of the
closing brace. Put spaces around operators and after commas. No trailing
whitespace. At most one blank line in a row.

Checked by #44 (`PSPlaceOpenBrace`, `PSPlaceCloseBrace`, `PSUseConsistentWhitespace`,
`PSAvoidTrailingWhitespace`).

### R-10 Casing

Rule:

- PascalCase: functions, parameters, script-scope and module-scope variables, public
  properties.
- camelCase: local variables.
- Lower-case keywords (`if`, `foreach`, `function`, `param`).
- Canonical casing for cmdlet names (`Get-ChildItem`, not `get-childitem`).

Checked by #47 (`PSUseCorrectCasing`, plus keyword and parameter casing checks).

### R-11 Encoding and line endings

Rule:

- ASCII preferred. If a file needs a non-ASCII character, save it as UTF-8 with BOM.
  Never UTF-16.
- LF line endings in the repository. The `.gitattributes` that sets `text eol=lf`
  for `*.ps1`, `*.psm1` and `*.psd1` is added by #44; until then this part is
  checked by review.
- Every file ends with a final newline.

Checked by #44 once it adds `.gitattributes` and the line-ending check; the BOM and
UTF-16 rules are checked by review.

### R-12 Branching (switch vs if)

Rule: an `if`/`elseif` chain that compares ONE variable to 3 or more constants with
`-eq` must be a `switch`. Every `switch` has a `default` clause. In a `switch` whose
cases can overlap (`-Regex`, `-Wildcard`, or a script-block condition), every
non-default case ends with `break` or `continue`. Duplicate constant labels are an
error.

Checked by review.

## Execution context

These rules capture what is known about how Tanium runs a script. Where a behavior
is not yet confirmed, the rule says so and takes the conservative position.

### R-13 Runtime version

Rule: anything that runs on an endpoint (sensors, platform packages, deploy
packages) MUST stay compatible with Windows PowerShell 5.1. Use `#Requires -Version
5.1` and avoid cmdlets and syntax that only exist in PowerShell 7.

Checked by review (`#Requires -Version 5.1` presence is part of the header check in
#45).

### R-14 Runtime bitness

Rule: the Tanium Client routes package actions through a 32-bit process by default.
A script that must reach a 64-bit location uses `Sysnative` for file paths or
`RegistryView.Registry64` for the registry, rather than assuming a 64-bit process.
The documented `Sysnative` relaunch pattern is the only allowed `powershell.exe`
relaunch.

Checked by #46 (no `powershell.exe` relaunch except the documented `Sysnative`
pattern); the `RegistryView.Registry64` rule is checked by review.

### R-15 Host

Rule: packages run under Tanium's own PowerShell host (`TPowershell.exe`), which may
restrict `Import-Module`. The exact behavior (module import, dot-sourcing payload
files, language mode, execution policy) is recorded once #69 runs, which is
deferred. Until then, the conservative rule is: packages MUST NOT rely on
`Import-Module`. Shared code is inlined into the script or dot-sourced from the
payload, and stays Constrained Language Mode-safe.

Checked by review (deferred to #69).

### R-16 Shared code in sensors

Rule: a sensor's script body is stored in the Tanium console and sent to endpoints
as text. It has no payload of its own, so it cannot dot-source a file shipped beside
it. Shared code reaches a sensor in one of two ways:

1. Inlined at build time (the default): the build step (issue #68) pastes the shared
   file into the sensor body between `# region shared-<name> <version> <sha256>`
   markers, and CI fails on a stale copy. A fix means updating every sensor that
   carries it in the console.
2. `Import-Module` of a module already on the endpoint (possible, not yet confirmed;
   check in #69): a platform package installs the module to a fixed, admin-only
   path, and the sensor imports it by full path. This patches in one place, but
   every sensor then depends on that package having run, and on the endpoint having
   the right version. A sensor whose import fails must return its defined error row
   (rule R-21), never an empty result. The path must be writable only by
   administrators and SYSTEM.

Keep shared code in sensors to small, stable, read-only helpers. Sensors do not log.

Checked by review (the #68 build step and CI stale-copy failure, and the #69 host
confirmation, are not yet landed).

## Sensors

### R-17 Read-only

Rule: a sensor MUST be read-only. It MUST NOT write files, registry values, or
logs, and MUST NOT call any state-changing command.

Checked by #46 (an allowlist of read verbs, with named exceptions).

### R-18 Runtime

Rule: a sensor MUST finish in under 1000 ms on target endpoints. This is a
repository requirement for all sensors in this repo, regardless of the Tanium
console's configurable runtime indicators.

Checked by review (runtime is measured, not parsed).

### R-19 No prompts

Rule: a sensor MUST NOT prompt. No `Read-Host`, no `Start-Sleep`, no `Write-Host`,
and no interactive UI.

Checked by #46 (no `Write-Host`, `Read-Host`, or `Start-Sleep`).

### R-20 Output shape

Rule: a sensor returns one row per line. For multiple values, columns are
pipe-delimited with a fixed column count that matches the sensor definition in
Tanium. For a single value, the sensor returns a simple string. Do not join all
rows into one string.

```powershell
Write-Output 'ComputerModel|Version|Build'   # one row, three columns
Write-Output 'Microsoft Windows 11 Pro'      # single value, simple string
```

Checked by #46 (output only through the success stream); the fixed column count and
delimiter are checked by review against the sensor definition.

### R-21 Error row and exit codes

Rule: a sensor that fails returns a defined error row as its result, never an empty
result. The error row is documented in the sensor's help block. A sensor ends with
a defined exit code (0 for a result or a handled error row, non-zero only when the
sensor itself cannot run).

Checked by review.

## Platform packages

### R-22 Idempotent

Rule: a platform package MUST be idempotent. It MUST check the current state before
it makes a change, and running it twice must produce the same result as running it
once.

Checked by review.

### R-23 SupportsShouldProcess

Rule: a state-changing platform package MUST declare
`[CmdletBinding(SupportsShouldProcess)]` and wrap each change in
`$PSCmdlet.ShouldProcess` (issue #4), so `-WhatIf` and `-Confirm` work. This rule
does not apply to deploy packages (rule R-26).

Checked by #46.

### R-24 Logging location

Rule: a platform package MUST write its log to a defined location. Choose a fixed,
documented path (for example under `$env:SystemDrive\Windows\Temp` or a
package-specific folder), state it in the header, and do not log to the current
working directory, which is not stable under Tanium.

Checked by review.

### R-25 Rate limiting

Rule: a platform package that does expensive work (large downloads, disk scans,
network traffic, or runs longer than about 30 seconds) SHOULD rate-limit itself so
it does not hammer an endpoint on every action (issue #12). Use the registry
rate-limiting pattern from `Packages/Templates/RateLimiting-Helpers.ps1`, copying
the helpers into the package. This pattern does not apply to deploy packages, which
use Tanium Deploy's own controls.

Checked by review.

## Deploy packages

### R-26 Install, update, remove

Rule: a deploy package handles the software lifecycle: install, update, and remove.
It SHOULD be idempotent. It MUST NOT declare `SupportsShouldProcess` or rely on
`-WhatIf`: Tanium Deploy owns the preview, so a deploy package is exempt from rule
R-23.

Checked by review (#46 exempts deploy packages from the `SupportsShouldProcess`
check).

### R-27 Exit codes

Rule: a deploy package MUST return the exit codes Tanium Deploy treats as success,
and nothing misleading on failure.

| Code | Meaning | Deploy action |
| --- | --- | --- |
| 0 | Success | Treat as success |
| 3010 | Success, reboot required | Treat as success |
| 1641 | Success, reboot initiated | Treat as 0 (success) |
| 1605 | Product not found | Treat as success on a Remove operation only |
| 1638 | Another version installed | Treat as success when the product code is already installed |
| 1618 | Another installation in progress | Retry, not success |

For MSI-based packages, see the generated metadata specification in
`docs/Tanium-Deploy-Package-Metadata-Specification.md`. The pipeline and module
design documents under `docs/` (`Pipeline-Automation-Design.md`,
`TaniumDeployPackage-Module-Design.md`) are proposals, not current rules.

Checked by review.

## Admin and API scripts

### R-28 Run from an admin workstation

Rule: an admin/API script runs from an admin workstation, outside Tanium. It MAY use
PowerShell 7, and MUST declare elevation with `#Requires -RunAsAdministrator` when
it needs it. It MUST check that the required Tanium components exist and handle a
missing component.

Checked by review.

### R-29 Full comment-based help

Rule: an admin/API script and its functions MUST support `Get-Help` with at least
two `.EXAMPLE` entries, and every parameter documented with `.PARAMETER`.

Checked by #45 (presence) and #48 (grade Complete).

## Package and sensor combo

### R-30 Work over 1000 ms

Rule: when a read operation would exceed the sensor runtime limit (rule R-18), split
it into a package and sensor combo (issue #13). The package performs the long
operation and writes a result artifact to a defined path. The sensor reads the
artifact in under 1000 ms and returns the result, with a distinct error row when the
artifact is missing, empty, or unreadable.

Checked by review.

## Enforcement

### R-31 Baseline

Rule: every rule above is an error for new and changed code. Violations that already
exist are recorded in a checked-in baseline with one entry per file and per rule.
CI fails on a violation that is not in the baseline, and fails when a baselined
violation has been fixed but its entry is still listed, so the baseline only ever
shrinks. A PR that edits a file makes that file compliant and removes its baseline
entries in the same PR.

Checked by #44.
