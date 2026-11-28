#Requires -Version 5.1

<#
.SYNOPSIS
    Generates the source of a script that lists installed .NET Framework versions with their product names.

.DESCRIPTION
    Downloads the Markdown of the Microsoft docs article "How to determine which .NET
    Framework versions are installed" from the dotnet/docs repository on GitHub and
    parses its tables into a lookup of Release value to .NET Framework version.

    Outputs, as a single string, the text of a new script that contains that $Lookup
    table and, when run, reads HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP and
    returns one object per installed framework entry with .NET Framework, Product,
    Version, Release, PSComputerName and WindowsVersion. This script does not run the
    generated code and changes nothing; save the output to a .ps1 file to use it.

.EXAMPLE
    .\GetNETFrameworkVersionScript-Package.ps1 | Set-Content -Path .\Get-NetFrameworkVersion.ps1

    Saves the generated script to a file.

.EXAMPLE
    .\GetNETFrameworkVersionScript-Package.ps1 | Set-Content -Path .\Get-NetFrameworkVersion.ps1
    Get-Content -Path .\Get-NetFrameworkVersion.ps1
    .\Get-NetFrameworkVersion.ps1

    Saves the generated script, shows it so you can review it, then runs it to list
    the installed .NET Framework versions. The generated text is built from content
    downloaded from GitHub, so review it before running it rather than piping it to
    Invoke-Expression.

.NOTES
    Requires network access to raw.githubusercontent.com. The parsing depends on the
    article's path on the master branch and on its table layout. A failed download or
    an empty lookup writes an error and exits non-zero rather than emitting an empty
    script. No admin rights needed. Works in Windows PowerShell 5.1 and PowerShell 7.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/Network/GetNETFrameworkVersionScript-Package.ps1.
#>
# Get the text from github
$url = "https://raw.githubusercontent.com/dotnet/docs/master/docs/framework/install/how-to-determine-which-versions-are-installed.md"
try {
    $md = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
}
catch {
    # A failed download must not silently produce an empty script.
    throw "Failed to download the .NET Framework version table from $url : $($_.Exception.Message)"
}
$OFS = "`n"
# The version table lists one ".NET Framework <version>" per row with its Release
# value(s) in **bold** (a version has several OS-specific Release values). Match the
# data rows directly (skipping the Markdown cell delimiters and the header/separator
# rows), then emit one "<release> = [version]'<version>'" line per Release value.
$map = $md -split "`n" |
    Where-Object { $_ -match '\.NET Framework\s+\d' } |
    ForEach-Object {
        $version = ([regex]::Match($_, '\.NET Framework\s+(\d+(?:\.\d+)*)')).Groups[1].Value
        [regex]::Matches($_, '\*\*(\d+)\*\*') | ForEach-Object {
            "    $($_.Groups[1].Value) = [version]'$version'"
        }
    }

if (-not $map) {
    # An empty lookup means the page changed or returned nothing; do not emit a plausible empty script.
    throw "The .NET Framework version table could not be parsed from $url; the page may have changed."
}

# And output the whole script
@"
`$Lookup = @{
    $map
}

# For extra effect we could get the Windows 10 OS version and build release id:
try {
    `$WinRelease = (Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" ReleaseId)
    `$WinVer = (Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentMajorVersionNumber, CurrentMinorVersionNumber, CurrentBuildNumber, UBR)
    `$WindowsVersion = "`$(`$WinVer -join '.') (`$WinRelease)"
}
catch {
    `$WindowsVersion = [System.Environment]::OSVersion.Version
}

Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
Get-ItemProperty -name Version, Release -EA 0 |
# For The One True framework (latest .NET 4x), change match to PSChildName -eq "Full":
Where-Object { `$_.PSChildName -match '^(?!S)\p{L}' } |
Select-Object @{name = ".NET Framework"; expression = { `$_.PSChildName } }, 
@{name = "Product"; expression = { `$Lookup[`$_.Release] } }, 
Version, Release,
# Some OPTIONAL extra output: PSComputerName and WindowsVersion
# The Computer name, so output from local machines will match remote machines:
@{ name = "PSComputerName"; expression = { `$Env:Computername } },
# The Windows Version (works on Windows 10, at least):
@{ name = "WindowsVersion"; expression = { `$WindowsVersion } }
"@
