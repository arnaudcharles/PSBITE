<#
.SYNOPSIS
Starts a remote PSBite session on a specified computer.

.DESCRIPTION
This function establishes a PowerShell remoting session to a target computer, verifies permissions,
synchronizes a file for editing, and launches the PSBite editor with remote sync capabilities.

.PARAMETER FilePath
The path to the file on the remote computer to edit.

.PARAMETER ComputerName
The name or IP address of the remote computer.

.PARAMETER UseSSL
Specifies whether to use SSL for the remote session.

.PARAMETER AutoSave
If set, automatically saves changes to the remote file.

.EXAMPLE
Start-RemotePSBite -FilePath "C:\Scripts\MyScript.ps1" -ComputerName "Server01" -UseSSL $true -AutoSave
#>
function Start-RemotePSBite {
    [OutputType()]
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [string]$ComputerName,
        [bool]$UseSSL,

        [Parameter()]
        [switch]$AutoSave
    )

    $session = $null
    $localTempFile = $null

    try {
        Write-Host "🔗 Connecting to $ComputerName..." -ForegroundColor Yellow

        # Create remote session
        $sessionParams = @{
            ComputerName = $ComputerName
            ErrorAction = 'Stop'
        }
        if ($UseSSL) { $sessionParams.UseSSL = $true }

        $session = New-PSSession @sessionParams
        Write-Host "✅ Connected to $ComputerName" -ForegroundColor Green

        # Check remote permissions
        Write-Host "🔐 Checking remote permissions..." -ForegroundColor Yellow
        $permissionCheck = Test-PSBitePermissions -FilePath $FilePath -IsRemote -Session $session
        Write-Host $permissionCheck.Message -ForegroundColor $permissionCheck.Color

        if (-not $permissionCheck.CanWrite) {
            Write-Host "⚠️  Cannot proceed - insufficient remote permissions" -ForegroundColor Red
            return
        }

        # Verify/Create remote file
        $fileExists = Invoke-Command -Session $session -ScriptBlock {
            param($Path)
            if (-not (Test-Path $Path)) {
                $directory = Split-Path $Path -Parent
                if ($directory -and -not (Test-Path $directory)) {
                    New-Item -Path $directory -ItemType Directory -Force | Out-Null
                }
                New-Item -Path $Path -ItemType File -Force | Out-Null
                return $false
            }
            return $true
        } -ArgumentList $FilePath

        if ($fileExists) {
            Write-Host "📄 Remote file found" -ForegroundColor Green
        } else {
            Write-Host "📝 Remote file created" -ForegroundColor Yellow
        }

        # Create local temp file
        $tempDir = "$env:TEMP\PSBite"
        if (-not (Test-Path $tempDir)) {
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = Split-Path $FilePath -Leaf
        $localTempFile = "$tempDir\${ComputerName}_${timestamp}_${fileName}"

        # Download remote file
        Write-Host "📥 Downloading remote file..." -ForegroundColor Yellow
        Copy-Item -Path $FilePath -Destination $localTempFile -FromSession $session -Force
        Write-Host "✅ File downloaded" -ForegroundColor Green

        # Start PSBITE with remote sync
        Start-RemotePSBiteEditor -LocalPath $localTempFile -RemotePath $FilePath -Session $session -ComputerName $ComputerName -AutoSave:$AutoSave
    }
    catch {
        Write-Error "Error in Remote PSBITE: $_"
    }
    finally {
        if ($session) {
            Remove-PSSession $session -ErrorAction SilentlyContinue
        }
        if ($localTempFile -and (Test-Path $localTempFile)) {
            Remove-Item $localTempFile -Force -ErrorAction SilentlyContinue
        }
    }
}
