# Script: GetOSSetupDate.ps1
# Purpose: Retrieves the operating system installation date
# Author: Jesse Slaton
# Created: 2024-01-15
# Modified: 2025-10-14
#
# Tanium Sensor Specifications:
#   - Execution time: < 100ms
#   - Output format: Formatted date string
#   - Read-only: No system changes
#
# Prerequisites:
#   - Windows PowerShell 5.1 or later
#   - CIM access permissions
#
# Expected Output: Wed, 15 Jan 2024

Try {
    $InstallDate = (Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_OperatingSystem).InstallDate
    Get-Date $InstallDate -Format "ddd, dd MMM yyyy"
}
Catch {
    Write-Error "Could not determine the setup date."
}