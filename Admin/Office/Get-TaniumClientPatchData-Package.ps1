function Get-TaniumClientPatchData {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [ValidateSet('deployment-statuses', 'deployment-results', 'scan-statuses', 'latest-errors', 'patch-lists', 'scan-configuration-priorities','settings-file','tsw-manifest','required-files-manifest')]
        [string]$DataType
    )
    $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory

    switch ($DataType) {
        'deployment-statuses' {
            $DataFilePath = "$TaniumClientPatchDirectory\deployments\$DataType"
            $Format = 'xml'
            $Element = 'DeploymentStatuses'
            $Leaf = 'Deployment'
        }
        'deployment-results' {
            $DataFilePath = "$TaniumClientPatchDirectory\deployments\$DataType"
            $Format = 'xml'
            $Element = 'DeploymentResults'
            $Leaf = 'Deployment'
        }
        'scan-statuses' {
            $DataFilePath = "$TaniumClientPatchDirectory\scans\$DataType"
            $Format = 'xml'
            $Element = 'ScanStatuses'
            $Leaf = 'ScanConfiguration'
        }
        'latest-errors' {
            $DataFilePath = "$TaniumClientPatchDirectory\$DataType"
            $Format = 'xml'
            $Element = 'Errors'
            #$Leaf = 'ScanError'
        }
        'patch-lists' {
            $DataFilePath = "$TaniumClientPatchDirectory\$DataType"
            $Format = 'xml'
            $Element = 'PatchLists'
            $Leaf = 'PatchList'
        }
        'scan-configuration-priorities' {
            $DataFilePath = "$TaniumClientPatchDirectory\scans\$DataType"
            $Format = 'text'
        }
        'settings-file' {
            $DataFilePath = "$TaniumClientPatchDirectory\settings-file"
            $Format = 'xml'
            $Element = 'log-settings'
        }
        'tsw-manifest' {
            $DataFilePath = "$TaniumClientPatchDirectory\scans\tsw-manifest.xml"
            $Format = 'xml'
            $Element = 'file-references'
            $Leaf = 'manifest'
        }
        'required-files-manifest' {
            $DataFilePath = "$TaniumClientPatchDirectory\$DataType"
            $Format = 'xml'
            $Element = 'required-files'
        }
    }

    if (Test-Path $DataFilePath) {
        Write-Verbose "Tanium Client Patch $DataType found"
        switch ($Format) {
            'xml' {
                $TaniumClientPatchData = Read-XmlFile -Path $DataFilePath
                if ($Leaf) {
                    $TaniumClientPatchData.$Element.$Leaf
                }
                else {
                    $TaniumClientPatchData.$Element
                }
            }
            'text' {
                $TaniumClientPatchData = Get-Content -Path $DataFilePath
                $TaniumClientPatchData
            }
        }
    }
    else {
        Write-Warning "Tanium Client Patch configuration $DataType doesn't exist"
    }
}