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
        Invoke-WebRequest -UseBasicParsing -Uri $NewPath -OutFile $OldPath -Method Get -Verbose

        # Some Sysinternals apps are often locked, so stop them before replacing files.
        # Match exact process names: a wildcard such as desktops* would also match unrelated
        # processes (the review found the Windows 11 DesktopStickerEditor being force-killed).
        # SilentlyContinue because none of these processes may be running, which Get-Process
        # reports as a "cannot find a process" error.
        $Running = Get-Process -Name ZoomIt, ZoomIt64, Desktops, procexp, procexp64 -ErrorAction SilentlyContinue

        # Capture the restart details before each process exits, then stop it.
        foreach ($Process in $Running) {
            $Stopped += [pscustomobject]@{
                Name = $Process.Name
                Path = $Process.Path
                Id   = $Process.Id
            }
            # SilentlyContinue because the process may have exited between listing and stopping it.
            Stop-Process -Id $Process.Id -Force -Verbose -ErrorAction SilentlyContinue
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
        Expand-Archive -LiteralPath $OldPath -DestinationPath $BaseDir -Force
    }
    catch {
        Write-Error "Failed to update Sysinternals: $($_.Exception.Message)"
        $Failed = $true
    }
    finally {

        # Restart the applications that were confirmed gone, except *64 binaries and
        # except any executable outside $BaseDir (never restart a user-writable path).
        foreach ($Process in $Restartable) {
            if ($Process.Name -notlike '*64' -and $Process.Path -like "$BaseDir\*") {
                try {
                    Start-Process -FilePath $Process.Path
                }
                catch {
                    # A failed restart must not skip the remaining restarts or the exit code.
                    Write-Warning "Failed to restart $($Process.Name): $($_.Exception.Message)"
                }
            }
        }
    }
    if ($Failed) {
        exit 1
    }
}

Update-Sysinternals
