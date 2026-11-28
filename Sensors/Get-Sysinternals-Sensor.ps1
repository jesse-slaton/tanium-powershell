#requires -version 5.0

<#
.SYNOPSIS
    Downloads the Sysinternals Suite and extracts it into C:\Bin.

.DESCRIPTION
    Defines and runs Update-Sysinternals with its default values. It downloads
    https://live.sysinternals.com/Files/SysinternalsSuite.zip to
    $env:TEMP\SysinternalsSuite.zip, stops any running ZoomIt, Desktops and Process
    Explorer processes (Stop-Process -Force), expands the zip into C:\Bin overwriting
    existing files, then restarts the stopped programs (except those whose process name
    ends in 64). The downloaded zip is left in $env:TEMP.

    The function builds a list of changed files but does not output it. Invoke-WebRequest
    and Stop-Process write verbose messages. If the download or another step in the
    outer block fails, it outputs "Cannot connect to: <url>, please ensure you are
    connected to the Internet."; a failure while extracting is written as a warning.

    The script takes no parameters. The function's -NewPath, -OldPath and -BaseDir
    parameters are only reachable by editing the call at the end of the script.

.EXAMPLE
    .\Get-Sysinternals-Sensor.ps1

    Downloads the current Sysinternals Suite and extracts it into C:\Bin.

.NOTES
    Requires PowerShell 5.0 or later (#requires -version 5.0; Expand-Archive) and
    internet access to live.sysinternals.com. Needs write access to C:\Bin. Despite
    the "Sensor" name, this script changes files and stops processes.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/System/Get-Sysinternals-Sensor.ps1.
#>


function Update-Sysinternals {
    param (
        $NewPath = "https://live.sysinternals.com/Files/SysinternalsSuite.zip",
        $OldPath = "$Env:Temp\SysinternalsSuite.zip",
        $BaseDir = "C:\Bin"
    )
      
    try {

        # Get the list of files before the update
        $Files = Get-ChildItem -Path $BaseDir
            
        # Download the new zip file of tools
        Invoke-WebRequest -UseBasicParsing -Uri $NewPath -OutFile $OldPath -Method Get -Verbose

        # Some sysinternals apps are often is locked, kill those processes
        $Running = Get-Process zoomit*, desktops*, procexp* -ErrorAction SilentlyContinue
        $Paths = $Running | Where-Object {$_.name -notlike '*64'} | Select-Object -Property Path
        if ($Running) {
            $Running | Stop-Process -Force -Verbose
        }
            
        try {
                  
            Expand-Archive -LiteralPath $OldPath -DestinationPath $BaseDir -Force

            $FilesUpdate = Get-ChildItem -Path $BaseDir
                  
            $Updates = Compare-Object -ReferenceObject $Files -DifferenceObject $FilesUpdate | 
                Select-Object -ExpandProperty InputObject |
                ForEach-Object {Get-ChildItem -Path $BaseDir\$_} | Select-Object Name, CreationTime
        }
        Catch {
            Write-Warning -Message $_
        }
        finally {
            
            # Restart any applications that were running previously
            if ($Paths) {
                $Paths | ForEach-Object { Start-Process -FilePath $_.Path }
            }
        }
    }
    catch {
        "Cannot connect to: $NewPath, please ensure you are connected to the Internet."   
    }
}

Update-Sysinternals