function Edit-RemoteFile {
    <#
    .SYNOPSIS
        Edit a remote file via VSCode with automatic synchronization using WinRM

    .DESCRIPTION
        Allows editing files on remote Windows servers via WinRM by synchronizing them automatically with VSCode.
        Supports both unidirectional (local to remote) and bidirectional synchronization.
        Falls back to Notepad if VSCode is not available.
        If files like logs are locked, switches to read-only mode with periodic refresh, 15s by default.
        In RO mode, -DelTemp parameter is set up by default, save and sync is disabled.

    .PARAMETER ComputerName
        Remote server name or FQDN

    .PARAMETER RemotePath
        Full path to the file on the remote server

    .PARAMETER LocalTempDir
        Local temporary directory for file synchronization (default: $env:TEMP\RemoteEdit)

    .PARAMETER UseSSL
        Use SSL for WinRM connection (default: true)

    .PARAMETER DelTemp
        Delete temporary file when finished (default: false - file is preserved)

    .PARAMETER Dual
        Enable bidirectional synchronization - monitors both local and remote file changes

    .PARAMETER Silent
        Minimal output - show only essential connection and monitoring messages

    .PARAMETER Verbose
        Enable verbose output for debugging and detailed information. SO AJ :-)

    .EXAMPLE
        Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1"
        Edit a remote PowerShell script with SSL and unidirectional sync

    .EXAMPLE
        Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Dual
        Edit with bidirectional synchronization (remote changes are pulled to local)

    .EXAMPLE
        Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Silent
        Edit with minimal output showing only essential messages

    .EXAMPLE
        Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -DelTemp
        Edit and delete temporary file when finished

    .NOTES
        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions", "", Justification = "Real-time file synchronization tool - confirmations would break user experience"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingWriteHost", "", Justification = "Interactive tool with colored output for better user experience - Write-Host is appropriate here"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseUsingScopeModifierInNewRunspaces", "")]
    [OutputType()]
    [CmdletBinding()]
    [Alias('bite', 'teub', 'erf')]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Remote server name or FQDN")]
        [ValidateNotNullOrEmpty()]
        [Alias('cn')]
        [string]$ComputerName,

        [Parameter(Mandatory = $true, HelpMessage = "Full path to the remote file")]
        [ValidateNotNullOrEmpty()]
        [Alias('f')]
        [string]$RemotePath,

        [Parameter(HelpMessage = "Local temporary directory")]
        [ValidateNotNullOrEmpty()]
        [string]$LocalTempDir = "$env:TEMP\RemoteEdit",

        [Parameter(HelpMessage = "Use SSL for WinRM connection")]
        [bool]$UseSSL = $true,

        [Parameter(HelpMessage = "Delete temporary file when finished")]
        [Alias('d')]
        [switch]$DelTemp,

        [Parameter(HelpMessage = "Enable bidirectional synchronization")]
        [Alias('b')]
        [switch]$Dual,

        [Parameter(HelpMessage = "Minimal output - show only essential connection and monitoring messages")]
        [switch]$Silent
    )

    $session = $null
    $readOnlyMode = $false

    try {
        # Header
        if (-not $Silent) {
            $syncMode = if ($Dual) { "bidirectional" } else { "unidirectional" }
            Write-Host "🚀 Establishing remote edit on $ComputerName, file $RemotePath ($syncMode sync)..." -ForegroundColor Green
        }

        # 1. Create remote session (with MOTD suppression)
        if (-not $Silent) {
            Write-Host "`n[1/7] Connecting to remote server..." -ForegroundColor Yellow
        }

        $sessionOption = New-PSSessionOption -NoMachineProfile
        $sessionParams = @{
            ComputerName  = $ComputerName
            ErrorAction   = 'Stop'
            SessionOption = $sessionOption
        }
        if ($UseSSL) {
            $sessionParams.UseSSL = $true
            if (-not $Silent) { Write-Verbose "Using SSL connection" }
        } else {
            if (-not $Silent) { Write-Verbose "Using non-SSL connection" }
        }

        # Create session and handle MOTD suppression
        $session = New-PSSession @sessionParams

        if ($Silent) {
            # In silent mode, just clear the buffer quietly
            [Console]::Clear()
            Write-Host "Session established with $ComputerName" -ForegroundColor Green
        } else {
            # In verbose mode, clear and re-display progress
            Clear-Host
            $syncMode = if ($Dual) { "bidirectional" } else { "unidirectional" }
            Write-Host "🚀 Establishing remote edit on $ComputerName, file $RemotePath ($syncMode sync)..." -ForegroundColor Green
            Write-Host "`n[1/7] Connecting to remote server..." -ForegroundColor Yellow
            Write-Host "✓ Session established with $ComputerName" -ForegroundColor Green
        }
        # Logs
        Write-Verbose "Local file will be in: $LocalTempDir"
        Write-Verbose "Remote file is: $RemotePath"
        Write-Verbose "Session details: $($session | Format-List | Out-String)"
        Write-Verbose "UseSSL: $UseSSL, DelTemp: $DelTemp, Dual: $Dual, Silent: $Silent"

        # 2. Check/Create remote file
        if (-not $Silent) {
            Write-Host "`n[2/7] Verifying remote file..." -ForegroundColor Yellow
        }

        $fileExists = Invoke-Command -Session $session -ScriptBlock {
            param($Path)

            if (-not (Test-Path $Path)) {
                $directory = Split-Path $Path -Parent
                if ($directory -and -not (Test-Path $directory)) {
                    try {
                        $null = New-Item -Path $directory -ItemType Directory -Force
                        Write-Output "Directory created: $directory"
                        Write-Verbose "Directory did not exist and was created: $directory"
                    } catch {
                        Write-Error "Cannot create directory: $directory - $_"
                        return $false
                    }
                }

                try {
                    $null = New-Item -Path $Path -ItemType File -Force
                    Write-Output "File created: $Path"
                    Write-Verbose "File did not exist and was created: $Path"
                    return $true
                } catch {
                    Write-Error "Cannot create file: $Path - $_"
                    return $false
                }
            } else {
                Write-Output "File exists: $Path"
                Write-Verbose "File exists and is ready for editing: $Path"
                return $true
            }
        } -ArgumentList $RemotePath

        if (-not $fileExists) {
            throw "Unable to create or access remote file"
        }

        if (-not $Silent) {
            Write-Host "✓ Remote file ready" -ForegroundColor Green
        }

        # 3. Prepare local environment
        if (-not $Silent) {
            Write-Host "`n[3/7] Preparing local environment..." -ForegroundColor Yellow
        }

        if (-not (Test-Path $LocalTempDir)) {
            $null = New-Item -Path $LocalTempDir -ItemType Directory -Force
        }

        $fileName = Split-Path $RemotePath -Leaf
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $localFileName = "${ComputerName}_${timestamp}_${fileName}"
        $localPath = Join-Path $LocalTempDir $localFileName
        Write-Verbose "Filename = $fileName, LocalPath = $localPath, LocalTempDir = $LocalTempDir, LocalFileName = $localFileName, Timestamp = $timestamp"

        if (-not $Silent) {
            Write-Host "✓ Local directory: $LocalTempDir" -ForegroundColor Green
            Write-Host "✓ Local file: $localFileName" -ForegroundColor Green
        }

        # 4. Copy remote file to local (with locked file detection)
        if (-not $Silent) {
            Write-Host "`n[4/7] Copying remote file to local..." -ForegroundColor Yellow
        }

        try {
            # Try normal copy first
            Copy-Item -Path $RemotePath -Destination $localPath -FromSession $session -Force -ErrorAction Stop

            if (-not $Silent) {
                Write-Host "✓ File copied: $localPath" -ForegroundColor Green
            }
        } catch {
            # If copy fails due to locked file, switch to read-only mode
            if ($_.Exception.Message -like "*being used by another process*") {
                if (-not $Silent) {
                    Write-Host "⚠️ File is locked by another process - Switching to READ-ONLY mode..." -ForegroundColor Red
                }
                # Call Read-RemoteFile
                $readOnlyMode = $true
                Read-RemoteFile -ComputerName $ComputerName -RemotePath $RemotePath -LocalTempDir $LocalTempDir -Session $session -Silent:$Silent
                return  # Exit Edit-RemoteFile --> Read-RemoteFile
            } else {
                throw $_
            }
        }

        # 5. Detect editor and configure if needed
        if (-not $Silent) {
            Write-Host "`n[5/7] Detecting and configuring editor..." -ForegroundColor Yellow
        }

        # Robust VSCode detection - test if it actually works
        $vscodeAvailable = $false
        try {
            # Test if code command actually works by checking version
            $vscodeProcess = Start-Process "code" -ArgumentList "--version" -WindowStyle Hidden -PassThru -ErrorAction Stop -Wait
            if ($vscodeProcess.ExitCode -eq 0) {
                $vscodeAvailable = $true
                Write-Verbose "VSCode detected and working"
            }
        } catch {
            $vscodeAvailable = $false
        }

        if ($vscodeAvailable) {
            # Configure VSCode trusted folders
            try {
                $configResult = Set-VSCodeConfiguration -TempDir $LocalTempDir
                if (-not $Silent) {
                    if ($configResult) {
                        Write-Host "✓ VSCode detected and configured for trusted mode" -ForegroundColor Green
                    } else {
                        Write-Host "⚠️ VSCode detected but configuration failed, restricted mode possible" -ForegroundColor Yellow
                    }
                }
            } catch {
                if (-not $Silent) {
                    Write-Host "⚠️ VSCode detected but configuration error: $_" -ForegroundColor Yellow
                }
            }
        } else {
            if (-not $Silent) {
                Write-Host "⚠️ VSCode not found, will use Notepad as fallback" -ForegroundColor Yellow
            }
        }

        # 6. Open editor
        if (-not $Silent) {
            Write-Host "`n[6/7] Opening editor..." -ForegroundColor Yellow
        }

        if ($vscodeAvailable) {
            # Open with VSCode
            Start-Process "code" -ArgumentList "`"$localPath`"" -WindowStyle Hidden
            Start-Sleep -Seconds 2
            Write-Verbose "VSCode started for file: $localPath"

            if (-not $Silent) {
                Write-Host "✓ VSCode opened with file" -ForegroundColor Green
            }
        } else {
            # Open with Notepad
            Start-Process "notepad.exe" -ArgumentList "`"$localPath`"" -WindowStyle Normal
            Start-Sleep -Seconds 1
            Write-Verbose "Notepad started for file: $localPath"

            if (-not $Silent) {
                Write-Host "✓ Notepad opened with file" -ForegroundColor Green
            }
        }

        # 7. Start file monitoring (ALWAYS SHOW)
        Write-Host "`n[7/7] Starting file monitoring..." -ForegroundColor Yellow
        if ($Dual) {
            Write-Host "👀 Bidirectional monitoring active - Local ↔ Remote synchronization" -ForegroundColor Cyan
        } else {
            Write-Host "👀 Unidirectional monitoring active - Local → Remote synchronization" -ForegroundColor Cyan
        }
        Write-Host "🔄 Press Ctrl+E to stop remote edit" -ForegroundColor Cyan

        # Verbose file info (only if verbose AND not silent)
        if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"] -and -not $Silent) {
            Write-Host "📁 Local file: $localPath" -ForegroundColor Gray
            Write-Host "📁 Remote file: $RemotePath on $ComputerName" -ForegroundColor Gray
        }

        Write-Verbose "Starting file watcher with parameters: LocalPath=$localPath, RemotePath=$RemotePath, ComputerName=$ComputerName, Dual=$Dual"
        Start-FileWatcher -LocalPath $localPath -RemotePath $RemotePath -Session $session -ComputerName $ComputerName -Dual:$Dual

    } catch {
        Write-Error "Error in Edit-RemoteFile: $_"
        if (-not $Silent) {
            Write-Host "Error details:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    } finally {
        if ($session) {
            Remove-PSSession $session -ErrorAction SilentlyContinue
            if (-not $Silent) {
                Write-Host "`n✓ Session closed" -ForegroundColor Yellow
            }
        }

        # Skip file management if we're in read-only mode
        if (-not $readOnlyMode) {
            # Temporary file management
            if ($localPath -and (Test-Path $localPath)) {
                if ($DelTemp) {
                    Remove-Item $localPath -Force -ErrorAction SilentlyContinue
                    if (-not $Silent) {
                        Write-Host "✓ Local file deleted (-DelTemp parameter)" -ForegroundColor Yellow
                    }
                } else {
                    if (-not $Silent) {
                        Write-Host "`n📁 Local file preserved: $localPath" -ForegroundColor Green
                        Write-Host "💡 Will be automatically deleted on next reboot" -ForegroundColor Gray
                    }
                }
            }

            if (-not $Silent) {
                Write-Host "`n🏁 Remote-Edit completed" -ForegroundColor Green
            }
        }
    }
}
