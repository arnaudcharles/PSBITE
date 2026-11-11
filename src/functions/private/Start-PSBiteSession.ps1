function Start-PSBiteSession {
    <#
    .SYNOPSIS
        Enters an interactive remote session in which the PSBITE commands run on the local host.

    .DESCRIPTION
        Connects to a remote computer like Enter-PSSession and defines the PSBITE commands inside
        that session. Calling 'Start-PSBite' or 'Edit-RemoteFile' from the remote prompt resolves
        the path on the remote side, then runs the real command on the local machine against that
        remote path. The remote prompt stays blocked until the editor is closed.

        Nothing is installed or configured on the remote computer, the callbacks are driven
        entirely from local code.

    .PARAMETER ComputerName
        The name or FQDN of the remote computer to enter.

    .PARAMETER UseSSL
        Use SSL for the WinRM connection, port 5986 instead of 5985.

    .PARAMETER Credential
        PowerShell credentials to use for the remote connection.

    .PARAMETER SkipCertificateCheck
        If specified, SSL/TLS certificate verification will be skipped.

    .EXAMPLE
        Start-PSBiteSession -ComputerName "server01"

        Enters server01, where 'psbite .\test.txt' opens the local PSBITE editor on the remote file.

    .NOTES
        Built on the session callback mechanism contributed by Jordan Borean (@jborean93), see
        New-PSSessionCallback and Enter-PSSessionWithCallback.

        Any code running in the remote session can invoke these callbacks, so only enter sessions
        on hosts you trust.

        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingWriteHost", "", Justification = "Interactive editor with colored UI"
    )]
    [OutputType()]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter()]
        [bool]$UseSSL = $true,

        [Parameter()]
        [PSCredential]$Credential,

        [Parameter()]
        [switch]$SkipCertificateCheck
    )

    try {
        # Built by hand rather than through New-PSSession because the runspace is pushed, not
        # wrapped in a PSSession. Scheme has to be set before Port: assigning it resets the port
        # to the scheme default (80/443) instead of the WinRM ones.
        $connectionInfo = [System.Management.Automation.Runspaces.WSManConnectionInfo]::new()
        $connectionInfo.ComputerName = $ComputerName
        if ($UseSSL) {
            $connectionInfo.Scheme = 'https'
            $connectionInfo.Port = 5986
        } else {
            $connectionInfo.Scheme = 'http'
            $connectionInfo.Port = 5985
        }
        if ($Credential) {
            $connectionInfo.Credential = $Credential
            # Negotiate allows NTLM fallback for cross-domain/bastion hosts where Kerberos SPN resolution fails
            $connectionInfo.AuthenticationMechanism = [System.Management.Automation.Runspaces.AuthenticationMechanism]::Negotiate
        }
        if ($SkipCertificateCheck) {
            $connectionInfo.SkipCACheck = $true
            $connectionInfo.SkipCNCheck = $true
            $connectionInfo.SkipRevocationCheck = $true
        }

        # Pre runs on the remote host. It only turns the path the user typed into an absolute one,
        # which is what the local commands need, every other step happens locally in Callback.
        $resolveFilePath = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the remote file to edit")]
                [ValidateNotNullOrEmpty()]
                [Alias('f', 'File')]
                [string]$FilePath
            )
            $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
        }

        $resolveRemotePath = {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the remote file to edit")]
                [ValidateNotNullOrEmpty()]
                [Alias('f')]
                [string]$RemotePath
            )
            $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RemotePath)
        }

        # The connection options travel in a closure rather than through -State, because -State is
        # serialized into the remote session and the remote side never needs them, let alone the
        # credential. Callback itself is only ever run locally and is never sent over the wire.
        $editorCallback = {
            param($Path)

            $params = @{
                FilePath             = $Path
                ComputerName         = $PSSessionCallbackContext.ConnectionInfo.ComputerName
                UseSSL               = $UseSSL
                Credential           = $Credential
                SkipCertificateCheck = $SkipCertificateCheck
            }
            Start-PSBite @params
        }.GetNewClosure()

        $externalEditorCallback = {
            param($Path)

            $params = @{
                ComputerName         = $PSSessionCallbackContext.ConnectionInfo.ComputerName
                RemotePath           = $Path
                UseSSL               = $UseSSL
                Credential           = $Credential
                SkipCertificateCheck = $SkipCertificateCheck
            }
            Edit-RemoteFile @params
        }.GetNewClosure()

        # Each name becomes a real function in the remote session, so the commands and their short
        # aliases are called there exactly as they are called locally.
        $callbacks = @(
            foreach ($name in 'Start-PSBite', 'psbite') {
                New-PSSessionCallback -Name $name -Pre $resolveFilePath -Callback $editorCallback
            }
            foreach ($name in 'Edit-RemoteFile', 'bite') {
                New-PSSessionCallback -Name $name -Pre $resolveRemotePath -Callback $externalEditorCallback
            }
        )

        Write-Host "🔗 Connecting to $ComputerName..." -ForegroundColor Yellow
        Write-Host "   📝 Start-PSBite <file>    (alias: psbite) - terminal editor" -ForegroundColor Cyan
        Write-Host "   🔗 Edit-RemoteFile <file> (alias: bite)   - VSCode / Notepad" -ForegroundColor Cyan
        Write-Host "   🚪 exit                                   - leave the session" -ForegroundColor Gray

        # Pushes the remote runspace and returns, so anything written after this lands on top of
        # the remote prompt. The banner above is printed first on purpose.
        $callbacks | Enter-PSSessionWithCallback -ConnectionInfo $connectionInfo
    } catch {
        Write-Error "Error in PSBITE Session: $_"
    }
}
