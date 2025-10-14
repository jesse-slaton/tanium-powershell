function Get-TaniumClientProcessLoadedModules {
    [cmdletbinding()]
    param (
        [ValidateSet(
            'TaniumClient',
            'TaniumCX',
            'Tpython',
            'TaniumDetectEngine',
            'TaniumEndpointIndex',
            'TaniumReveal',
            'TaniumTSDB',
            'TaniumReceiver',
            'TaniumModuleServer',
            'TaniumZoneServer',
            'TaniumDataService',
            'TaniumImpactService',
            'TaniumEndpointConfigService'
        )]
        [string[]]$Process = @('TaniumClient', 'TaniumCX', 'Tpython'),
        [switch]$All,
        [switch]$ExcludeTaniumModules,
        [switch]$ExcludeMicrosoftModules,
        [switch]$IncludeDefenderModules
    )

    $DefenderModules = 'amsi\.dll|mpclient\.dll|mpoav\.dll'

    function Get-ProcessModuleNative {
        param (
            $Name
        )
        $Modules = Get-Process -Name $Name -Module | Select-Object -Unique
        $Modules
    }
    function Get-ProcessModuleWow6432 {
        param (
            $Name
        )
        Write-Verbose "Launching x86 PowerShell to get process modules"
        $ModulesXmlFile = "$env:TEMP\modules.xml"
        $Command = "Get-Process -Name $Name -Module | Select-Object -Unique | Export-CliXml -Path $ModulesXmlFile"
        $Ps32 = "$env:windir\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"
        if (Test-Path -Path $Ps32) {
            Start-Process -FilePath $Ps32 -ArgumentList '-command', $Command -Wait -WindowStyle Hidden
            if (Test-Path -Path $ModulesXmlFile) {
                $Modules = Import-CliXml -Path $ModulesXmlFile
                Remove-Item -Path $ModulesXmlFile
                $Modules
            }
            else {
                Write-Warning "Unable to find $ModulesXmlFile"
            }
        }
        else {
            Write-Warning 'Unable to find 32-bit PowerShell'
        }
    }

    if ($All.IsPresent) {
        $Process = Get-Process | Where-Object -FilterScript { $_.Path -like '*Tanium*' } | Select-Object -ExpandProperty Name
    }

    Write-Verbose 'Checking operating system bitness'
    $Bitness = Get-Bitness

    foreach ($TaniumProcess in $Process) {
        if (Test-Process -ProcessName $TaniumProcess) {
            switch ($Bitness) {
                'x64' {
                    Write-Verbose "x64 operating system. Check process bitness."
                    $ProcessBitness = Get-ProcessBitness -Process $TaniumProcess
                    switch ($ProcessBitness) {
                        'x64' {
                            $Modules = Get-ProcessModuleNative -Name $TaniumProcess
                        }
                        'x86' {
                            $Modules = Get-ProcessModuleWow6432 -Name $TaniumProcess
                        }
                    }
                }
                'x86' {
                    Write-Verbose "x86 operating system. Skipping checking process bitness."
                    $Modules = Get-ProcessModuleNative -Name $TaniumProcess
                }
            }

            if ($Modules) {
                Write-Verbose "Found modules for process $TaniumProcess"
                if ($ExcludeTaniumModules.IsPresent) {
                    $Modules = $Modules | Where-Object -FilterScript { $_.Company -notlike '*Tanium*' -and $_.FileName -notlike '*Tanium*' }
                }
                if ($ExcludeMicrosoftModules.IsPresent) {
                    if ($IncludeDefenderModules.IsPresent) {
                        $Modules = $Modules | Where-Object -FilterScript { $_.ModuleName -match $DefenderModules -or $_.Company -notlike '*Microsoft*' }
                    }
                    else {
                        $Modules = $Modules | Where-Object -FilterScript { $_.Company -notlike '*Microsoft*' }
                    }
                }
                $LoadedModules = @()
                foreach ($Module in $Modules) {
                    $LoadedModulesProperties = @{
                        'Process'    = $TaniumProcess
                        'ModuleName' = $Module.ModuleName
                        'FileName'   = $Module.FileName
                        'Company'    = $Module.Company
                    }
                    $LoadedModule = New-Object -TypeName PSObject -Property $LoadedModulesProperties
                    $LoadedModules += $LoadedModule
                }
                $LoadedModules
            }
            else {
                Write-Verbose "Unable to find modules for process $TaniumProcess"
            }
        }
        else {
            Write-Warning "Unable to find process $TaniumProcess"
        }
    }
}