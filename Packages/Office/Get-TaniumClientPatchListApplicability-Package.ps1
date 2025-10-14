function Get-TaniumClientPatchListApplicability {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Int]$PatchListId
    )
    
    $PatchList = Get-TaniumClientPatchList -Id $PatchListId
    if ($PatchList) {
        Write-Verbose "Found Patch List $($PatchList.name) with Id $($PatchList.id)"
        $PatchScanResults = Get-TaniumClientPatchScanResults
        $PatchListApplicability = @()
        if ($PatchScanResults) {
            Write-Verbose "Found Patch scan results"
            # Get the rules and loop through them
            foreach ($Rule in $PatchList.rules.rule) {
                Write-Verbose "Processing $($rule.name)"
                # Any match of a rule condition should match (OR)
                foreach ($Condition in $rule.conditions.condition) {
                    $FieldName = $Condition.fieldName
                    $Regex = $Condition.regex
                    Write-Verbose "$FieldName $Regex"
                    # All rule conditions must be true (AND)
                    $Filter = ''
                    switch ($FieldName) {
                        'classification' {
                            $Filter += "$FieldName -match $Regex"
                            $Filter
                        }
                        'releaseDate' {
                            # comparator                fieldName   fieldValue
                            #----------                ---------   ----------
                            #release date on or before releaseDate 6/9/2020
                            $releaseDate = $Condition | Select-Object -ExpandProperty releasedate
                            $releaseDate
                        }

                    }
                }
            }

            # need to deal with static entries
        }
        else {
            Write-Warning "Unable to find patch scan results"
        }
    }
    else {
        Write-Warning "Unable to find patch list $PatchlistId"
    }
    


}