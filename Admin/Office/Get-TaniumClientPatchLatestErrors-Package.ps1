function Get-TaniumClientPatchLatestErrors {
    [CmdletBinding()]
    param(
        [parameter(mandatory=$true)]
        [ValidateSet('DeploymentError','ScanError')]
        [string]$ErrorType
    )
    $TaniumClientPatchErrors = Get-TaniumClientPatchData -DataType latest-errors
    $TaniumClientPatchErrors.$ErrorType
}