<#
List all files and folders to check
Patch\
    environment-options
    latest-errors
    patch-lists
    required-files-manifest
    blacklists\
        blacklists-manifest
        configurations\*
    deployments\
        deployment-results
        deployment-statuses
        configurations\*
        notifications\*
    maintenance-windows\
        configurations\*
        maintenance-windows-manifest
    scans\
        configurations\*
        scan-configurations-manifest
        scan-statuses
        tsw-applicability-rules.xml
        tsw-manifest.xml


c:\Program Files (x86)\Tanium\Tanium Client\Patch\environment-options
c:\Program Files (x86)\Tanium\Tanium Client\Patch\latest-errors
c:\Program Files (x86)\Tanium\Tanium Client\Patch\patch-lists
c:\Program Files (x86)\Tanium\Tanium Client\Patch\required-files-manifest
c:\Program Files (x86)\Tanium\Tanium Client\Patch\blacklists\blacklists-manifest
c:\Program Files (x86)\Tanium\Tanium Client\Patch\blacklists\configurations\*
c:\Program Files (x86)\Tanium\Tanium Client\Patch\deployments\deployment-results
c:\Program Files (x86)\Tanium\Tanium Client\Patch\deployments\deployment-statuses
c:\Program Files (x86)\Tanium\Tanium Client\Patch\deployments\configurations\*
c:\Program Files (x86)\Tanium\Tanium Client\Patch\deployments\notifications\*
c:\Program Files (x86)\Tanium\Tanium Client\Patch\maintenance-windows\configurations\*
c:\Program Files (x86)\Tanium\Tanium Client\Patch\maintenance-windows\maintenance-windows-manifest
c:\Program Files (x86)\Tanium\Tanium Client\Patch\scans\
c:\Program Files (x86)\Tanium\Tanium Client\Patch\scans\configurations\*
c:\Program Files (x86)\Tanium\Tanium Client\Patch\scans\scan-configurations-manifest
c:\Program Files (x86)\Tanium\Tanium Client\Patch\scans\scan-statuses
c:\Program Files (x86)\Tanium\Tanium Client\Patch\scans\tsw-applicability-rules.xml
c:\Program Files (x86)\Tanium\Tanium Client\Patch\scans\tsw-manifest.xml
#>
function Test-TaniumClientPatchXmlFile {
    [cmdletbinding()]
    param ( )
    begin {}
    process {
        $TaniumClientPatchDirectory = Get-TaniumClientPatchDirectory
        $TaniumClientPatchXmlFiles = @(
            'environment-options'
            'latest-errors'
            'patch-lists'
            'required-files-manifest'
            'blacklists\blacklists-manifest'
            'blacklists\configurations\*'
            'deployments\deployment-results'
            'deployments\deployment-statuses'
            'deployments\configurations\*'
            'deployments\notifications\*'
            'maintenance-windows\configurations\*'
            'maintenance-windows\maintenance-windows-manifest'
            'scans\configurations\*'
            'scans\scan-configurations-manifest'
            'scans\scan-statuses'
            'scans\tsw-applicability-rules.xml'
            'scans\tsw-manifest.xml'
        )

        foreach ($TaniumClientPatchXmlFile in $TaniumClientPatchXmlFiles) {
            Write-Verbose "Checking $TaniumClientPatchDirectory\$TaniumClientPatchXmlFile"
            if (Test-Path -Path "$TaniumClientPatchDirectory\$TaniumClientPatchXmlFile" ) {
                $Files = Get-ChildItem -Path "$TaniumClientPatchDirectory\$TaniumClientPatchXmlFile" 
                if ($Files) {
                    foreach ($File in $Files) {
                        Write-Verbose "Validating XML file $($File.FullName)"
                        $IsValidXml = Test-XmlFile -Path $File.FullName
                        $TaniumClientPatchXmlFileResultsProperties = @{
                            Path       = $File.FullName
                            IsValidXml = $IsValidXml
                        }
                        $TaniumClientPatchXmlFileResults = New-Object -Type PSObject -Property $TaniumClientPatchXmlFileResultsProperties
                        $TaniumClientPatchXmlFileResults
                    }
                }
            }
            else {
                Write-Verbose "$TaniumClientPatchDirectory\$TaniumClientPatchXmlFile not found."
            }
        }
    }
    end {}
}