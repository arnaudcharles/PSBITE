function Start-PSBite {
    <#
    .SYNOPSIS
        Start the PSBITE text editor for local or remote file editing using WinRM.

    .DESCRIPTION
        PSBITE stand for "PowerShell Buffer Insert Text Editor", it's a VIM-like text editor that supports both local and remote file editing.
        It provides a familiar VIM interface with NORMAL and INSERT modes, character operations, and real-time remote synchronization.

    .PARAMETER FilePath
        Path to the file to edit (local or remote). Can be relative or absolute for local but must be absolute when using the remote.

    .PARAMETER ComputerName
        Remote computer name for remote editing (optional)

    .PARAMETER UseSSL
        Use SSL for remote connection (default: true)

    .PARAMETER Credential
        PowerShell credentials to use for the remote connection. Ignored if -Session is provided.

    .PARAMETER SkipCertificateCheck
        If specified, SSL/TLS certificate verification will be skipped. Ignored if -Session is provided.

    .PARAMETER Session
        An already-established PSSession to reuse instead of opening a new remote connection.

    .PARAMETER InitialLine
        1-based line number to place the cursor on when the editor opens (default: 1).

    .EXAMPLE
        Start-PSBite -FilePath "C:\test.txt"
        Edit a local file

    .EXAMPLE
        Start-PSBite -FilePath "C:\scripts\remote.ps1" -ComputerName "server01"
        Edit a remote file with real-time synchronization

    .NOTES
        Controls:
        - i       : Enter INSERT mode
        - Esc     : Enter NORMAL mode
        - y       : Yank (copy) line
        - dd      : Delete line
        - p       : Paste line
        - :w      : Save file
        - :q      : Quit
        - :q!     : Quit without saving
        - :wq     : Save and quit

        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingWriteHost", "", Justification = "Interactive editor with colored UI"
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions", "", Justification = "Interactive text editor - confirmations would break user experience"
    )]
    [OutputType([void])]
    [CmdletBinding()]
    [Alias('psbite')]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the file to edit")]
        [ValidateNotNullOrEmpty()]
        [Alias('f', 'File')]
        [string]$FilePath,

        [Parameter(HelpMessage = "Remote computer name for remote editing")]
        [Alias('cn', 'Computer')]
        [string]$ComputerName,

        [Parameter(HelpMessage = "Enable automatic file saving every 5 minutes")]
        [switch]$AutoSave,

        [Parameter(HelpMessage = "Use SSL for remote connection")]
        [bool]$UseSSL = $true,

        [Parameter(HelpMessage = "Credential to use for the remote connection")]
        [PSCredential]$Credential,

        [Parameter(HelpMessage = "Skip SSL/TLS certificate verification for the remote connection")]
        [switch]$SkipCertificateCheck,

        [Parameter(HelpMessage = "An already-established PSSession to reuse")]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [Parameter(HelpMessage = "1-based line number to place the cursor on when the editor opens")]
        [int]$InitialLine = 1
    )

    # Initialize global clipboard if not exists
    if (-not (Get-Variable -Name PSBiteClipboard -Scope Script -ErrorAction SilentlyContinue)) {
        $script:PSBiteClipboard = ""
    }

    # Determine mode
    $isRemote = -not [string]::IsNullOrEmpty($ComputerName)

    # Validate paths
    if ($isRemote) {
        # Check absolute path for remote mode
        if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
            Write-Error "❌ Remote mode requires an absolute file path."
            return
        }
    }

    if ($isRemote) {
        Write-Host "🌐 PSBITE - Remote Mode" -ForegroundColor Magenta
        Write-Host "   📂 Remote path: $FilePath" -ForegroundColor Cyan
        if ($AutoSave) { Write-Host "   ⏰ AutoSave: Every 5 minutes" -ForegroundColor Yellow }
        $remoteParams = @{
            FilePath             = $FilePath
            ComputerName         = $ComputerName
            UseSSL               = $UseSSL
            Credential           = $Credential
            SkipCertificateCheck = $SkipCertificateCheck
            Session              = $Session
            AutoSave             = $AutoSave
            InitialLine          = $InitialLine
        }
        Start-RemotePSBite @remoteParams
    } else {
        Write-Host "💻 PSBITE - Local Mode" -ForegroundColor Green
        Write-Host "   📂 Local path: $FilePath" -ForegroundColor Cyan
        if ($AutoSave) { Write-Host "   ⏰ AutoSave: Every 5 minutes" -ForegroundColor Yellow }
        Start-LocalPSBite -FilePath $FilePath -AutoSave:$AutoSave -InitialLine $InitialLine
    }
}
