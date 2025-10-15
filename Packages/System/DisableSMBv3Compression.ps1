# Script: DisableSMBv3Compression.ps1
# Purpose: Disables SMBv3 compression to mitigate CVE-2020-0796 (SMBGhost)
# Author: Jesse Slaton
# Created: 2020-03-15
# Modified: 2025-10-14
#
# Tanium Package Specifications:
#   - Type: Platform Package (registry modification)
#   - Requires: Administrative privileges
#   - Idempotent: Safe to run multiple times
#
# Prerequisites:
#   - Run as Administrator
#   - Windows 10 1903+ or Windows Server 2019+
#
# Changes Made:
#   - Registry: HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters
#   - Key: DisableCompression
#   - Value: 0 (disabled)
#
# Security Note:
#   This mitigates CVE-2020-0796 (SMBGhost vulnerability)
#   Compression will be disabled on the SMB server

#Requires -RunAsAdministrator

$parameters = @{
    Path  = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    Name  = 'DisableCompression'
    Type  = 'DWORD'
    Value = 0
    Force = $true
}
Set-ItemProperty @parameters