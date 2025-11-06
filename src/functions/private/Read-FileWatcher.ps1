<#
.SYNOPSIS
Monitors a remote file for changes and updates a local copy at regular intervals.

.DESCRIPTION
Read-FileWatcher periodically reads the content of a remote file via a PowerShell session and updates a local file with the latest content.
The function checks for user interruption (Ctrl+E), local file deletion, and handles errors gracefully.
It is intended for interactive, read-only monitoring scenarios.

.PARAMETER LocalPath
The path to the local file to update with the remote file's content.

.PARAMETER RemotePath
The path to the remote file to monitor and read.

.PARAMETER Session
The PSSession object used to connect to the remote computer.

.PARAMETER ComputerName
The name of the remote computer being monitored.

.PARAMETER Silent
If specified, suppresses interactive output (not currently implemented).

.EXAMPLE
Read-FileWatcher -LocalPath "C:\Temp\log.txt" -RemotePath "C:\Logs\log.txt" -Session $session -ComputerName "Server01"

Monitors the remote file 'C:\Logs\log.txt' on 'Server01' and updates the local file 'C:\Temp\log.txt' every 15 seconds.

.NOTES
    This function is intended for read-only access to remote files using Edit-RemoteFile.
#>
function Read-FileWatcher {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions", "", Justification = "Read-only file monitoring - no state changes"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingWriteHost", "", Justification = "Interactive monitoring tool"
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

        [switch]$Silent
    )

    $refreshCount = 0

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

            # Auto-refresh every 15 seconds (15 sec = 30 * 500ms)
            $refreshCount++
            if ($refreshCount -ge 30) {
                try {
                    Write-Verbose "Attempting to refresh remote file content..."
                    # Read updated remote content
                    $fileContent = Invoke-Command -Session $Session -ScriptBlock {
                        param($Path)
                        try {
                            Write-Verbose "Reading remote file content from $Path"
                            return Get-Content -Path $Path -Raw -ErrorAction Stop
                        } catch {
                            return "# File could not be read: $_`n# Error: $($_.Exception.Message)"
                        }
                    } -ArgumentList $RemotePath

                    # Update local file
                    $fileContent | Set-Content -Path $LocalPath -Encoding UTF8 -Force
                    Write-Verbose "Updated local file with refreshed content"

                    # Update status line
                    $timestamp = Get-Date -Format "HH:mm:ss"
                    Write-Host "`r[$timestamp] ✅ Last refresh: $ComputerName                    " -ForegroundColor Green -NoNewline

                    $refreshCount = 0
                } catch {
                    $timestamp = Get-Date -Format "HH:mm:ss"
                    Write-Host "`r[$timestamp] ❌ Refresh error                              " -ForegroundColor Red -NoNewline
                    $refreshCount = 0
                }
            }

            Start-Sleep -Milliseconds 500
        }
    } catch [System.Management.Automation.HaltCommandException] {
        Write-Host "`n🛑 Read-only monitoring interrupted by Ctrl+C" -ForegroundColor Yellow
    } catch {
        Write-Host "`n❌ Error in read-only monitoring: $_" -ForegroundColor Red
    }
}
