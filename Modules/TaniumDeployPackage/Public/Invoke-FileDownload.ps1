function Invoke-FileDownload {
    <#
    .SYNOPSIS
        Downloads a file using BITS with progress tracking and resume capability.

    .DESCRIPTION
        Downloads a file using Background Intelligent Transfer Service (BITS) for automatic
        resume capability and bandwidth throttling. Falls back to WebClient if BITS is unavailable.

    .PARAMETER Url
        The URL to download from.

    .PARAMETER Destination
        The destination file path.

    .PARAMETER UseBits
        Use BITS for downloading. Default is true. Set to false to use WebClient instead.

    .EXAMPLE
        Invoke-FileDownload -Url "https://example.com/file.msu" -Destination "C:\temp\file.msu"

    .EXAMPLE
        Invoke-FileDownload -Url "https://example.com/large-file.zip" -Destination "C:\temp\file.zip" -UseBits $true
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$Destination,

        [Parameter()]
        [bool]$UseBits = $true
    )

    $fileName = Split-Path -Leaf $Destination
    $startTime = Get-Date

    if ($UseBits) {
        $bitsJob = $null
        try {
            Write-Host "Starting BITS download..." -ForegroundColor Cyan
            Write-Host "Source: $Url" -ForegroundColor Gray
            Write-Host "Destination: $Destination" -ForegroundColor Gray

            # Start BITS transfer asynchronously
            $bitsJob = Start-BitsTransfer -Source $Url -Destination $Destination -Asynchronous -DisplayName "Downloading $fileName" -Description $Url

            # Monitor progress
            while ($bitsJob.JobState -in @('Transferring', 'Connecting', 'TransientError', 'Queued')) {
                Start-Sleep -Milliseconds 500
                $bitsJob = Get-BitsTransfer -JobId $bitsJob.JobId

                if ($bitsJob.BytesTotal -gt 0) {
                    $percent = [int](($bitsJob.BytesTransferred / $bitsJob.BytesTotal) * 100)
                    $downloadedMB = [math]::Round($bitsJob.BytesTransferred / 1MB, 2)
                    $totalMB = [math]::Round($bitsJob.BytesTotal / 1MB, 2)
                    $elapsed = (Get-Date) - $startTime

                    $speed = if ($elapsed.TotalSeconds -gt 0) {
                        [math]::Round(($bitsJob.BytesTransferred / 1MB) / $elapsed.TotalSeconds, 2)
                    } else { 0 }

                    # Calculate ETA in seconds
                    $etaSeconds = if ($speed -gt 0) {
                        $remainingMB = $totalMB - $downloadedMB
                        [int]($remainingMB / $speed)
                    } else { -1 }

                    $status = "$downloadedMB MB / $totalMB MB | $speed MB/s"
                    Write-Progress -Activity "Downloading $fileName" -Status $status -PercentComplete $percent -SecondsRemaining $etaSeconds
                }
            }

            Write-Progress -Activity "Downloading $fileName" -Completed

            # Check final state
            if ($bitsJob.JobState -eq 'Transferred') {
                Complete-BitsTransfer -BitsJob $bitsJob
                $elapsed = (Get-Date) - $startTime
                $elapsedFormatted = "{0:D2}:{1:D2}:{2:D2}" -f [int]$elapsed.Hours, [int]$elapsed.Minutes, [int]$elapsed.Seconds
                $sizeMB = [math]::Round((Get-Item $Destination).Length / 1MB, 2)
                Write-Host "Download completed successfully! ($sizeMB MB in $elapsedFormatted)" -ForegroundColor Green
                return $true
            }
            elseif ($bitsJob.JobState -eq 'Error') {
                $errorMsg = $bitsJob.ErrorDescription
                throw "BITS transfer failed: $errorMsg"
            }
            else {
                throw "BITS transfer ended with unexpected state: $($bitsJob.JobState)"
            }
        }
        catch [System.Management.Automation.PipelineStoppedException] {
            # User pressed Ctrl+C
            Write-Host "`n`nDownload interrupted by user" -ForegroundColor Yellow
            return $false
        }
        catch {
            Write-Warning "BITS download failed: $_"
            Write-Host "Falling back to WebClient download..." -ForegroundColor Yellow
            $UseBits = $false
        }
        finally {
            # Cleanup: Check for incomplete BITS jobs
            if ($bitsJob) {
                $incompleteBitsJobs = Get-BitsTransfer | Where-Object {
                    $_.JobId -eq $bitsJob.JobId -and
                    $_.JobState -ne 'Transferred'
                }

                if ($incompleteBitsJobs) {
                    Write-Host "`nIncomplete BITS transfer detected" -ForegroundColor Yellow
                    $cleanup = Read-Host "Clean up incomplete transfer and partial file? (Y/N)"

                    if ($cleanup -eq 'Y' -or $cleanup -eq 'y') {
                        # Remove BITS transfer
                        $incompleteBitsJobs | Remove-BitsTransfer

                        # Remove partial file if it exists
                        if (Test-Path $Destination) {
                            Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
                        }

                        Write-Host "Cleanup completed" -ForegroundColor Green
                    } else {
                        Write-Host "BITS transfer and partial file kept (can be resumed later)" -ForegroundColor Cyan
                    }
                }
            }
        }
    }

    if (-not $UseBits) {
        try {
            Write-Host "Starting WebClient download..." -ForegroundColor Cyan
            Write-Host "Source: $Url" -ForegroundColor Gray
            Write-Host "Destination: $Destination" -ForegroundColor Gray

            $webClient = New-Object System.Net.WebClient

            # Register progress event
            $script:webStartTime = $startTime
            Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier WebClientProgress -Action {
                $percent = $EventArgs.ProgressPercentage
                $downloadedMB = [math]::Round($EventArgs.BytesReceived / 1MB, 2)
                $totalMB = [math]::Round($EventArgs.TotalBytesToReceive / 1MB, 2)

                # Calculate speed and ETA
                $elapsed = (Get-Date) - $script:webStartTime
                $speed = if ($elapsed.TotalSeconds -gt 0) {
                    [math]::Round($downloadedMB / $elapsed.TotalSeconds, 2)
                } else { 0 }

                $etaSeconds = if ($speed -gt 0) {
                    $remainingMB = $totalMB - $downloadedMB
                    [int]($remainingMB / $speed)
                } else { -1 }

                $status = "$downloadedMB MB / $totalMB MB | $speed MB/s"
                Write-Progress -Activity "Downloading $fileName" -Status $status -PercentComplete $percent -SecondsRemaining $etaSeconds
            } | Out-Null

            # Start download
            $webClient.DownloadFileAsync($Url, $Destination)

            # Wait for completion
            while ($webClient.IsBusy) {
                Start-Sleep -Milliseconds 500
            }

            Write-Progress -Activity "Downloading $fileName" -Completed

            # Cleanup
            Unregister-Event -SourceIdentifier WebClientProgress -ErrorAction SilentlyContinue
            $webClient.Dispose()

            if (Test-Path $Destination) {
                $elapsed = (Get-Date) - $startTime
                $elapsedFormatted = "{0:D2}:{1:D2}:{2:D2}" -f [int]$elapsed.Hours, [int]$elapsed.Minutes, [int]$elapsed.Seconds
                $sizeMB = [math]::Round((Get-Item $Destination).Length / 1MB, 2)
                Write-Host "Download completed successfully! ($sizeMB MB in $elapsedFormatted)" -ForegroundColor Green
                return $true
            }
            else {
                Write-Error "WebClient download failed - file not found"
                return $false
            }
        }
        catch {
            Write-Error "WebClient download failed: $_"
            Unregister-Event -SourceIdentifier WebClientProgress -ErrorAction SilentlyContinue
            if ($webClient) { $webClient.Dispose() }
            return $false
        }
    }
}
