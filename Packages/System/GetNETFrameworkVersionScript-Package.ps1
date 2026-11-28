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
    article's path on the master branch and on its table layout; if either has
    changed the lookup will be empty or wrong. No admin rights needed. Works in
    Windows PowerShell 5.1 and PowerShell 7.
    Imported from jesse-slaton/powershell-utilities at 00676387f42413dc85c8b373791a0364358f6820, from Scripts/Network/GetNETFrameworkVersionScript-Package.ps1.
#>
# Get the text from github
$url = "https://raw.githubusercontent.com/dotnet/docs/master/docs/framework/migration-guide/how-to-determine-which-versions-are-installed.md"
$md = Invoke-WebRequest $url -UseBasicParsing
$OFS = "`n"
# Replace the weird text in the tables, and the padding
# Then trim the | off the front and end of lines
$map = $md -split "`n" -replace " installed [^|]+" -replace "\s+\|" -replace "\|$" |
# Then we can build the table by looking for unique lines that start with ".NET Framework"
Select-String "^.NET" | Select-Object -Unique |
# And flip it so it's key = value
# And convert ".NET FRAMEWORK 4.5.2" to  [version]4.5.2
ForEach-Object { 
    [version]$v, [int]$k = $_ -replace "\.NET Framework " -split "\|"
    "    $k = [version]'$v'"
}

# And output the whole script
@"
`$Lookup = @{
    $map
}

# For extra effect we could get the Windows 10 OS version and build release id:
try {
    `$WinRelease, `$WinVer = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" ReleaseId, CurrentMajorVersionNumber, CurrentMinorVersionNumber, CurrentBuildNumber, UBR
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