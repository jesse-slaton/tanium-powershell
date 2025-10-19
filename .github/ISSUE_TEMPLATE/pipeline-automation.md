# Automation and Pipeline Support for Tanium Deploy Package Generation

## Summary
Provide documentation, examples, and tooling to enable organizations to build automated pipelines for generating and maintaining Tanium Deploy packages from various sources (WinGet, Microsoft Update Catalog, etc.).

## Background
Building on the work completed in:
- **#7** - WinGet package generation (`Get-WinGetPackage.ps1`)
- **#8** - Windows Update Catalog package generation (`Get-UpdateCatalogPackage.ps1`)

Both scripts can generate Tanium Deploy packages, but currently require manual execution. Organizations need guidance and tooling to build environment-specific automation pipelines that respect their security constraints.

## Key Constraint: Environment-Specific Deployment
**Tanium API ACLs** require pipeline runners to operate from:
- Self-hosted runners within the corporate network
- Internal CI/CD systems (Jenkins, Azure DevOps on-prem, GitLab self-hosted)
- Scheduled tasks on internal servers with Tanium API access
- **NOT** public cloud CI/CD or GitHub Actions hosted runners

Therefore, this issue focuses on **documentation and reusable tooling** rather than a one-size-fits-all pipeline implementation.

## Proposed Documentation

### 1. Pipeline Architecture Guide
**Location**: `docs/automation/pipeline-architecture.md`

**Content**:
- Overview of automation approaches (scheduled, on-demand, event-driven)
- Network and security considerations for Tanium API integration
- Self-hosted runner setup examples (GitHub Actions, Azure DevOps, Jenkins)
- Air-gapped environment considerations
- Storage and artifact management strategies

### 2. Configuration File Specification
**Location**: `docs/automation/configuration-spec.md`

**Content**:
Define standard configuration format for bulk package generation:

```yaml
# Example: packages.yml
metadata:
  generatedBy: "Automation Pipeline v1.0"
  organization: "Contoso Corp"
  lastUpdated: "2025-01-18"

packages:
  # WinGet packages
  - source: winget
    packageId: 7zip.7zip
    architecture: [x64]
    scope: machine
    downloadInstallers: true
    enabled: true

  - source: winget
    packageId: Microsoft.PowerShell
    architecture: [x64, arm64]
    scope: machine
    downloadInstallers: true
    enabled: true

  - source: winget
    packageId: Google.Chrome
    architecture: [x64]
    scope: machine
    downloadInstallers: false  # Tanium Server will fetch
    enabled: false  # Skip in automation

  # MSIX packages with dependencies
  - source: winget
    packageId: 9MSMLRH6LZF3  # Windows Notepad (msstore)
    scope: user
    downloadInstallers: true
    includeDependencies: true  # Creates separate packages for dependencies
    enabled: true

  # Windows Update Catalog packages
  - source: catalog
    kb: KB5066835
    operatingSystem: "Windows 11"
    osRelease: "25H2"
    architecture: x64
    downloadAll: false
    enabled: true

settings:
  outputPath: "./Output/Packages"
  logPath: "./Output/Logs"
  parallelism: 4
  retryAttempts: 3
  retryDelaySeconds: 30
```

### 3. Bulk Generation Script
**Location**: `Admin/Pipeline/Invoke-BulkPackageGeneration.ps1`

**Purpose**: Read configuration file and generate multiple packages

**Features**:
- Read YAML/JSON configuration
- Parallel package generation with configurable concurrency
- Error handling with retry logic
- Detailed logging and progress reporting
- Exit codes for CI/CD integration
- JSON output for pipeline consumption

**Example Usage**:
```powershell
# Generate all enabled packages
.\Invoke-BulkPackageGeneration.ps1 -ConfigFile packages.yml

# Generate specific packages only
.\Invoke-BulkPackageGeneration.ps1 -ConfigFile packages.yml -Filter "7zip","PowerShell"

# Dry run mode
.\Invoke-BulkPackageGeneration.ps1 -ConfigFile packages.yml -WhatIf

# JSON output for parsing
.\Invoke-BulkPackageGeneration.ps1 -ConfigFile packages.yml -OutputFormat JSON
```

### 4. Pipeline Examples
**Location**: `examples/pipelines/`

**Content**:
- `github-actions-self-hosted.yml` - GitHub Actions with self-hosted runner
- `azure-devops-pipeline.yml` - Azure DevOps on-premises pipeline
- `jenkins-pipeline.groovy` - Jenkins declarative pipeline
- `scheduled-task-example.ps1` - Windows Scheduled Task wrapper
- `docker-compose.yml` - Containerized pipeline example

### 5. Exit Code Reference
**Location**: `docs/automation/exit-codes.md`

**Content**:
Document all exit codes for automation:

| Exit Code | Meaning | Example |
|-----------|---------|---------|
| 0 | Success | Package generated successfully |
| 1 | General error | Missing dependencies, network failure |
| 2 | Invalid parameters | Missing required argument |
| 3 | Package not found | WinGet package ID doesn't exist |
| 4 | Download failed | Network timeout, file not available |
| 5 | Generation failed | Script generation error |
| 6 | User cancellation | Ctrl+C during operation |

### 6. Logging and Observability
**Location**: `docs/automation/logging.md`

**Content**:
- Structured logging format (JSON, CSV)
- Log rotation and retention
- Integration with monitoring systems
- Alerting on failures
- Metrics to track (success rate, generation time, package size)

## Proposed Tooling Enhancements

### Script Improvements (Already Completed ✅)
- [x] Proper exit codes (0 for success, non-zero for errors)
- [x] Replace `return` with `exit` in error paths
- [x] Explicit `exit 0` on success

### Additional Script Features (To Do)
- [ ] JSON output mode for structured data
- [ ] Quiet mode for CI/CD (suppress progress, only show errors)
- [ ] Force mode to overwrite existing packages
- [ ] Version comparison (skip if already generated)
- [ ] Lock file support to prevent concurrent generation

### Bulk Generation Script Features
- [ ] Configuration file validation
- [ ] Parallel execution with configurable workers
- [ ] Resume capability (skip completed packages)
- [ ] Summary report generation
- [ ] Email/webhook notifications
- [ ] Integration with version control (commit generated packages)

## Testing Requirements
- [ ] Exit code validation tests
- [ ] Configuration parsing tests
- [ ] Bulk generation error handling tests
- [ ] Pipeline example validation

## Documentation Structure
```
docs/
├── automation/
│   ├── README.md
│   ├── pipeline-architecture.md
│   ├── configuration-spec.md
│   ├── exit-codes.md
│   └── logging.md
examples/
├── pipelines/
│   ├── README.md
│   ├── github-actions-self-hosted.yml
│   ├── azure-devops-pipeline.yml
│   ├── jenkins-pipeline.groovy
│   ├── scheduled-task-example.ps1
│   └── docker-compose.yml
├── configurations/
│   ├── basic-winget-packages.yml
│   ├── enterprise-catalog.yml
│   └── mixed-sources.yml
Admin/Pipeline/
├── Invoke-BulkPackageGeneration.ps1
├── Test-PackageConfiguration.ps1
└── README.md
```

## Success Criteria
- [ ] Comprehensive documentation for building organization-specific pipelines
- [ ] Working examples for common CI/CD platforms
- [ ] Bulk generation script handles errors gracefully
- [ ] All scripts have proper exit codes for automation
- [ ] Configuration schema is documented and validated
- [ ] Organizations can adapt examples to their environment without code changes

## Related Issues
- #7 - WinGet Package Generation
- #8 - Windows Update Catalog Package Generation

## MSIX/AppX Package Dependencies

### Overview
Microsoft Store (msstore) packages often have dependencies (e.g., Windows Notepad requires VCLibs, UI.Xaml frameworks). The package generation scripts support two modes for handling dependencies:

### All-in-One Mode (Default)
**Behavior**: Single Tanium Deploy package with install/remove scripts that handle all dependencies.

**Generated Structure**:
```
WindowsNotepad/
└── 1.0.0/
    └── user/
        ├── Install-WindowsNotepad.ps1     # Installs dependencies + main package
        ├── Remove-WindowsNotepad.ps1      # Removes main package (+ provisioned if machine scope)
        ├── tanium-deploy-metadata.json
        ├── WindowsNotepad.msixbundle      # Main package
        ├── Microsoft.VCLibs.140.00_14.0.30704.0_x64.appx  # Dependencies
        └── Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64.appx
```

**Install Script Behavior**:
- Idempotent: Checks if package already installed before proceeding
- Installs dependencies first (if not already installed)
- Installs main package
- Uses `Add-AppxPackage` (user scope) or `Add-AppxProvisionedPackage` (machine scope)

**Use Case**: Simplest deployment - single Tanium package to deploy and manage.

---

### Separate Dependencies Mode
**Flag**: `-IncludeDependencies`

**Behavior**: Creates separate Tanium Deploy packages for each dependency in `dependencies/` subdirectory.

**Generated Structure**:
```
WindowsNotepad/
└── 1.0.0/
    └── user/
        ├── Install-WindowsNotepad.ps1              # Installs ONLY main package
        ├── Remove-WindowsNotepad.ps1               # Removes ONLY main package
        ├── tanium-deploy-metadata.json
        ├── WindowsNotepad.msixbundle               # Main package only
        └── dependencies/
            ├── Microsoft.VCLibs.140.00/
            │   └── 14.0.30704.0/
            │       └── user/
            │           ├── Install-Microsoft.VCLibs.140.00.ps1
            │           ├── Remove-Microsoft.VCLibs.140.00.ps1
            │           ├── tanium-deploy-metadata.json
            │           └── Microsoft.VCLibs.140.00_14.0.30704.0_x64.appx
            └── Microsoft.UI.Xaml.2.8/
                └── 8.2310.30001.0/
                    └── user/
                        ├── Install-Microsoft.UI.Xaml.2.8.ps1
                        ├── Remove-Microsoft.UI.Xaml.2.8.ps1
                        ├── tanium-deploy-metadata.json
                        └── Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64.appx
```

**Package Behavior**:
- Main package install script does NOT install dependencies
- Each dependency is a fully independent Tanium Deploy package with:
  - Own install/remove scripts
  - Own metadata JSON
  - Own installer artifact
  - Product/Version/Scope directory structure

**Use Case**:
- Dependencies are shared across multiple applications
- Organization wants fine-grained control over dependency deployment
- Dependency versioning needs to be managed independently

---

### Pipeline Automation for Dependencies

**CI/CD Pipeline Requirements**:
When `-IncludeDependencies` is used, the automation pipeline **MUST**:

1. **Discover Dependency Packages**: Scan `dependencies/` subdirectory for all Tanium packages
2. **Check Existing Packages**: Query Tanium API to check if dependency package/version already exists
3. **Import Dependencies First**: Import dependencies to Tanium before importing main package
4. **Avoid Duplicate Imports**: Skip import if package with same name/version already exists
5. **Handle Import Failures**: Fail main package import if dependencies fail to import

**Example Pipeline Logic** (pseudocode):
```powershell
# After generating packages with -IncludeDependencies
$mainPackageDir = "WindowsNotepad/1.0.0/user"
$dependenciesDir = Join-Path $mainPackageDir "dependencies"

if (Test-Path $dependenciesDir) {
    # Find all dependency packages
    $depPackages = Get-ChildItem -Path $dependenciesDir -Recurse -Filter "tanium-deploy-metadata.json"

    foreach ($depMetadata in $depPackages) {
        $metadata = Get-Content $depMetadata | ConvertFrom-Json
        $packageName = $metadata.productName
        $packageVersion = $metadata.productVersion

        # Check if already exists in Tanium
        $existingPackage = Get-TaniumPackage -Name $packageName -Version $packageVersion

        if ($existingPackage) {
            Write-Host "Dependency already exists: $packageName v$packageVersion - SKIPPING"
            continue
        }

        # Import dependency package to Tanium
        Write-Host "Importing dependency: $packageName v$packageVersion"
        Import-TaniumPackage -Path $depMetadata.DirectoryName -Metadata $depMetadata
    }
}

# After all dependencies imported, import main package
Import-TaniumPackage -Path $mainPackageDir
```

**Important Notes**:
- Dependencies are imported as **separate Tanium packages**, not as part of the main package
- Main package does NOT have a deployment dependency on these packages in Tanium (dependencies are for organization/tracking only)
- If dependencies are required BEFORE main package, that must be handled by deployment orchestration (package chaining, deployment groups, etc.)

---

### Idempotency Considerations

**All-in-One Scripts**:
- Install script checks if main package already installed (via `Get-AppxPackage`)
- If installed, exits 0 (success) without reinstalling
- Dependencies are installed with error suppression (may already exist)

**Separate Dependency Scripts**:
- Each dependency install script is idempotent
- Checks if dependency already installed before attempting installation
- Safe to run multiple times

---

### Tanium Detection for MSIX Packages

**Detection Method**: AppX Package (not registry-based)

**Format**:
```
installVerification: AppX Package "*PackageId*" >= "Version"
updateDetection: AppX Package "*PackageId*" >= "Version"
```

**Example**:
```json
{
  "installVerification": "AppX Package \"*9MSMLRH6LZF3*\" >= \"1.0.0\"",
  "updateDetection": "AppX Package \"*9MSMLRH6LZF3*\" >= \"1.0.0\""
}
```

**Reference**: [Tanium Deploy Attributes Reference - AppX Package Detection](https://help.tanium.com/bundle/ug_deploy_cloud/page/deploy/attributes_reference.html)

---

## Notes
- This is **not** a one-size-fits-all CI/CD solution
- Focus is on **tooling and documentation** for organizations to build their own pipelines
- Must respect Tanium API ACL requirements (self-hosted runners, internal networks)
- Organizations have different security, network, and operational requirements
- **MSIX dependency handling**: Choose all-in-one (simple) or separate packages (granular control) based on organizational needs
