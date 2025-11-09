function Read-RemoteFile {
    <#
    .SYNOPSIS
        Reads a remote file in read-only mode, creates a local snapshot, and opens it in an editor with auto-refresh and cleanup.

    .DESCRIPTION
        This function connects to a remote computer using an existing PSSession, reads the specified file in a read-only manner,
            and creates a local snapshot of the file.
        The local snapshot is opened in VSCode (if available) or Notepad for viewing.
        In RO mode : The function monitors the remote file for changes and refreshes the local snapshot every 15 seconds.
        The local file is automatically cleaned up after the session ends.

    .PARAMETER ComputerName
        The name of the remote computer.

    .PARAMETER RemotePath
        The full path to the remote file to read.

    .PARAMETER LocalTempDir
        (Optional) The local directory where the temporary read-only snapshot will be stored.

    .PARAMETER Session
        The PSSession object for the remote computer.

    .PARAMETER Silent
        If specified, suppresses interactive output.

    .PARAMETER Verbose
        If specified, enables verbose logging for debugging purposes.

    .EXAMPLE
        Read-RemoteFile -ComputerName "server01" -RemotePath "C:\Logs\app.log" -LocalTempDir "C:\Temp" -Session $session

    .NOTES
        This function is intended for read-only access to remote files using Edit-RemoteFile.
        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions", "", Justification = "Read-only file viewer - no state changes"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingWriteHost", "", Justification = "Interactive tool with colored output"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$RemotePath,

        [Parameter(Mandatory = $true)]
        [string]$LocalTempDir,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [switch]$Silent
    )

    if (-not $Silent) {
        Write-Host "`n📖 READ-ONLY MODE - File is locked by another process" -ForegroundColor Yellow
        Write-Host "   📂 Remote path: $RemotePath" -ForegroundColor Cyan
        Write-Host "   🔄 Auto-refresh: Every 15 seconds" -ForegroundColor Cyan
        Write-Host "   🗑️ Auto-cleanup: Enabled" -ForegroundColor Cyan
    }

    # Create local file path
    $fileName = Split-Path $RemotePath -Leaf
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $localFileName = "${ComputerName}_READONLY_${timestamp}_${fileName}"
    $localPath = Join-Path $LocalTempDir $localFileName

    try {
        # RO 1/3
        # Read remote file content
        if (-not $Silent) {
            Write-Host "`n[RO 1/3] Reading remote file..." -ForegroundColor Yellow
        }

        $fileContent = Invoke-Command -Session $Session -ScriptBlock {
            param($Path)
            try {
                return Get-Content -Path $Path -Raw -ErrorAction Stop
            } catch {
                return "# File could not be read: $_`n# Error: $($_.Exception.Message)"
            }
        } -ArgumentList $RemotePath

        # Create local read-only snapshot
        $fileContent | Set-Content -Path $localPath -Encoding UTF8 -Force

        if (-not $Silent) {
            Write-Host "✓ Read-only snapshot created: $localFileName" -ForegroundColor Green
        }

        # RO 2/3
        # Detect and open editor
        if (-not $Silent) {
            Write-Host "`n[RO 2/3] Opening editor..." -ForegroundColor Yellow
        }

        # Robust VSCode detection
        $vscodeAvailable = $false
        try {
            $vscodeProcess = Start-Process "code" -ArgumentList "--version" -WindowStyle Hidden -PassThru -ErrorAction Stop -Wait
            if ($vscodeProcess.ExitCode -eq 0) {
                $vscodeAvailable = $true
            }
        } catch {
            $vscodeAvailable = $false
        }

        if ($vscodeAvailable) {
            # Configure VSCode trusted folders
            try {
                $configResult = Set-VSCodeConfiguration -TempDir $LocalTempDir
                if (-not $Silent -and $configResult) {
                    Write-Host "✓ VSCode configured for trusted mode" -ForegroundColor Green
                }
            } catch {
                # Continue anyway
                Write-Debug -Message "VSCode configuration failed for trusted mode"
            }

            # Open with VSCode
            Start-Process "code" -ArgumentList "`"$localPath`"" -WindowStyle Hidden
            Start-Sleep -Seconds 2

            if (-not $Silent) {
                Write-Host "✓ VSCode opened with read-only file" -ForegroundColor Green
            }
        } else {
            # Open with Notepad
            Start-Process "notepad.exe" -ArgumentList "`"$localPath`"" -WindowStyle Normal
            Start-Sleep -Seconds 1

            if (-not $Silent) {
                Write-Host "✓ Notepad opened with read-only file" -ForegroundColor Green
            }
        }

        # RO 3/3
        # Start read-only monitoring
        if (-not $Silent) {
            Write-Host "`n[RO 3/3] Starting read-only monitoring..." -ForegroundColor Yellow
        }
        Write-Host "👁️ Read-only monitoring active - Remote → Local refresh every 15s" -ForegroundColor Magenta
        Write-Host "🔄 Press Ctrl+E to stop read-only session" -ForegroundColor Cyan

        Read-FileWatcher -LocalPath $localPath -RemotePath $RemotePath -Session $Session -ComputerName $ComputerName -Silent:$Silent

    } finally {
        # Force cleanup in read-only mode
        if ($localPath -and (Test-Path $localPath)) {
            Remove-Item $localPath -Force -ErrorAction SilentlyContinue
            if (-not $Silent) {
                Write-Host "`n✓ Read-only file cleaned up" -ForegroundColor Yellow
            }
        }
    }
}
