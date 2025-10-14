function Get-TaniumClientTpython {
    [cmdletbinding()]
    param (
        [ValidateSet('2', '3')]
        [string]$Version = '2'
    )
    $TaniumClientDirectory = Get-TaniumClientDirectory
    $TaniumClientTpythonHelper = "$TaniumClientDirectory\TPython\TPython.bat"
    if (Test-Path -Path $TaniumClientTpythonHelper) {
        Write-Verbose "Found Tpython.bat at $TaniumClientTpythonHelper"
        $TaniumClientTpython = $TaniumClientTpythonHelper
        $TaniumClientTpython
    }
    else {
        Write-Verbose "Unable to find $TaniumClientTpythonHelper. Trying explicit path."
        switch ($Version) {
            '2' {
                $TpythonDirectory = 'python27'
            }
            '3' {
                $TpythonDirectory = 'python38'
            }
        }
        if (Test-Path "$TaniumClientDirectory\$TpythonDirectory\Tpython.exe") {
            Write-Verbose "Found Tpython.exe at $TaniumClientDirectory\$TpythonDirectory\Tpython.exe"
            $TaniumClientTpython = "$TaniumClientDirectory\$TpythonDirectory\Tpython.exe"
            $TaniumClientTpython
        }
        else {
            Write-Warning "Unable to find Tpython at $TaniumClientDirectory\$TpythonDirectory\Tpython.exe"
        }
    }
}