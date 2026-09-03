function Start-RemotePSBite {
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

    .PARAMETER Credential
        PowerShell credentials to use for the remote session. Ignored if -Session is provided.

    .PARAMETER SkipCertificateCheck
        If specified, SSL/TLS certificate verification will be skipped. Ignored if -Session is provided.

    .PARAMETER Session
        An already-established PSSession to reuse instead of opening a new connection.

    .PARAMETER AutoSave
        If set, automatically saves changes to the remote file.

    .PARAMETER InitialLine
        1-based line number to place the cursor on when the editor opens (default: 1).

    .EXAMPLE
        Start-RemotePSBite -FilePath "C:\Scripts\MyScript.ps1" -ComputerName "Server01" -UseSSL $true -AutoSave

    .NOTES
        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [OutputType()]
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [string]$ComputerName,
        [bool]$UseSSL,
        [PSCredential]$Credential,
        [switch]$SkipCertificateCheck,
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [Parameter()]
        [switch]$AutoSave,

        [Parameter()]
        [int]$InitialLine = 1
    )

    $session = $null
    $localTempFile = $null
    $ownsSession = $false

    try {
        if ($Session) {
            # Reuse a session opened by the caller (e.g. an explorer already connected)
            $session = $Session
            Write-Host "🔗 Reusing existing session to $ComputerName..." -ForegroundColor Yellow
        } else {
            Write-Host "🔗 Connecting to $ComputerName..." -ForegroundColor Yellow

            # Create remote session
            $sessionParams = @{
                ComputerName = $ComputerName
                ErrorAction  = 'Stop'
            }
            if ($UseSSL) { $sessionParams.UseSSL = $true }
            if ($Credential) {
                $sessionParams.Credential = $Credential
                # Negotiate allows NTLM fallback for cross-domain/bastion hosts where Kerberos SPN resolution fails
                $sessionParams.Authentication = 'Negotiate'
            }
            if ($SkipCertificateCheck) { $sessionParams.SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck }

            $session = New-PSSession @sessionParams
            $ownsSession = $true
            Write-Host "✅ Connected to $ComputerName" -ForegroundColor Green
        }

        # Check remote permissions
        Write-Host "🔐 Checking remote permissions..." -ForegroundColor Yellow
        $permissionCheck = Test-PSBitePermission -FilePath $FilePath -IsRemote -Session $session
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
                    $null = New-Item -Path $directory -ItemType Directory -Force
                }
                $null = New-Item -Path $Path -ItemType File -Force
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
            $null = New-Item -Path $tempDir -ItemType Directory -Force
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = Split-Path $FilePath -Leaf
        $localTempFile = "$tempDir\${ComputerName}_${timestamp}_${fileName}"

        # Download remote file
        Write-Host "📥 Downloading remote file..." -ForegroundColor Yellow
        Copy-Item -Path $FilePath -Destination $localTempFile -FromSession $session -Force
        Write-Host "✅ File downloaded" -ForegroundColor Green

        # Start PSBITE with remote sync
        $editorParams = @{
            LocalPath    = $localTempFile
            RemotePath   = $FilePath
            Session      = $session
            ComputerName = $ComputerName
            AutoSave     = $AutoSave
            InitialLine  = $InitialLine
        }
        Start-RemotePSBiteEditor @editorParams
    } catch {
        Write-Error "Error in Remote PSBITE: $_"
    } finally {
        if ($session -and $ownsSession) {
            Remove-PSSession $session -ErrorAction SilentlyContinue
        }
        if ($localTempFile -and (Test-Path $localTempFile)) {
            Remove-Item $localTempFile -Force -ErrorAction SilentlyContinue
        }
    }
}
