function Start-FileWatcher {
    <#
    .SYNOPSIS
        Monitors a local file for changes and synchronizes it with a remote file in real-time using a PSSession.

    .DESCRIPTION
        This function monitors a local file for changes and synchronizes it with a remote file in real-time using a PSSession.
        It supports dual mode, allowing for monitoring of both local and remote file changes.

    .PARAMETER LocalPath
        The full path to the local file to monitor.

    .PARAMETER RemotePath
        The full path to the remote file to synchronize with.

    .PARAMETER Session
        The PSSession object for the remote computer.

    .PARAMETER ComputerName
        The name of the remote computer.

    .PARAMETER Dual
        If specified, enables dual mode to monitor both local and remote changes.

    .EXAMPLE
        Start-FileWatcher -LocalPath "C:\Temp\local.txt" -RemotePath "C:\Temp\remote.txt" -Session $session -ComputerName "server01" -Dual

    .NOTES
        This function is intended for read-only access to remote files using Edit-RemoteFile.

        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions", "", Justification = "File monitoring function - no user confirmation needed for real-time sync"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingWriteHost", "", Justification = "Interactive tool with colored output for better user experience - Write-Host is appropriate here"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LocalPath,

        [Parameter(Mandatory = $true)]
        [string]$RemotePath,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [switch]$Dual
    )

    $localLastWriteTime = (Get-Item $LocalPath).LastWriteTime
    $remoteLastWriteTime = $null
    $syncInProgress = $false
    $noActivityCount = 0
    $waitingMessageShown = $false
    Write-Verbose "Initial local file last write time: $localLastWriteTime"

    # Get initial remote file time if dual mode
    if ($Dual) {
        $remoteLastWriteTime = Invoke-Command -Session $Session -ScriptBlock {
            param($Path)
            if (Test-Path $Path) {
                return (Get-Item $Path).LastWriteTime
                Write-Verbose "Remote file last write time: $($_.LastWriteTime)"
            }
            return $null
        } -ArgumentList $RemotePath

        Write-Host "🔄 Dual sync enabled - monitoring both local and remote changes" -ForegroundColor Magenta
    }

    try {
        while ($true) {
            # Check for key press
            if ($Host.UI.RawUI.KeyAvailable) {
                $key = $Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho")
                # Ctrl+E = ASCII 5
                if (5 -eq [int]$key.Character) {
                    Write-Host "`n🔴 Stop requested by user (Ctrl+E)" -ForegroundColor Yellow
                    break
                }
            }

            # Check if local file still exists
            if (-not (Test-Path $LocalPath)) {
                Write-Host "`n🔴 Local file deleted - Stopping monitoring" -ForegroundColor Yellow
                break
            }

            # Check local file modifications
            $currentLocalWriteTime = (Get-Item $LocalPath).LastWriteTime
            $localChanged = $currentLocalWriteTime -gt $localLastWriteTime
            Write-Verbose "Local file last write time: $currentLocalWriteTime, Previous: $localLastWriteTime, Changed: $localChanged"

            # Check remote file modifications (if dual mode)
            $remoteChanged = $false
            if ($Dual -and -not $syncInProgress) {
                try {
                    $currentRemoteWriteTime = Invoke-Command -Session $Session -ScriptBlock {
                        param($Path)
                        if (Test-Path $Path) {
                            return (Get-Item $Path).LastWriteTime
                            Write-Verbose "Remote file last write time: $($_.LastWriteTime)"
                        }
                        return $null
                    } -ArgumentList $RemotePath

                    if ($currentRemoteWriteTime -and $remoteLastWriteTime -and $currentRemoteWriteTime -gt $remoteLastWriteTime) {
                        $remoteChanged = $true
                    }
                } catch {
                    # Ignore remote check errors to avoid spam
                    Write-Debug "Remote check failed: $_"
                }
            }

            # Handle local → remote sync
            if ($localChanged -and -not $syncInProgress) {
                $syncInProgress = $true
                $noActivityCount = 0
                $waitingMessageShown = $false

                $timestamp = Get-Date -Format "HH:mm:ss"
                Write-Host "`n[$timestamp] 🔄 Local modification detected" -ForegroundColor Cyan

                try {
                    Start-Sleep -Milliseconds 200
                    Copy-Item -Path $LocalPath -Destination $RemotePath -ToSession $Session -Force -ErrorAction Stop
                    Write-Host "[$timestamp] ✅ Synchronized local → remote ($ComputerName)" -ForegroundColor Green
                    $localLastWriteTime = $currentLocalWriteTime
                    Write-Verbose "Updated local file last write time: $localLastWriteTime"

                    # Update remote time to avoid immediate reverse sync
                    if ($Dual) {
                        $remoteLastWriteTime = Invoke-Command -Session $Session -ScriptBlock {
                            param($Path)
                            if (Test-Path $Path) {
                                return (Get-Item $Path).LastWriteTime
                                Write-Verbose "Remote file last write time: $($_.LastWriteTime)"
                            }
                            return $null
                        } -ArgumentList $RemotePath
                    }
                } catch {
                    Write-Host "[$timestamp] ❌ Local → Remote sync error: $_" -ForegroundColor Red
                } finally {
                    $syncInProgress = $false
                    Write-Verbose "Sync operation completed"
                }
            } elseif ($remoteChanged -and $Dual -and -not $syncInProgress) {
                # Handle remote → local sync (dual mode only) with NUL character cleanup
                $syncInProgress = $true
                $noActivityCount = 0
                $waitingMessageShown = $false
                Write-Verbose "Remote file change detected, starting sync"

                $timestamp = Get-Date -Format "HH:mm:ss"
                Write-Host "`n[$timestamp] 🔄 Remote modification detected" -ForegroundColor Magenta

                try {
                    Start-Sleep -Milliseconds 200

                    # Copy to temporary file first
                    $tempRemoteFile = "$env:TEMP\remote_temp_$(Get-Random).tmp"
                    Copy-Item -Path $RemotePath -Destination $tempRemoteFile -FromSession $Session -Force -ErrorAction Stop
                    Write-Verbose "Copied remote file to temporary location: $tempRemoteFile"

                    # Read without specifying encoding (PowerShell auto-detects) then clean and force UTF-8
                    $content = Get-Content -Path $tempRemoteFile -Raw
                    Write-Verbose "Read content from temporary file, length: $($content.Length)"

                    # Remove any null characters and other problematic characters
                    if ($content) {
                        $content = $content -replace [char]0, ''  # Remove NUL characters
                        $content | Set-Content -Path $LocalPath -Encoding UTF8 -Force
                        Write-Verbose "Wrote cleaned content to local file with UTF-8 encoding"
                    } else {
                        # Handle empty file case
                        Set-Content -Path $LocalPath -Value "" -Encoding UTF8 -Force
                        Write-Verbose "Local file was empty, created empty UTF-8 file"
                    }

                    # Clean up temporary file
                    Remove-Item $tempRemoteFile -Force -ErrorAction SilentlyContinue
                    Write-Verbose "Removed temporary file: $tempRemoteFile"

                    Write-Host "[$timestamp] ✅ Synchronized remote → local ($ComputerName) [Clean UTF-8]" -ForegroundColor Green
                    $remoteLastWriteTime = $currentRemoteWriteTime

                    # Update local time
                    $localLastWriteTime = (Get-Item $LocalPath).LastWriteTime
                    Write-Verbose "Updated local file last write time: $localLastWriteTime"
                } catch {
                    Write-Host "[$timestamp] ❌ Remote → Local sync error: $_" -ForegroundColor Red
                    # Clean up temp file on error
                    if ($tempRemoteFile -and (Test-Path $tempRemoteFile)) {
                        Remove-Item $tempRemoteFile -Force -ErrorAction SilentlyContinue
                        Write-Verbose "Removed temporary file after error: $tempRemoteFile"
                    }
                } finally {
                    $syncInProgress = $false
                }
            } else {
                $noActivityCount++
                # Show waiting message once every 2 minutes
                if ($noActivityCount -eq 240 -and -not $waitingMessageShown) {
                    $timestamp = Get-Date -Format "HH:mm:ss"
                    $syncType = if ($Dual) { "bidirectional" } else { "unidirectional" }
                    Write-Host "[$timestamp] 💤 Waiting for modifications ($syncType)..." -ForegroundColor DarkGray
                    $waitingMessageShown = $true
                }
                # Reset after 4 minutes to show message again
                if ($noActivityCount -eq 480) {
                    $noActivityCount = 0
                    $waitingMessageShown = $false
                    Write-Verbose "Reset waiting message flag after inactivity"
                }
            }

            Start-Sleep -Milliseconds 500
        }
    } catch [System.Management.Automation.HaltCommandException] {
        Write-Host "`n🛑 Monitoring interrupted by Ctrl+C" -ForegroundColor Yellow
    } catch {
        Write-Host "`n❌ Error in monitoring: $_" -ForegroundColor Red
    }
}
