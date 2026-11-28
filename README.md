# tanium-powershell

## Status

**Initial import - reorganization in progress**

This repository was created from a reorganization of a monolithic PowerShell script collection.
Scripts are being refactored and improved according to the standards in DEV_ENVIRONMENT.md.

## Purpose

PowerShell sensors and packages for Tanium endpoint management platform

## Current State

- [x] Initial import complete
- [ ] Refactoring in progress
- [ ] Documentation being added
- [ ] Tests being written

## Structure

```
tanium-powershell/
  Sensors/       # Read-only data collection scripts
  Packages/      # State-changing deployment scripts
  Shared/        # Dual-use scripts
  Modules/       # PowerShell modules
  Tests/         # Pester tests
  docs/          # Documentation
  Templates/     # Script templates
```


## Prerequisites

### Required PowerShell Modules

```powershell
# Install required modules
Install-Module PSScriptAnalyzer, Pester -Scope CurrentUser -Force

# For specific scripts, you may also need:
# Install-Module ActiveDirectory, LidarrPS, AWSPowerShell -Scope CurrentUser
```

### External Repositories

Some scripts depend on external repositories. See `EXTERNAL_REPOS.txt` for:
- Repositories to fork/star
- Installation instructions
- Local path requirements

## Running the tests

The tests need Pester 5. Windows PowerShell 5.1 ships an older, Microsoft-signed Pester 3.4.0 that
blocks a plain install, so install with `-SkipPublisherCheck` and import version 5 explicitly
(otherwise the inbox 3.4.0 module is loaded):

```powershell
Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force -SkipPublisherCheck
```

From the repo root:

```powershell
Import-Module Pester -MinimumVersion 5.0
Invoke-Pester -Path ./Tests -Output Detailed
```

Each file in `Tests/Unit` is a stub for one script. A stub finds its script by exact file name
and checks it with the PowerShell parser. It never runs the script, so the suite does not change
the machine it runs on. A stub whose script is missing or ambiguous fails with a message that
names the script. The shared helpers are in `Tests/TestHelpers.psm1`.

## Getting Started

See [DEV_ENVIRONMENT.md](./DEV_ENVIRONMENT.md) for:
- Required tools (PowerShell, PSScriptAnalyzer, Pester)
- VS Code setup
- Git hooks configuration
- Development workflow

## Contributing

1. Follow the naming conventions in `docs/TANIUM_NAMING_CONVENTION.md`
2. Write tests for all new scripts
3. Add comment-based help to all functions
4. Run PSScriptAnalyzer before committing
5. Create feature branches for changes
6. Never commit a credential. Every pull request is scanned with
   [gitleaks](https://github.com/gitleaks/gitleaks) using the rules in `.gitleaks.toml`
   (the gitleaks defaults plus PowerShell patterns such as
   `ConvertTo-SecureString -AsPlainText`, connection-string passwords and literal
   `-Password` or `-Token` values). If the scan flags a harmless value, fix the rule or
   the value first. As a last resort for a real false positive, add a `gitleaks:allow`
   comment on the same line, and say why in the pull request. CI ignores that comment
   and any `.gitleaksignore` file, so it only silences a local `gitleaks` run. To let a
   value through in CI, an allowlist entry in `.gitleaks.toml` must merge first (the
   scan uses the copy of that file from the pull request's base commit).
7. Keep UTF-16 out of the repository. Secret scanners cannot read it, so CI fails any added
   or changed file, of any type, that starts with a UTF-16 byte order mark. `.ps1`, `.psm1`
   and `.psd1` files must also be UTF-8 (with a byte order mark when they hold non-ASCII
   text), never UTF-16 without a byte order mark either. `Tests/Encoding.Tests.ps1` is the
   fast local check, and the Gitleaks workflow enforces both rules on every commit of a pull
   request, so re-encoding the file in a later commit does not clear it.

## Documentation

- [DEV_ENVIRONMENT.md](./DEV_ENVIRONMENT.md) - Development environment setup
- [docs/MODULE_OPPORTUNITIES.md](./docs/MODULE_OPPORTUNITIES.md) - Module consolidation plans
- [docs/EXTERNAL_DEPENDENCIES.md](./docs/EXTERNAL_DEPENDENCIES.md) - External dependencies

## Next Steps

See the `refactoring` branch for ongoing improvements:
1. Add help documentation to all scripts
2. Implement WhatIf support for state-changing scripts
3. Write Pester tests
4. Consolidate related scripts into modules
5. Remove VBScript dependencies

---

Generated: 2025-10-14 16:43:22
Baseline: v0.1-baseline

