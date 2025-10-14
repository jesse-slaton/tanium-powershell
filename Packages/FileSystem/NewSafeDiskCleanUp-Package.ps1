param (
    [string]$Thoroughness = "normal"
)

# Decode the Thoroughness parameter in case it's URI encoded
$Thoroughness = [System.URI]::UnescapeDataString($Thoroughness)

$StartTime = Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
$LogPath = "C:\PIMCO\Logs"
$LogFile = "$LogPath\NewCleanup_${Thoroughness}_Completed-"

function Get-FreeSpacePercentage {
    $drive = Get-PSDrive C
    return ($drive.Free / ($drive.Free + $drive.Used)) * 100
}

function Set-RegistryValues {
    param (
        [string]$Thoroughness,
        [datetime]$StartTime,
        [int]$CleanupCompleted
    )
    $path = "HKLM:\Software\Tanium\Tanium Client\Sensor Data"
    $cleanupLastRun = $StartTime.ToUniversalTime().ToString("ddd, dd MMM yyyy HH':'mm':'ss 'GMT'")
    
    If (!(Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    Set-ItemProperty -Path $path -Name "CleanupLevel" -Value $Thoroughness
    Set-ItemProperty -Path $path -Name "CleanupLastRun" -Value $cleanupLastRun
    Set-ItemProperty -Path $path -Name "CleanupCompleted" -Value $CleanupCompleted
}

function Remove-RegistryValues {
    $path = "HKLM:\Software\Tanium\Tanium Client\Sensor Data"
    If (Test-Path $path) {
        Remove-ItemProperty -Path $path -Name "CleanupLevel" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $path -Name "CleanupLastRun" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $path -Name "CleanupCompleted" -ErrorAction SilentlyContinue
    }
}

function PerformCleanup {
    param (
        [string]$Thoroughness,
        [int]$Timeout
    )
    
    $global:CleanupCompletedIndicator = $false
    Start-Transcript -Path "${LogFile}FALSE-$StartTime.log" -Append
    
    $StartTime = Get-Date
    $job = Start-Job -ScriptBlock {
        param($Thoroughness)
        # Add your cleanup logic here based on $Thoroughness
    } -ArgumentList $Thoroughness

    $result = Wait-Job -Job $job -Timeout $Timeout
    if ($result -eq $null) {
        Write-Host "Cleanup process exceeded the maximum allowed time for $Thoroughness cleanup and has been stopped."
        Stop-Transcript
        Stop-Job -Job $job
        Remove-Job -Job $job
    }
    else {
        $global:CleanupCompletedIndicator = $true
        Stop-Job -Job $job
        Receive-Job -Job $job
        Remove-Job -Job $job
    }

    $finalFreeSpacePercentage = Get-FreeSpacePercentage

    if ($finalFreeSpacePercentage -lt 15) {
        Set-RegistryValues -Thoroughness $Thoroughness -StartTime $StartTime -CleanupCompleted ($global:CleanupCompletedIndicator -as [int])
    } else {
        Remove-RegistryValues
    }
    
    Stop-Transcript
    $completionStatus = if ($global:CleanupCompletedIndicator) { "TRUE" } else { "FALSE" }
    Rename-Item -Path "${LogFile}FALSE-$StartTime.log" -NewName "${LogFile}$completionStatus-$StartTime.log"
}

switch ($Thoroughness) {
    "fast" {
        PerformCleanup -Thoroughness "fast" -Timeout 900 # 15 minutes
    }
    "normal" {
        PerformCleanup -Thoroughness "normal" -Timeout 3600 # 1 hour
    }
    "thorough" {
        PerformCleanup -Thoroughness "thorough" -Timeout 14400 # 4 hours
    }
}
