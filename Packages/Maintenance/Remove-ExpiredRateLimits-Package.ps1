<#
.SYNOPSIS
    Removes expired rate limit registry entries for Platform Packages.

.DESCRIPTION
    This package scans all rate limit entries under the Tanium Client Sensor Data
    registry path and removes expired entries to prevent registry bloat.

    Rate limits are stored in RFC822 format with Zulu time.
    Only entries where ExpiresAt < current UTC time are removed.

.NOTES
    Script Name : Remove-ExpiredRateLimits-Package.ps1
    Author      : Jesse Slaton
    Created     : 2025-10-15
    Modified    : 2025-10-15
    Version     : 1.0.0

    Platform    : Tanium Platform Package
    Requires    : PowerShell 5.1+

.EXAMPLE
    .\Remove-ExpiredRateLimits-Package.ps1

    Removes all expired rate limit entries and reports count.
#>

[CmdletBinding()]
param()

try {
    # Determine registry path based on OS bitness
    $basePath = if ([Environment]::Is64BitOperatingSystem) {
        "SOFTWARE\WOW6432Node\Tanium\Tanium Client\Sensor Data\RateLimits"
    } else {
        "SOFTWARE\Tanium\Tanium Client\Sensor Data\RateLimits"
    }

    Write-Output "Checking for expired rate limits..."

    # Open RateLimits key with write access
    $rateLimitsKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($basePath, $true)

    if ($null -eq $rateLimitsKey) {
        Write-Output "No rate limits configured. Nothing to clean."
        exit 0
    }

    $currentUtc = [DateTime]::UtcNow
    $expiredPackages = @()
    $totalPackages = 0

    # Enumerate all package subkeys
    foreach ($packageName in $rateLimitsKey.GetSubKeyNames()) {
        $totalPackages++
        $packageKey = $rateLimitsKey.OpenSubKey($packageName, $false)

        if ($null -ne $packageKey) {
            $expiresAt = $packageKey.GetValue("ExpiresAt")
            $packageKey.Close()

            if ($null -ne $expiresAt) {
                try {
                    $expDate = [DateTime]::ParseExact(
                        $expiresAt,
                        "ddd, dd MMM yyyy HH:mm:ss zzz",
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )

                    if ($currentUtc -ge $expDate) {
                        $expiredPackages += $packageName
                        Write-Output "Found expired: $packageName (Expired: $expiresAt)"
                    }
                }
                catch {
                    # Invalid date format - consider expired
                    $expiredPackages += $packageName
                    Write-Output "Found invalid: $packageName (Invalid date format)"
                }
            }
            else {
                # No ExpiresAt value - consider expired
                $expiredPackages += $packageName
                Write-Output "Found incomplete: $packageName (No ExpiresAt value)"
            }
        }
    }

    # Remove expired entries
    $removedCount = 0
    foreach ($packageName in $expiredPackages) {
        try {
            $rateLimitsKey.DeleteSubKeyTree($packageName)
            $removedCount++
            Write-Output "Removed: $packageName"
        }
        catch {
            Write-Output "Failed to remove: $packageName - $($_.Exception.Message)"
        }
    }

    $rateLimitsKey.Close()

    # Summary
    Write-Output ""
    Write-Output "Cleanup Summary:"
    Write-Output "  Total rate limits: $totalPackages"
    Write-Output "  Expired/Invalid: $($expiredPackages.Count)"
    Write-Output "  Successfully removed: $removedCount"
    Write-Output "  Active rate limits: $($totalPackages - $removedCount)"

    exit 0
}
catch {
    Write-Output "Error during cleanup: $($_.Exception.Message)"
    exit 1
}
