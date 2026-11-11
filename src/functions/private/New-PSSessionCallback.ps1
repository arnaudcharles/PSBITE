# ------------------------------------------------------------------------------------------------
# Vendored from https://gist.github.com/jborean93/f5605dc05d9395831800753014222b7b
# Original file: New-PSSessionWithCallback.ps1
# Copyright: (c) 2026, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see THIRD_PARTY_NOTICES.md or https://opensource.org/licenses/MIT)
#
# Itself inspired by https://gist.github.com/SeeminglyScience/1b72f0fde3840b275dd23b4104776c5d
#
# Adapted for PSBITE: the original single file is split one function per file to match the module
# layout, and braces are restyled to match the module. See Enter-PSSessionWithCallback for the
# other half.
# ------------------------------------------------------------------------------------------------

function New-PSSessionCallback {
    <#
    .SYNOPSIS
        Defines a function in a remote session that calls back to the client.

    .DESCRIPTION
        Creates a callback definition to pass to Enter-PSSessionWithCallback. It defines a
        function with the given name in the remote session. When that function is called, it
        runs Pre remotely, then Callback on the client with Pre's output as positional
        arguments, then Post remotely with Callback's output as positional arguments. Post's
        output is the function's output.

        The remote function blocks while Callback runs, so the client console isn't reading
        input and Callback can use it freely, for example to run an interactive TUI such as
        the PSBITE editor.

    .PARAMETER Name
        The name of the function to define in the remote session. Each callback passed to
        Enter-PSSessionWithCallback needs a unique name.

    .PARAMETER Callback
        The scriptblock to run on the local client. It receives Pre's output as positional
        arguments, or the remote function's parameters by name if there is no Pre, and its
        output is passed to Post. If starting an interactive process, use Start-Process
        -NoNewWindow -Wait instead of calling it as a command. This ensures the console's
        TTYs are properly attached to the interactive process and not through PowerShell's
        redirected stdout pipe.

        The variable $PSSessionCallbackContext is available to the scriptblock with the
        properties Name (the callback name), State (the -State object), and ConnectionInfo
        (the RunspaceConnectionInfo) used to connect to the remote session, for example
        $PSSessionCallbackContext.ConnectionInfo.ComputerName for a WSManConnectionInfo.
        Treat its arguments as untrusted input, anything running in the remote session can
        invoke it.

    .PARAMETER Pre
        The scriptblock to run in the remote session before Callback. Its param block
        becomes the remote function's parameters and its output is passed to Callback as
        positional arguments. Comment-based help before the param block becomes the remote
        function's help.

        If not set, Callback's param block, attributes and help become the remote function's
        and the parameters bound remotely are passed to Callback by name. Any unbound
        arguments are passed positionally. The param block is evaluated on both sides, so
        its types and validation attributes need to work remotely as well.

    .PARAMETER Post
        The scriptblock to run in the remote session after Callback. It receives Callback's
        output as positional arguments and its output is the remote function's output. It
        runs in the same scope as Pre, so it can use variables Pre set. Defaults to
        outputting Callback's output.

        Pre and Post can use the variable $PSSessionCallbackContext with the properties
        Name (the callback name) and State (the remote copy of -State).

    .PARAMETER State
        An object available to the scriptblocks as $PSSessionCallbackContext.State.
        Callback gets this object, so changes it makes persist across calls and are visible
        to the caller. Pre and Post get a copy serialized to the remote session once when
        it's set up, changes they make persist across calls in that session but aren't
        sent back to the client. Like any remoting value, the copy is only serialized to a
        limited depth.

    .EXAMPLE
        New-PSSessionCallback -Name Get-LocalName -Callback { [Environment]::MachineName } |
            Enter-PSSessionWithCallback -Target server01

        Defines Get-LocalName in the remote session, which outputs the client's machine
        name. Without Pre and Post the function's arguments go straight to Callback and
        Callback's output is returned.

    .EXAMPLE
        $callback = New-PSSessionCallback -Name psbite -Pre {
            param([Parameter(Mandatory)]$Path)
            $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        } -Callback {
            param($Path)
            Start-PSBite -FilePath $Path -ComputerName $PSSessionCallbackContext.ConnectionInfo.ComputerName
        }
        $callback | Enter-PSSessionWithCallback -Target server01

        Defines 'psbite' in the remote session. Pre resolves the path on the remote side and
        Callback opens the local PSBITE editor against that remote path.

    .INPUTS
        None

    .OUTPUTS
        PSSessionCallback
        The callback definition to pass to Enter-PSSessionWithCallback.

    .NOTES
        Pre and Post are sent to the remote session as text, so they can't see local
        variables and $using: isn't supported. Values passed between the client and the
        remote session are serialized like any remoting output. The remote function doesn't
        support pipeline input.

        If Callback throws, the remote function throws "Callback for '<Name>' failed:
        <message>" and Post doesn't run.

        Author: Jordan Borean (@jborean93) - vendored into PSBITE under the MIT License.
    #>
    [OutputType('PSSessionCallback')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[\w-]+$')]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$Callback,

        [Parameter()]
        [scriptblock]$Pre,

        [Parameter()]
        [scriptblock]$Post = { $args },

        [Parameter()]
        [object]$State
    )

    [PSCustomObject]@{
        PSTypeName = 'PSSessionCallback'
        Name       = $Name
        Pre        = $Pre
        Callback   = $Callback
        Post       = $Post
        State      = $State
    }
}
