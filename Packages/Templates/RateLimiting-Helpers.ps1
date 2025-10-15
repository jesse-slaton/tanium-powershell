# Rate Limiting Helper Functions
# Purpose: Inline functions for copy-paste into Platform Packages
# Author: Jesse Slaton
# Created: 2025-10-15
#
# Usage: Copy required functions directly into your package script
#
# Registry Structure:
#   Base: HKLM:\SOFTWARE\[WOW6432Node\]Tanium\Tanium Client\Sensor Data\RateLimits\<PackageName>
#   Values:
#     - ExpiresAt (String): RFC822 format "Mon, 05 Jan 2015 15:17:59 +0000"
#     - SetAt (String): RFC822 format when rate limit was set

# ============================================================================
# HELPER FUNCTIONS - Copy these into your package script
# ============================================================================

function Get-RateLimitRegistryPath {
    param([string]$PackageName)
    if ([Environment]::Is64BitOperatingSystem) {
        "SOFTWARE\WOW6432Node\Tanium\Tanium Client\Sensor Data\RateLimits\$PackageName"
    } else {
        "SOFTWARE\Tanium\Tanium Client\Sensor Data\RateLimits\$PackageName"
    }
}

function Test-RateLimitExpired {
    param([string]$PackageName)

    $regPath = Get-RateLimitRegistryPath $PackageName
    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $false)

    if ($null -eq $regKey) { return $true }

    try {
        $expiresAt = $regKey.GetValue("ExpiresAt")
        if ($null -eq $expiresAt) { return $true }

        $expDate = [DateTime]::ParseExact($expiresAt, "ddd, dd MMM yyyy HH:mm:ss zzz", [System.Globalization.CultureInfo]::InvariantCulture)
        return ([DateTime]::UtcNow -ge $expDate)
    }
    catch {
        return $true
    }
    finally {
        if ($null -ne $regKey) { $regKey.Close() }
    }
}

function Set-RateLimit {
    param([string]$PackageName, [int]$Hours = 24)

    $regPath = Get-RateLimitRegistryPath $PackageName
    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $true)

    if ($null -eq $regKey) {
        $regKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey($regPath)
    }

    try {
        $expires = (Get-Date).ToUniversalTime().AddHours($Hours)
        $expiresRFC822 = $expires.ToString("ddd, dd MMM yyyy HH:mm:ss +0000", [System.Globalization.CultureInfo]::InvariantCulture)
        $setAtRFC822 = (Get-Date).ToUniversalTime().ToString("ddd, dd MMM yyyy HH:mm:ss +0000", [System.Globalization.CultureInfo]::InvariantCulture)

        $regKey.SetValue("ExpiresAt", $expiresRFC822, [Microsoft.Win32.RegistryValueKind]::String)
        $regKey.SetValue("SetAt", $setAtRFC822, [Microsoft.Win32.RegistryValueKind]::String)
    }
    finally {
        if ($null -ne $regKey) { $regKey.Close() }
    }
}

# ============================================================================
# USAGE EXAMPLES
# ============================================================================

<#
# Example 1: Basic rate limiting (run once per week)
if (Test-RateLimitExpired "MyPackage") {
    # Perform resource-intensive operation
    Write-Output "Executing operation..."

    # Set rate limit for 7 days (168 hours)
    Set-RateLimit "MyPackage" -Hours 168
    Write-Output "Completed. Rate limited for 7 days."
} else {
    Write-Output "Rate limited. Run skipped."
}

# Example 2: With detailed output
$packageName = "FindPSTFiles"
if (Test-RateLimitExpired $packageName) {
    Write-Output "Starting PST search..."

    # ... filesystem search logic ...

    Set-RateLimit $packageName -Hours 168
    Write-Output "Search complete. Next run allowed after 7 days."
} else {
    $regPath = Get-RateLimitRegistryPath $packageName
    $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($regPath, $false)
    $expiresAt = $regKey.GetValue("ExpiresAt")
    $regKey.Close()
    Write-Output "Rate limited. Expires: $expiresAt"
}

# Example 3: Force execution with parameter
param([switch]$Force)

if ($Force -or (Test-RateLimitExpired "MyPackage")) {
    # Execute operation
    Set-RateLimit "MyPackage" -Hours 24
} else {
    Write-Output "Rate limited. Use -Force to override."
}
#>
