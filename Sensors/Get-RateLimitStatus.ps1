# Script: Get-RateLimitStatus.ps1
# Purpose: Enumerate all Platform Package rate limits with expiration status
# Author: Jesse Slaton
# Created: 2025-10-15
#
# Tanium Sensor Specifications:
#   - Execution time: < 1000ms
#   - Output format: Pipe-delimited (PackageName|ExpiresAt|IsExpired)
#   - Read-only: No system changes
#
# Expected Output: Package1|Mon, 05 Jan 2015 15:17:59 +0000|True|Package2|Mon, 05 Jan 2015 15:17:59 +0000|False

try {
    # Determine registry path based on OS bitness
    $basePath = if ([Environment]::Is64BitOperatingSystem) {
        "SOFTWARE\WOW6432Node\Tanium\Tanium Client\Sensor Data\RateLimits"
    } else {
        "SOFTWARE\Tanium\Tanium Client\Sensor Data\RateLimits"
    }

    # Open RateLimits key
    $rateLimitsKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($basePath, $false)

    if ($null -eq $rateLimitsKey) {
        Write-Output "No rate limits configured"
        exit
    }

    $results = @()
    $currentUtc = [DateTime]::UtcNow

    # Enumerate all package subkeys
    foreach ($packageName in $rateLimitsKey.GetSubKeyNames()) {
        $packageKey = $rateLimitsKey.OpenSubKey($packageName, $false)

        if ($null -ne $packageKey) {
            $expiresAt = $packageKey.GetValue("ExpiresAt")

            if ($null -ne $expiresAt) {
                try {
                    $expDate = [DateTime]::ParseExact($expiresAt, "ddd, dd MMM yyyy HH:mm:ss zzz", [System.Globalization.CultureInfo]::InvariantCulture)
                    $isExpired = ($currentUtc -ge $expDate)
                    $results += "$packageName|$expiresAt|$isExpired"
                }
                catch {
                    $results += "$packageName|Invalid Date|True"
                }
            }
            else {
                $results += "$packageName|Not Set|True"
            }

            $packageKey.Close()
        }
    }

    $rateLimitsKey.Close()

    if ($results.Count -eq 0) {
        Write-Output "No rate limits configured"
    }
    else {
        Write-Output ($results -join "|")
    }
}
catch {
    Write-Output "Error: $($_.Exception.Message)"
}
