#Requires -Version 5.1

<#
.SYNOPSIS
    Downloads the Sysinternals Suite and extracts it into C:\Bin.

.DESCRIPTION
    Defines and runs Update-Sysinternals with its default values. It downloads
    https://live.sysinternals.com/Files/SysinternalsSuite.zip to
    $env:TEMP\SysinternalsSuite.zip, stops any running ZoomIt, ZoomIt64, Desktops,
    procexp and procexp64 processes, waits for each stopped process to exit, expands the
    zip into C:\Bin overwriting existing files, then restarts the stopped programs
    (except those whose process name ends in 64) whose executable lives under C:\Bin and
    that were confirmed to have exited. It never restarts a path outside the install
    root. The downloaded zip is left in $env:TEMP.

    A process that survives Stop-Process aborts the run before extraction with an error
    and a non-zero exit. A failed download or extraction also writes an error and exits
    non-zero, and the processes confirmed gone are still restarted by the recovery scope
    before the exit. Invoke-WebRequest and Stop-Process write verbose messages.

    The script takes no parameters. The function's -NewPath, -OldPath and -BaseDir
    parameters are only reachable by editing the call at the end of the script.

.EXAMPLE
    .\Get-Sysinternals-Sensor.ps1

    Downloads the current Sysinternals Suite and extracts it into C:\Bin.

.NOTES
    Requires PowerShell 5.1 or later (#Requires -Version 5.1; Expand-Archive) and
    internet access to live.sysinternals.com. Needs write access to C:\Bin. This
    script changes files and stops processes, so it is a platform package, not a
    sensor.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/System/Get-Sysinternals-Sensor.ps1.
#>


function Update-Sysinternals {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        $NewPath = "https://live.sysinternals.com/Files/SysinternalsSuite.zip",
        $OldPath = "$Env:Temp\SysinternalsSuite.zip",
        $BaseDir = "C:\Bin"
    )

    $Stopped = @()
    $Restartable = @()
    $Failed = $false
    try {

        # Download the new zip file of tools.
        if ($PSCmdlet.ShouldProcess($NewPath, 'Download Sysinternals Suite')) {
            Invoke-WebRequest -UseBasicParsing -Uri $NewPath -OutFile $OldPath -Method Get -Verbose
        }

        # Some Sysinternals apps are often locked, so stop them before replacing files.
        # Match exact process names: a wildcard such as desktops* would also match unrelated
        # processes (the review found the Windows 11 DesktopStickerEditor being force-killed).
        # SilentlyContinue because none of these processes may be running, which Get-Process
        # reports as a "cannot find a process" error.
        $Running = Get-Process -Name ZoomIt, ZoomIt64, Desktops, procexp, procexp64 -ErrorAction SilentlyContinue

        # Capture the restart details before each process exits, then stop it.
        foreach ($Process in $Running) {
            if ($PSCmdlet.ShouldProcess($Process.Name, 'Stop process')) {
                $Stopped += [pscustomobject]@{
                    Name = $Process.Name
                    Path = $Process.Path
                    Id   = $Process.Id
                }
                # SilentlyContinue because the process may have exited between listing and stopping it.
                Stop-Process -Id $Process.Id -Force -Verbose -ErrorAction SilentlyContinue
            }
        }

        # Wait for each stopped process to actually exit before replacing its files. Only a
        # process confirmed gone is marked for restart: a survivor still holds its executable,
        # so expanding the zip over it would fail, and restarting it would spawn a second
        # instance.
        $Survivors = @()
        foreach ($Process in $Stopped) {
            # SilentlyContinue because Wait-Process reports an error if the process is already gone.
            Wait-Process -Id $Process.Id -Timeout 10 -ErrorAction SilentlyContinue
            # SilentlyContinue because the process is gone after a successful wait.
            $Remaining = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
            if ($Remaining -and -not $Remaining.HasExited) {
                $Survivors += $Process
            }
            else {
                $Restartable += $Process
            }
        }
        if ($Survivors.Count -gt 0) {
            $survivorNames = ($Survivors | ForEach-Object { "$($_.Name) (PID $($_.Id))" }) -join ', '
            throw "Process(es) still running after Stop-Process: $survivorNames"
        }

        # Expand the downloaded zip into the install root, overwriting existing files.
        if ($PSCmdlet.ShouldProcess($BaseDir, 'Extract Sysinternals Suite')) {
            Expand-Archive -LiteralPath $OldPath -DestinationPath $BaseDir -Force
        }
    }
    catch {
        Write-Error "Failed to update Sysinternals: $($_.Exception.Message)"
        $Failed = $true
    }
    finally {

        # Restart the applications that were confirmed gone, except *64 binaries and
        # except any executable outside $BaseDir. Before each elevated restart, verify
        # the trust boundary: the ACL of $BaseDir and of the executable must not grant
        # write-class rights to a non-trusted principal (see Test-TrustedRestartPath).
        $BaseDirTrust = $null
        foreach ($Process in $Restartable) {
            if ($Process.Name -notlike '*64' -and $Process.Path -like "$BaseDir\*") {
                if ($null -eq $BaseDirTrust) {
                    $BaseDirTrust = Test-TrustedRestartPath -Path $BaseDir
                }
                if (-not $BaseDirTrust.Trusted) {
                    Write-Error "Refusing to restart $($Process.Name): $BaseDir untrusted ($($BaseDirTrust.Reason))."
                    $Failed = $true
                    continue
                }
                $ExeTrust = Test-TrustedRestartPath -Path $Process.Path
                if (-not $ExeTrust.Trusted) {
                    Write-Error "Refusing to restart $($Process.Name): $($Process.Path) untrusted ($($ExeTrust.Reason))."
                    $Failed = $true
                    continue
                }
                if ($PSCmdlet.ShouldProcess($Process.Path, 'Restart')) {
                    try {
                        Start-Process -FilePath $Process.Path
                    }
                    catch {
                        # A failed restart must not skip the remaining restarts or the exit code.
                        Write-Warning "Failed to restart $($Process.Name): $($_.Exception.Message)"
                        $Failed = $true
                    }
                }
            }
        }
    }
    if ($Failed) {
        exit 1
    }
}

# Verify the trust boundary of a path before restarting an executable from it.
#
# Trust rule: the path is trusted only when no Allow access rule grants a write-class
# right (Write, Modify, FullControl, CreateFiles, or AppendData) to a principal other
# than BUILTIN\Administrators, NT AUTHORITY\SYSTEM, or NT SERVICE\TrustedInstaller. Such
# write access would let a non-trusted principal replace the executable, so an elevated
# restart must not run it. This only reads the ACL; it never changes it.
function Test-TrustedRestartPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $TrustedPrincipals = @(
        'BUILTIN\Administrators'
        'NT AUTHORITY\SYSTEM'
        'NT SERVICE\TrustedInstaller'
    )
    $WriteRights = @(
        [System.Security.AccessControl.FileSystemRights]::Write
        [System.Security.AccessControl.FileSystemRights]::Modify
        [System.Security.AccessControl.FileSystemRights]::FullControl
        [System.Security.AccessControl.FileSystemRights]::CreateFiles
        [System.Security.AccessControl.FileSystemRights]::AppendData
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Trusted = $false; Path = $Path; Reason = 'path not found' }
    }

    $Acl = Get-Acl -LiteralPath $Path
    foreach ($Rule in $Acl.Access) {
        if ($Rule.AccessControlType -ne [System.Security.AccessControl.AccessControlType]::Allow) {
            continue
        }
        $Identity = $Rule.IdentityReference.Value
        if ($TrustedPrincipals -contains $Identity) {
            continue
        }
        $Rights = [System.Security.AccessControl.FileSystemRights]$Rule.FileSystemRights
        foreach ($Right in $WriteRights) {
            if (($Rights -band $Right) -eq $Right) {
                return [pscustomobject]@{
                    Trusted = $false
                    Path    = $Path
                    Reason  = "writable by untrusted principal '$Identity'"
                }
            }
        }
    }

    return [pscustomobject]@{ Trusted = $true; Path = $Path; Reason = '' }
}

Update-Sysinternals
