# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| main branch | :white_check_mark: |
| Earlier commits | :x:                |

**Note**: This repository is under active development and reorganization. Security fixes are applied to the main branch only.

## Reporting a Vulnerability

We take security vulnerabilities seriously. Given the enterprise nature of Tanium deployments, vulnerabilities in these scripts could affect thousands of endpoints.

### How to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by:

1. **Using GitHub Security Advisories** (preferred)
   - Go to the [Security tab](https://github.com/jesse-slaton/tanium-powershell/security/advisories)
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Email** (alternative)
   - Send an email to the repository maintainer
   - Include "SECURITY - Tanium PowerShell" in the subject line
   - Provide detailed information about the vulnerability

### What to Include

When reporting a vulnerability, please include:

- **Script Name**: Which sensor/package is affected (include category folder)
- **Description**: A clear description of the vulnerability
- **Impact**: Potential impact on Tanium-managed endpoints
- **Attack Scenario**: How the vulnerability could be exploited at scale
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Tanium Version**: Which Tanium platform versions are affected (if relevant)
- **Suggested Fix**: If you have ideas for a fix (optional)
- **Proof of Concept**: Code that demonstrates the issue (if applicable)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your report within 24 hours (given enterprise impact)
- **Updates**: We will provide regular updates on our progress (at least every 3-5 days)
- **Timeline**: We aim to release a fix within 30-60 days for critical vulnerabilities
- **Credit**: We will credit you in the security advisory (unless you prefer to remain anonymous)

### Safe Harbor

We support safe harbor for security researchers who:

- Make a good faith effort to avoid privacy violations, data destruction, and service interruption
- Only test against your own Tanium environment or lab systems
- Do not test in production Tanium environments without explicit permission
- Do not exploit the vulnerability beyond the minimum necessary to demonstrate the issue
- Report vulnerabilities promptly
- Keep the vulnerability confidential until it has been resolved

We will not pursue legal action against researchers who follow these guidelines.

## Security Considerations for Tanium Scripts

### Enterprise Deployment Context

These scripts are designed for Tanium, an enterprise endpoint management platform:

- **Wide Deployment**: Scripts can be deployed to thousands of endpoints simultaneously
- **High Privileges**: Scripts often run with SYSTEM or administrative privileges
- **Sensitive Data**: Sensors collect system configuration and potentially sensitive information
- **State Changes**: Packages modify system state, install software, change configurations

### Script Categories and Risks

#### Sensors (Read-Only Data Collection)

**Purpose**: Collect system information and return to Tanium console

**Security Concerns**:
- **Information Disclosure**: May expose sensitive system data, credentials, or PII
- **Performance Impact**: Resource-intensive sensors can affect endpoint performance
- **Data Leakage**: Sensor output stored in Tanium database
- **Reconnaissance**: Sensors aid in environment mapping for attackers

**Risk Level**: Medium to High (depending on data collected)

#### Packages (State-Changing Operations)

**Purpose**: Deploy software, modify configurations, remediate issues

**Security Concerns**:
- **Arbitrary Code Execution**: Malicious packages can execute any code with SYSTEM privileges
- **Privilege Escalation**: Package vulnerabilities can be exploited for privilege escalation
- **Persistence**: Packages can create backdoors, scheduled tasks, or services
- **Data Destruction**: File operations can delete or corrupt critical data
- **Lateral Movement**: Network operations can be used for pivoting
- **Credential Theft**: Packages can access credentials in memory or on disk

**Risk Level**: Critical

#### Shared Scripts (Dual-Use)

**Security Concerns**: Combination of sensor and package risks

**Risk Level**: High to Critical

### Specific Security Risks

#### 1. Command Injection

```powershell
# Vulnerable
Invoke-Expression "Get-Process -Name $UserInput"

# Safer
Get-Process -Name $UserInput -ErrorAction SilentlyContinue
```

#### 2. Path Traversal

```powershell
# Vulnerable
Copy-Item -Path $UserPath -Destination "C:\Target"

# Safer
$SafePath = Resolve-Path -Path $UserPath
if ($SafePath.Path.StartsWith("C:\AllowedDir")) {
    Copy-Item -Path $SafePath -Destination "C:\Target"
}
```

#### 3. Credential Exposure

```powershell
# Vulnerable - credentials in script
$Password = "P@ssw0rd123"

# Safer - use Tanium secure parameters or Windows Credential Manager
$Password = Get-TaniumSecureParameter -Name "ServicePassword"
```

#### 4. Information Disclosure

```powershell
# Problematic - may return sensitive data
Get-ChildItem C:\Users -Recurse

# Better - limit scope and filter sensitive items
Get-ChildItem C:\Users -Directory | Where-Object {$_.Name -notlike ".*"}
```

#### 5. Unsafe XML/Web Requests

```powershell
# Vulnerable to XXE
[xml]$Config = Get-Content $UserFile

# Safer
$XmlSettings = New-Object System.Xml.XmlReaderSettings
$XmlSettings.XmlResolver = $null
$XmlSettings.ProhibitDtd = $true
$Reader = [System.Xml.XmlReader]::Create($UserFile, $XmlSettings)
```

### Tanium-Specific Security Features

1. **Action Approval Workflows**
   - Use Tanium's approval features for high-risk packages
   - Implement peer review for critical deployments

2. **Tanium Secure Parameters**
   - Store credentials as Tanium secure parameters
   - Never hardcode credentials in scripts

3. **Computer Group Targeting**
   - Test packages on pilot groups first
   - Use smart computer groups for controlled rollout

4. **Action Expiration**
   - Set appropriate expiration times for actions
   - Prevent indefinite package execution

5. **Action History and Auditing**
   - Review action results regularly
   - Monitor for unexpected failures or results

## Known Security Limitations

- **Work in Progress**: Scripts are being refactored; not all follow current security standards
- **No Code Signing**: Scripts are not currently code-signed
- **Limited Input Validation**: Some legacy scripts may have incomplete input validation
- **Documentation Gaps**: Security requirements may not be fully documented
- **Sensor Data Retention**: Sensitive data collected by sensors persists in Tanium database

## Security Best Practices

### For Script Authors

1. **Input Validation**
   - Validate all parameters
   - Use parameter validation attributes
   - Sanitize inputs before use in commands

2. **Least Privilege**
   - Request minimum necessary permissions
   - Document required privilege levels
   - Use `-WhatIf` and `-Confirm` for packages

3. **Error Handling**
   - Use `try/catch/finally` blocks
   - Avoid exposing sensitive data in error messages
   - Log errors appropriately

4. **Secure Coding**
   - Follow PowerShell best practices
   - Avoid `Invoke-Expression` with user input
   - Use parameterized queries for databases
   - Validate file paths and URLs

5. **Data Minimization**
   - Collect only necessary data in sensors
   - Filter out sensitive information
   - Implement data retention policies

6. **Testing**
   - Test in isolated environments first
   - Use Tanium's staging features
   - Verify rollback procedures

### For Tanium Administrators

1. **Package Review**
   - Review all packages before deployment
   - Understand what packages do
   - Verify source and integrity

2. **Access Control**
   - Restrict package authoring permissions
   - Use role-based access control (RBAC)
   - Implement approval workflows

3. **Monitoring**
   - Monitor package execution results
   - Set up alerts for failures
   - Review action history regularly

4. **Environment Isolation**
   - Test packages in non-production Tanium instances
   - Use separate environments for development/testing/production
   - Implement network segmentation

5. **Credential Management**
   - Rotate Tanium service credentials regularly
   - Use least-privilege service accounts
   - Audit credential access

6. **Logging and Auditing**
   - Enable PowerShell logging (module, script block, transcription)
   - Centralize logs to SIEM
   - Review logs for suspicious activity

## Common Vulnerability Types in Tanium Scripts

Be especially cautious of:

- **Command Injection**: Unsanitized parameters passed to `Invoke-Expression`, `&`, or external commands
- **Path Traversal**: File operations with user-controlled or parameter-controlled paths
- **Privilege Escalation**: Scripts that can be modified by low-privileged users
- **Credential Exposure**: Credentials in scripts, logs, or Tanium action results
- **Information Disclosure**: Sensitive data returned by sensors
- **Denial of Service**: Resource-intensive operations that affect endpoint performance
- **Persistence Mechanisms**: Unauthorized scheduled tasks, services, or startup items
- **Lateral Movement**: Network operations that could aid in pivoting
- **Data Exfiltration**: Scripts that send data to external destinations

## Tanium Security Architecture Considerations

1. **Client-Server Communication**
   - Tanium clients use UDP for peer-to-peer communication
   - Ensure firewalls allow necessary Tanium traffic
   - Monitor for unauthorized Tanium communications

2. **Result Size Limits**
   - Sensor results are limited by Tanium's max result size
   - Large results may be truncated
   - Design sensors to return concise, relevant data

3. **Action Approvals**
   - Configure approval requirements for high-risk packages
   - Implement multi-person approval for critical operations

4. **Content Management**
   - Use Tanium's content versioning
   - Track changes to sensors and packages
   - Implement change control processes

## Disclosure Policy

- We follow a **coordinated disclosure** policy
- Security issues will be disclosed publicly after a fix is available
- We will publish a security advisory with details of the vulnerability and the fix
- Critical vulnerabilities affecting enterprise deployments will be prioritized
- We may coordinate with Tanium Inc. if vulnerabilities affect the platform itself

## Contributing Security Fixes

If you'd like to contribute a security fix:

1. Report the vulnerability first (as described above)
2. Wait for acknowledgment before submitting a PR
3. Submit the PR to a private branch if requested
4. Include security impact assessment in PR description
5. Follow the coding standards in `DOCUMENTATION_STANDARDS.md`
6. Add tests that verify the fix
7. Update documentation to reflect security improvements

## Contact

For security-related questions that are not vulnerabilities, you can:

- Open a regular GitHub issue with the `security` label
- Use the Discussions tab for general security questions

**Note**: For Tanium platform security issues (not related to these scripts), contact Tanium Inc. directly through their security program.

Thank you for helping keep our Tanium deployments and enterprise environments safe!
