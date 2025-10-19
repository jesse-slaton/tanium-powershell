# TaniumDeployPackage PowerShell Module
# Module for generating Tanium Deploy packages from various sources

#Requires -Version 5.1

# Load Classes
$Classes = @(Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue)
foreach ($ClassFile in $Classes) {
    try {
        . $ClassFile.FullName
    } catch {
        Write-Error "Failed to import class $($ClassFile.FullName): $_"
        throw
    }
}

# Load Private functions
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
foreach ($PrivateFunction in $Private) {
    try {
        . $PrivateFunction.FullName
    } catch {
        Write-Error "Failed to import private function $($PrivateFunction.FullName): $_"
        throw
    }
}

# Load Public functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
foreach ($PublicFunction in $Public) {
    try {
        . $PublicFunction.FullName
    } catch {
        Write-Error "Failed to import public function $($PublicFunction.FullName): $_"
        throw
    }
}

# Export Public functions
Export-ModuleMember -Function $Public.BaseName
