# Claude Context for tanium-powershell

## Repository Purpose
PowerShell sensors (read-only data collection) and packages (state-changing deployments) for Tanium endpoint management platform. Scripts run on production endpoints at scale.

## Current State
- **Status**: Initial import complete, refactoring in progress
- **Active branch**: `refactoring` for ongoing improvements
- **Created**: 2025-10-14 from monolithic script collection reorganization

## Repository Structure
```
tanium-powershell/
  Sensors/       # Read-only data collection scripts (run frequently on endpoints)
  Packages/      # State-changing deployment scripts
  Shared/        # Dual-use scripts
  Modules/       # PowerShell modules
  Tests/         # Pester tests
  docs/          # Documentation
  Templates/     # Script templates
```

## Key Standards & Documentation
- **DOCUMENTATION_STANDARDS.md**: Required patterns for all scripts
- **DEV_ENVIRONMENT.md**: Development environment setup
- **docs/TANIUM_NAMING_CONVENTION.md**: Naming conventions

## Owner Requirements
The repository owner requires assistance with:

1. **Headers/Comments**: Complete, consistent comment-based help for all scripts
2. **Parameters**: Standardized common parameters across similar scripts (e.g., -Force, -WhatIf)
3. **Pester Tests**: Test coverage for all functionality
4. **Documentation**: General usage documentation and patterns

## Critical Context
- Scripts execute on production endpoints at scale
- Performance matters (sensors have <1000ms execution time requirements)
- Resource-intensive operations need rate limiting to prevent endpoint impact
- Changes must be production-ready and enterprise-quality

## Development Workflow
1. Follow naming conventions
2. Write tests for all new scripts
3. Add comment-based help to all functions
4. Run PSScriptAnalyzer before committing
5. Use feature branches for changes
6. Documentation changes go through the same review process as code

## Related Repository
- **powershell-utilities**: Separate repo with its own context (see `.claude/context.md` there)

## Current Work (As of 2025-10-15)
- **Issue 12**: Rate limiting standardization - implementation complete, needs commit
  - Helper functions created
  - Enumeration sensor created
  - Cleanup package created
  - Documentation updated in DOCUMENTATION_STANDARDS.md

---
Last Updated: 2025-10-15
