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

