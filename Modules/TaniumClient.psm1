# Source all ps1 scripts in current directory.

foreach ($file in Get-ChildItem $PSScriptRoot -Include *.ps1 -Recurse) {
    . (
        [scriptblock]::Create(
            [io.file]::ReadAllText($file)
        )
    )
}