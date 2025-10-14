#region Base Variables
$StartTime = Get-Date -format "yyyy-MM-dd HH.mm tt"
$HostName = "$env:COMPUTERNAME"
$WorkFolder = "C:\DesktopSupportTools"
$WMIBackupFolder = "$WorkFolder\WMIBackup"
$WMIBackupFile = ("$WMIBackupFolder\$($Hostname)-$($StartTime).WMI_Backup").Replace(' ', '_')
$LogFile = ("$WorkFolder\Logs\RepairWMI-$($StartTime).log").Replace(' ', '_')
$SetupKey = "HKLM:\SYSTEM\Setup"
$RunCountValueName = "WMIRepairRunCount"
$LastDateRunValueName = "LastRunDate"
$SuccessCountValueName = "WmiRepairSucessCount"
$LastSuccessfulRepairValueName = "LastSuccessDate"
$DependentServices = Get-Service -Name "Winmgmt" | Select-Object -ExpandProperty dependentservices
$DependentServicesStatus = $DependentServices | Get-Service
#$WarningPreference = 'SilentlyContinue'
#endregion Base Variables

Start-Transcript -Path $LogFile -Force
Write-Output ""

#region Functions
#region isNumeric function
function IsNumeric ($Value) {
    return $Value -match "^[\d\.]+$"
}
#endregion isNumeric function

#region Get-OrdinalNumer function
Function Get-OrdinalNumber {
    Param(
        [Parameter(Mandatory = $true)]
        [int64]$num
    )

    $Suffix = Switch -regex ($Num) {
        '1(1|2|3)$' { 'th'; break }
        '.?1$' { 'st'; break }
        '.?2$' { 'nd'; break }
        '.?3$' { 'rd'; break }
        default { 'th'; break }
    }
    Write-Output "$Num$Suffix"
}
#endregion Get-OrdinalNumer function

#region Stop-ServiceWithTimeout function
#Function to stop a service with a specified timeout window.  Can optionally kill the process ID.
function Stop-ServiceWithTimeout ([string] $ServiceName, [int] $timeoutSeconds, [bool] $Kill) {
    Begin {
        if ($null -eq $timeoutSeconds) {
            $timeoutSeconds = 60
        }
        if ($null -eq $Kill) {
            [bool]$Kill = $False
        }
        $timespan = New-Object -TypeName System.Timespan -ArgumentList 0, 0, $timeoutSeconds
        If ($svc = Get-Service -Name $ServiceName) {
            if ($null -eq $svc) {
                Write-Warning "$($svc.DisplayName) service does not exist."
            }
            if ($svc.Status -eq [ServiceProcess.ServiceControllerStatus]::Stopped) {
                Write-Warning "$($svc.DisplayName) service is already stopped"
            }
            else {
                try {
                    $svc.Stop()
                }
                Catch {
                }
                try {
                    Write-Host "Stopping $($svc.DisplayName) service with a $timeoutSeconds second timeout"
                    $svc.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Stopped, $timespan)
                }
                catch [ServiceProcess.TimeoutException] {
                    Write-Warning "Timeout stopping service"
                }             
                If ($Kill -eq $true) {
                    Try {
                        Get-Process -name $svc.Name -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
                        Write-Warning "Killed $($svc.DisplayName) service"
                    }
                    Catch {
                        Throw "Failed to kill $($svc.DisplayName) service"
                    }
    
                }
                Write-Host -ForegroundColor Green "$($Svc.DisplayName) service successfully stopped"
            }
        }
    }
}
#endregion Stop-ServiceWithTimeout function

#region StopWMI function
#Stop WMI Service along with all dependents
Function StopWMI {
    Write-Host "Forcibly stopping services dependent on WMI"
    ForEach ($Service in $DependentServices) {
        Try {
            Set-Service -Name $Service.Name -StartupType Disabled -PassThru
            Stop-ServiceWithTimeout -ServiceName $Service.ServiceName -timeoutSeconds 5 -Kill $true
        }
        Catch {
            Write-Error "Could not stop the $($Service.DisplayName) service" -ErrorAction Stop
        }
    }
    Write-Host "Stopping WMI service"
    Try {
        Stop-ServiceWithTimeout -ServiceName 'Winmgmt' -timeoutSeconds 5 -Kill $true
    }
    Catch {
        Write-Error "Could not stop the WMI service" -ErrorAction Stop
    }
}
#endregion Stop-ServiceWithTimeout function

#region StartWMI function
#Start WMI Service along with all dependents
Function StartWMI {
    Write-Host "Starting the WMI service"
    Try {
        Set-Service -Name Winmgmt -StartupType Automatic -Status Running -ErrorAction Stop -PassThru
    }
    Catch {
        Write-Error "Could not start the WMI service" -ErrorAction Stop
    }
    Write-Host "Starting all services dependent on the WMI service"
    ForEach ($ServiceStatus in $DependentServicesStatus) {
        Set-Service -Name $ServiceStatus.Name -StartupType $ServiceStatus.StartType
    }    
    ForEach ($Service in $DependentServices) {
        If ($Service -notin 'Manual', 'Disabled') {
            Try {
                Start-Service $Service.ServiceName -ErrorAction Stop -PassThru
            }
            Catch {
                Write-Warning "Could not start $($Service.Displayname) service"
            }
        }
    }
}
#endregion StartWMI function

#region RotateBackups function
Function RotateBackups ([string] $PathName, [string] $Extension, [int] $Keep) {
    Get-ChildItem -Path $PathName -Filter "*.$Extension" | `
        Where-Object { -not $_.PsIsContainer } | `
        Sort-Object CreationTime -Descending | `
        Select-Object -Skip $Keep | `
        Remove-Item -Force
}
#endregion RotateBackups function

#region TestWMI function
function TestWMI {
    $NameSpaceCount = ((Get-WmiObject -Class __NameSpace -NameSpace root -ErrorAction Stop | Where-Object { $_.Name -eq 'CimV2' }) | Measure-Object).Count
    If ($NameSpaceCount -ne 1) {
        Write-Error "Error: Cannot create WMI object" -ErrorAction Stop
    }
    $Win32ProductTypeArray = Get-WmiObject -Query "Select ProductType from Win32_OperatingSystem" -ErrorAction Stop
    If (($Win32ProductTypeArray | Measure-Object).Count -lt 1) {
        Write-Error "Error: Cannot query WMI" -ErrorAction Stop
    }
    ForEach ($Item in $Win32ProductTypeArray) { 
        $ProductType = $Item.ProductType
    }
    $IsNumeric = IsNumeric($ProductType)
    If ($null -eq $ProductType -or $IsNumeric -eq $False) {
        Write-Error "Error: WMI cannot retrieve a basic property" -ErrorAction Stop
    }
}
#endregion TestWMI function

#region TestRegistry function
function TestRegistry {
    $StdRegProv = [WMIClass]"ROOT\DEFAULT:StdRegProv"
    $HKEY_Local_Machine = 2147483650 
    $Key = "SYSTEM\This\key\should\never\exist"
    $TestRegistry = $False
    $FakeKey = ($StdRegProv.EnumValues($HKEY_Local_Machine, $Key)).Snames
    $SystemKey = ($StdRegProv.EnumValues($HKEY_Local_Machine, "SYSTEM")).Snames
    
    If ($FakeKey -ne 0 ) {
        If ($null -eq $SystemKey) {
            $TestRegistry = $True
        }
    }
    $TestRegistry
}
#endregion TestRegistry function
#endregion Functions

#region Add Last Run Count and Date to the Registry
If ((Test-Path -Path "$SetupKey\Contoso") -eq $False ) {
    Try {
        New-Item $SetupKey -Name "Contoso" -ErrorAction Stop
        $ContosoKey = "$SetupKey\Contoso"    
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        Throw "Error: Could not create the Contoso registry key $ErrorMessage"     
    }
    
}
Else {
    $ContosoKey = "$SetupKey\Contoso"    
}
$RCVNExists = Get-ItemProperty -Path $ContosoKey -Name $RunCountValueName -ErrorAction SilentlyContinue
If (!($RCVNExists)) {
    Set-ItemProperty -Path $ContosoKey -Name $RunCountValueName -Value 1 -ErrorAction SilentlyContinue
}
else {
    [INT]$RunCountValue = (Get-ItemProperty -Path $ContosoKey -Name $RunCountValueName -ErrorAction SilentlyContinue).$($RunCountValueName)
    If (IsNumeric($RunCountValue) -eq $true) {
        $RunCountValue++
        Write-Host "$(Get-OrdinalNumber $RunCountValue) attempt at repairing WMI."
        Set-ItemProperty -Path $ContosoKey -Name $RunCountValueName -Value $RunCountValue -ErrorAction SilentlyContinue
    }
    Else {
        Set-ItemProperty -Path $ContosoKey -Name $RunCountValueName -Value 2 -ErrorAction SilentlyContinue
        Write-Warning "Could not determine the number of times run.  This is at least the 2nd time."
    }
    
}
Set-ItemProperty -Path $ContosoKey -Name $LastDateRunValueName -Value $StartTime -ErrorAction SilentlyContinue
#endregion Last Run Count and Date

#region Backup WMI
If (!(Test-Path -Path $WMIBackupFolder)) {
    Try {
        New-Item -Path $WMIBackupFolder -ItemType Directory -ErrorAction Stop
    }
    Catch {
        Write-Error "Unable to create $WMIBackupFolder" -ErrorAction Stop
    }
}
Try {
    $BackupWMI = Start-Process -FilePath "winmgmt.exe" -ArgumentList "/backup $WMIBackupFile" -PassThru -WindowStyle Hidden -Wait -ErrorAction Stop
    Write-Host -ForegroundColor Green "Successfully backed up the WMI Repository to $($WMIBackupFile)"
}
Catch {
    $ErrorMessage = $BackupWMI.ExitCode
    StartWMI
    Throw "Error: Unable to back up WMI. $ErrorMessage" 
}

try {
    RotateBackups -PathName $WMIBackupFolder -Extension "WMI_Backup" -Keep 10
}
catch {
    $ErrorMessage = $_.Exception.Message
    Throw "Error: Unable to rotate WMI repository backup files.  $ErrorMessage"
}
#endregion Backup WMI

#region Stop WMI
Try {
    StopWMI
}
Catch {
    $ErrorMessage = $_.Exception.Message
    Throw "Error: Unable to stop the WMI Service or one of its dependents. $ErrorMessage"
}
Start-Sleep -Seconds 60
#endregion Stop WMI

#region Repair WMI
#region Verify the WMI Repository
Try {
    $VerifyWMI = Start-Process -FilePath "winmgmt.exe" -ArgumentList "/verifyrepository" -PassThru -WindowStyle Hidden -Wait -ErrorAction Stop
    Write-Host -ForegroundColor Green "Successfully completed verification of the WMI Repository"
}
Catch {
    $ErrorMessage = $VerifyWMI.ExitCode
    StartWMI
    Throw "Error: Unable to complete verification of the WMI Repository"
}
#endregion Verify WMI Repository

#region Salvage WMI Repository
Try {
    $SalvageWMI = Start-Process -FilePath "winmgmt.exe" -ArgumentList "/salvagerepository" -PassThru -WindowStyle Hidden -Wait -ErrorAction Stop
    Write-Host -ForegroundColor Green "Successfully completed salvage of the WMI Repository"
}
Catch {
    $ErrorMessage = $SalvageWMI.ExitCode
    StartWMI
    Throw "Error: Unable to complete salvage of the WMI Repository" 
}
#endregion Salvage WMI Repository

#region Reset WMI Repository
Try {
    $ResetWMI = Start-Process -FilePath "winmgmt.exe" -ArgumentList "/resetrepository" -PassThru -WindowStyle Hidden -Wait -ErrorAction Stop
    Write-Host -ForegroundColor Green "Successfully completed reset of the WMI Repository"
}
Catch {
    $ErrorMessage = $ResetWMI.ExitCode
    StartWMI
    Throw "Error: Unable to complete reset of the WMI Repository"
}
#region Reset WMI Repository
#endregion Repair WMI

#region Start WMI
Try {
    StartWMI
}
Catch {
    $ErrorMessage = $_.Exception.Message
    Throw "Error: Unable to stop the WMI Service or one of its dependents. $ErrorMessage"
}
Start-Sleep -Seconds 60
#endregion Start WMI

#region Tanium Client Core Health Tests

#region Load Wscript.Shell COM Object
Try {
    $WshShell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
}
Catch {
    $ErrorMessage = $_.Exception.Message
    StartWMI
    Throw "Error: Cannot create WScript.Shell object. $ErrorMessage"
}
#endregion Load Wscript.Shell COM Object

#region Load StdReg Provider
Try {
    $StdRegProv = [WMIClass]"ROOT\DEFAULT:StdRegProv"
}
Catch {
    $ErrorMessage = $_.Exception.Message
    StartWMI
    Throw "Error: Cannot initialize the StdReg Provider. $ErrorMessage" 
}
#endregion Load StdReg Provider

#region Test WMI
$TestWMI = TestWMI
If ($TestWMI -eq $False) {
    StartWMI
    Throw "Error: Cannot properly access WMI"
}
#endregion Test WMI

#region Test registry
$TestRegistry = TestRegistry
If ($TestRegistry -eq $False) {
    StartWMI
    Throw "Error: Cannot properly access registry via WMI"
}
#endregion Test registry

#endregion Tanium Client Core Health Tests

#region Add Successful Run Count and Date to Registry
$SCVNExists = Get-ItemProperty -Path $ContosoKey -Name $SuccessCountValueName -ErrorAction SilentlyContinue
If (!($SCVNExists)) {
    Set-ItemProperty -Path $ContosoKey -Name $SuccessCountValueName -Value 1 -ErrorAction SilentlyContinue
}
else {
    [INT]$SuccessCountValue = (Get-ItemProperty -Path $ContosoKey -Name $SuccessCountValueName -ErrorAction SilentlyContinue).$($SuccessCountValueName)
    If (IsNumeric($SuccessCountValue) -eq $true) {
        Write-Host "$(Get-OrdinalNumber $SuccessCountValue) succesful attempt at repairing WMI."
        Set-ItemProperty -Path $ContosoKey -Name $SuccessCountValueName -Value $SuccessCountValue -ErrorAction SilentlyContinue
    }
    Else {
        Set-ItemProperty -Path $ContosoKey -Name $SuccessCountValueName -Value 2 -ErrorAction SilentlyContinue
        Write-Warning "Could not determine the number of times run successfully.  This is at least the 2nd time."

    }
}
Set-ItemProperty -Path $ContosoKey -Name $LastSuccessfulRepairValueName -Value $StartTime -ErrorAction SilentlyContinue
#endregion Add Successful Run Count and Date

#End Transcription
Stop-Transcript