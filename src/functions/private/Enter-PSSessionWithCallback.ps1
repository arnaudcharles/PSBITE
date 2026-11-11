#SkipTest:FunctionCount:Invoke-PSSessionCallback and Invoke-LocalCallback are defined inside a New-Module scriptblock that is serialized to, and only ever runs on, the remote host
#SkipTest:FunctionName:The two inner functions are remote-only, the file is named after the single function it actually exports locally

# ------------------------------------------------------------------------------------------------
# Vendored from https://gist.github.com/jborean93/f5605dc05d9395831800753014222b7b
# Original file: New-PSSessionWithCallback.ps1
# Copyright: (c) 2026, Jordan Borean (@jborean93) <jborean93@gmail.com>
# MIT License (see THIRD_PARTY_NOTICES.md or https://opensource.org/licenses/MIT)
#
# Itself inspired by https://gist.github.com/SeeminglyScience/1b72f0fde3840b275dd23b4104776c5d
#
# Adapted for PSBITE:
#   - split one function per file to match the module layout (see New-PSSessionCallback)
#   - the original 'using namespace' statements are replaced by fully qualified type names,
#     because the PSModule build concatenates every source file into a single .psm1 where a
#     'using' statement would no longer be the first statement and would fail to parse
#   - braces restyled and hashtable assignments aligned to satisfy the module's PSScriptAnalyzer
#   - one upstream error-path fix, marked inline
# ------------------------------------------------------------------------------------------------

function Enter-PSSessionWithCallback {
    <#
    .SYNOPSIS
        Starts an interactive session with a remote computer that can call back to the client.

    .DESCRIPTION
        Enters an interactive session with a remote computer like Enter-PSSession, with the
        functions defined by New-PSSessionCallback available in it. When one of those
        functions runs remotely, it runs its Callback scriptblock on the client before
        continuing in the remote session.

        Exiting the session closes the remote connection.

    .PARAMETER Target
        The target to connect to, its meaning depends on -Transport:

        WinRM: the computer name.
        SSH: [user@]host[:port] like Enter-PSSession -HostName.
        NamedPipe: the custom pipe name of a local pwsh process, like pwsh -CustomPipeName.
        PwshProcess: the process id of a local pwsh process, like Enter-PSHostProcess.

        -ComputerName is an alias of this parameter.

    .PARAMETER Transport
        The protocol used to connect to -Target, WinRM, SSH, NamedPipe or PwshProcess.
        Defaults to WinRM. Use -ConnectionInfo for anything these don't cover, like
        credentials or other transports.

    .PARAMETER ConnectionInfo
        The connection info to connect with, for example a WSManConnectionInfo with
        credentials or an SSHConnectionInfo with a key file. It is available to the
        callbacks as $PSSessionCallbackContext.ConnectionInfo.

    .PARAMETER Callback
        The callback definitions from New-PSSessionCallback to define in the remote session.
        Accepts pipeline input. A definition with invalid values, or with the same name as
        an earlier one, writes an error and is skipped.

    .EXAMPLE
        New-PSSessionCallback -Name Get-LocalName -Callback { [Environment]::MachineName } |
            Enter-PSSessionWithCallback -Target server01

        Enters a session on server01 where Get-LocalName outputs the client's machine name.

    .EXAMPLE
        $callbacks | Enter-PSSessionWithCallback admin@server01:2222 -Transport SSH

        Enters a session on server01 over SSH as admin on port 2222.

    .EXAMPLE
        $connInfo = [System.Management.Automation.Runspaces.WSManConnectionInfo]@{
            ComputerName = 'server01'
            Credential   = Get-Credential
        }
        $callbacks | Enter-PSSessionWithCallback -ConnectionInfo $connInfo

        Enters a session on server01 over WinRM with explicit credentials.

    .INPUTS
        PSSessionCallback
        The callback definitions from New-PSSessionCallback.

    .OUTPUTS
        None

    .NOTES
        The host must support pushing runspaces, like the pwsh console. Ctrl+C while a
        Callback scriptblock runs stops the remote function, not the scriptblock, unless the
        scriptblock reads Ctrl+C as input, for example by setting
        [Console]::TreatControlCAsInput.

        Author: Jordan Borean (@jborean93) - vendored into PSBITE under the MIT License.
    #>
    [OutputType()]
    [CmdletBinding(DefaultParameterSetName = 'Target')]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Target')]
        [Alias('ComputerName')]
        [ValidateNotNullOrEmpty()]
        [string]$Target,

        [Parameter(ParameterSetName = 'Target')]
        [ValidateSet('WinRM', 'SSH', 'NamedPipe', 'PwshProcess')]
        [string]$Transport = 'WinRM',

        [Parameter(Mandatory, ParameterSetName = 'ConnectionInfo')]
        [System.Management.Automation.Runspaces.RunspaceConnectionInfo]$ConnectionInfo,

        [Parameter(ValueFromPipeline)]
        [PSTypeName('PSSessionCallback')]
        [PSObject[]]$Callback
    )
    begin {
        if (-not ($Host -and $Host -is [System.Management.Automation.Host.IHostSupportsInteractiveSession])) {
            $e = [System.Management.Automation.ErrorRecord]::new(
                [ArgumentException]"The host does not support the required user interface.",
                "HostIsNotInteractive",
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null)
            $PSCmdlet.ThrowTerminatingError($e)
        }

        # Events forwarded from the remote side land in the remote runspace's own event
        # queue. New-PSSession subscribes to that queue and re-queues each event locally
        # so our subscribers see it, a runspace from RunspaceFactory doesn't. A
        # scriptblock can't be the handler as it is raised on a remoting thread with no
        # runspace. We could use Add-Type but as it's a simple enough delegate we use an
        # expression tree to avoid the compilation overhead. The event's sender is set
        # to an object holding the remote runspace and this session's local callbacks,
        # so $OnInvoke knows what to run and how to tell the remote side it's done.
        # Unlike New-PSSession, only our own event is forwarded so the remote side can't
        # raise other local events, like PowerShell.Exiting or the user's own engine
        # events. The C# equivalent is:
        #
        #     PSEventManager target = ...;
        #     Func<object, PSEventReceivedEventHandler> newForwardEventHandler =
        #         session => (sender, e) =>
        #         {
        #             if (e.SourceIdentifier == "PSSessionCallback.Invoke")
        #             {
        #                 target.GenerateEvent(
        #                     e.SourceIdentifier, session, e.SourceArgs, e.MessageData);
        #             }
        #         };
        $invokeEventName = 'PSSessionCallback.Invoke'
        $sessionParam = [System.Linq.Expressions.Expression]::Parameter([object], 'session')
        $senderParam = [System.Linq.Expressions.Expression]::Parameter([object], 'sender')
        $eParam = [System.Linq.Expressions.Expression]::Parameter([System.Management.Automation.PSEventArgs], 'e')
        $generateEvent = [System.Management.Automation.PSEventManager].GetMethod(
            'GenerateEvent',
            [type[]]@([string], [object], [object[]], [psobject]))
        $forwardEventHandler = [System.Linq.Expressions.Expression]::Lambda(
            [System.Management.Automation.PSEventReceivedEventHandler],
            [System.Linq.Expressions.Expression]::IfThen(
                [System.Linq.Expressions.Expression]::Equal(
                    [System.Linq.Expressions.Expression]::Property($eParam, 'SourceIdentifier'),
                    [System.Linq.Expressions.Expression]::Constant($invokeEventName)),
                [System.Linq.Expressions.Expression]::Call(
                    [System.Linq.Expressions.Expression]::Constant($Host.Runspace.Events),
                    $generateEvent,
                    [System.Linq.Expressions.Expression]::Property($eParam, 'SourceIdentifier'),
                    $sessionParam,
                    [System.Linq.Expressions.Expression]::Property($eParam, 'SourceArgs'),
                    [System.Linq.Expressions.Expression]::Property($eParam, 'MessageData'))),
            [System.Linq.Expressions.ParameterExpression[]]@($senderParam, $eParam))
        $newForwardEventHandler = [System.Linq.Expressions.Expression]::Lambda(
            [Func[object, System.Management.Automation.PSEventReceivedEventHandler]],
            $forwardEventHandler,
            [System.Linq.Expressions.ParameterExpression[]]@($sessionParam)).Compile()

        # Replace any subscriber from an earlier call rather than reusing it, so a
        # reloaded copy of this script takes effect without restarting the session. It
        # holds no state of its own, everything per session comes from the sender.
        foreach ($subscriber in $Host.Runspace.Events.GetEventSubscribers($invokeEventName)) {
            $Host.Runspace.Events.UnsubscribeEvent($subscriber)
        }

        $OnInvoke = {
            param ($Name, $Id, $Arguments, $NamedArguments)

            # The remote function is blocked until we tell it we're done, so the
            # console isn't reading input and Callback can use it freely.
            $output = [System.Collections.Generic.List[object]]::new()
            $errors = [System.Collections.Generic.List[string]]::new()
            $errorMessage = $null
            try {
                # The callback is bound to the caller's session state so it can't
                # see $Sender, give it the details it may need as a variable.
                $entry = $Sender.Callbacks[$Name]
                $context = [PSCustomObject]@{
                    PSTypeName     = 'PSSessionCallbackContext'
                    Name           = $Name
                    State          = $entry.State
                    ConnectionInfo = $Sender.ConnectionInfo
                }
                $namedArgs = if ($NamedArguments) { $NamedArguments } else { @{} }

                # The invoker runs in a new scope of the callback's session state with
                # the context defined, so the callback inherits it as a child scope.
                # The callback and its arguments are private, private variables aren't
                # visible to child scopes so they can't conflict with anything the
                # callback uses.
                $variables = [System.Collections.Generic.List[System.Management.Automation.PSVariable]]::new()
                $variables.Add([System.Management.Automation.PSVariable]::new('PSSessionCallbackContext', $context))
                $variables.Add([System.Management.Automation.PSVariable]::new('Callback', $entry.Callback, 'Private'))
                $variables.Add([System.Management.Automation.PSVariable]::new('NamedArguments', $namedArgs, 'Private'))
                $variables.Add([System.Management.Automation.PSVariable]::new('PositionalArguments', @($Arguments), 'Private'))

                # Collect non-terminating errors so they can be written remotely,
                # otherwise they only go to this event action and are easily missed.
                # Their position isn't reliable when raised in an event action, so
                # only the message is sent.
                & { $entry.Invoker.InvokeWithContext($null, $variables) } 2>&1 | ForEach-Object {
                    if ($_ -is [System.Management.Automation.ErrorRecord]) {
                        $errors.Add("$_")
                    } else {
                        $output.Add($_)
                    }
                }
            } catch {
                # InvokeWithContext wraps errors from the callback, unwrap it so the
                # message and position are the callback's own. Include where it failed
                # as the remote side only sees this text.
                $err = $_
                if ($err.Exception -is [System.Management.Automation.MethodInvocationException] -and
                    $err.Exception.InnerException -is [System.Management.Automation.IContainsErrorRecord]) {
                    $err = $err.Exception.InnerException.ErrorRecord
                }
                $errorMessage = "$err`n$($err.InvocationInfo.PositionMessage)"
            }

            # The remote function still holds the remote runspace, we use a nested
            # pipeline which is run in the while loop statements to trigger the loop
            # to exit and the remote function to continue.
            $complete = $Sender.Runspace.CreateNestedPipeline(
                'param ($Id, $Output, $Errors, $ErrorMessage) & (Get-Module PSSessionCallback) { $script:Completed = @{ Id = $args[0]; Output = $args[1]; Errors = $args[2]; ErrorMessage = $args[3] } } $Id $Output $Errors $ErrorMessage',
                $false)
            try {
                $complete.Commands[0].Parameters.Add('Id', $Id)
                $complete.Commands[0].Parameters.Add('Output', $output.ToArray())
                $complete.Commands[0].Parameters.Add('Errors', $errors.ToArray())
                $complete.Commands[0].Parameters.Add('ErrorMessage', $errorMessage)
                $null = $complete.Invoke()
            } finally {
                $complete.Dispose()
            }
        }

        # Subscribe to the event the remote functions raise to run their Callback
        # scriptblock here. Every session shares this subscriber, the forwarded
        # event's sender says which session it came from.
        $null = $Host.Runspace.Events.SubscribeEvent(
            $null,             # source
            $invokeEventName,  # eventName
            $invokeEventName,  # sourceIdentifier
            $null,             # data
            $OnInvoke,         # action
            $true,             # supportEvent
            $false)            # forwardEvent

        # Evaluated in the callback's session state to get an invoker bound to it, see
        # the process block.
        $invokerFactory = [ScriptBlock]::Create(
            '{ & $Callback @NamedArguments @PositionalArguments }')

        $localCallbacks = @{}
        $definitions = [System.Collections.Generic.List[hashtable]]::new()
    }
    process {
        foreach ($c in $Callback) {
            # PSTypeName only checks the type name, so check the properties in case the
            # definition wasn't made by New-PSSessionCallback.
            $invalid = @(
                foreach ($prop in 'Callback', 'Pre', 'Post') {
                    # Pre is optional, Callback's declaration is used without it.
                    if ($prop -eq 'Pre' -and $null -eq $c.Pre) {
                        continue
                    }
                    if ($c.$prop -isnot [scriptblock]) {
                        $prop
                    }
                }
            )
            if ($invalid) {
                $e = [System.Management.Automation.ErrorRecord]::new(
                    [ArgumentException]"The callback definition has invalid values for $($invalid -join ', '). Create it with New-PSSessionCallback.",
                    "InvalidCallback",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $c)
                $PSCmdlet.WriteError($e)
                continue
            }

            if ($localCallbacks.ContainsKey($c.Name)) {
                $e = [System.Management.Automation.ErrorRecord]::new(
                    [ArgumentException]"A callback named '$($c.Name)' was already provided, ignoring this one.",
                    "DuplicateCallbackName",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $c)
                $PSCmdlet.WriteError($e)
                continue
            }
            # A scriptblock runs in the session state it was created in, so the
            # callback can't see variables from this script's scopes. Evaluating the
            # unbound factory in the callback's session state, its module or otherwise
            # the caller's, gives an invoker bound to the same session state. Only the
            # scriptblock literal is evaluated, nothing is defined there.
            $sessionState = if ($c.Callback.Module) {
                $c.Callback.Module.SessionState
            } else {
                $PSCmdlet.SessionState
            }
            $localCallbacks[$c.Name] = @{
                Callback = $c.Callback
                State    = $c.State
                Invoker  = $ExecutionContext.InvokeCommand.InvokeScript(
                    $sessionState,
                    $invokerFactory)[0]
            }

            # The remote function takes Pre's parameters, or Callback's without a Pre.
            # Taking the text up to the end of the param block also keeps its
            # attributes, like [CmdletBinding()], and any comment-based help before it.
            # This allows us to define the wrapper function on the remote side with the
            # same declaration for tab completion, help, etc.
            # .Ast isn't used as its offsets are into the original script, and include
            # the braces for a literal, not into the ToString() text.
            $declarationText = if ($c.Pre) { $c.Pre.ToString() } else { $c.Callback.ToString() }
            $declarationAst = [System.Management.Automation.Language.Parser]::ParseInput($declarationText, [ref]$null, [ref]$null)
            $paramText = if ($declarationAst.ParamBlock) {
                $declarationText.Substring(0, $declarationAst.ParamBlock.Extent.EndOffset)
            }

            # Assigned through a variable as an if expression without output stored
            # directly in the hashtable serializes as an empty object, not $null.
            $preText = $null
            if ($c.Pre) {
                $preText = $c.Pre.ToString()
            }

            $definitions.Add(@{
                    Name       = $c.Name
                    ParamBlock = $paramText
                    Pre        = $preText
                    Post       = $c.Post.ToString()
                    State      = $c.State
                })
        }
    }
    end {
        $ErrorActionPreference = 'Stop'

        $setupScript = {
            param ($EventName, $Definitions)

            # Setup event forwarding so the callback functions can raise the event on
            # the client side.
            $null = $Host.Runspace.Events.SubscribeEvent(
                $null,       # source
                $EventName,  # eventName
                $EventName,  # sourceIdentifier
                $null,       # data
                $null,       # action
                $true,       # supportEvent
                $true)       # forwardEvent

            New-Module -Name PSSessionCallback -ScriptBlock {
                param ($EventName, $Definitions)

                $script:EventName = $EventName
                $script:Callbacks = @{}
                $script:Completed = $null

                function Invoke-PSSessionCallback {
                    param ($Name, $BoundParameters, $UnboundArguments)

                    # $args is an array when the function has one and null in an
                    # advanced function. Splatting null passes a null argument.
                    if ($null -eq $UnboundArguments) {
                        $UnboundArguments = @()
                    }

                    # Pre and Post are dot-sourced into the top scope of a new, empty
                    # module so Post can use variables Pre set. Being a separate session
                    # state, they can't see or clobber the variables here or in this
                    # module, and nothing carries over to the next call.
                    $callback = $script:Callbacks[$Name]
                    $scope = [PSModuleInfo]::new($true)
                    $scope.SessionState.PSVariable.Set(
                        'PSSessionCallbackContext',
                        [PSCustomObject]@{
                            PSTypeName = 'PSSessionCallbackContext'
                            Name       = $Name
                            State      = $callback.State
                        })
                    $localOutput = @(if ($callback.Pre) {
                            $localArgs = @(. $scope.NewBoundScriptBlock($callback.Pre) @BoundParameters @UnboundArguments)
                            Invoke-LocalCallback -Name $Name -Arguments $localArgs
                        } else {
                            # Without a Pre the function has Callback's parameters, so pass
                            # them by name. Switches are sent as a bool as a deserialized
                            # SwitchParameter is always truthy.
                            $named = @{}
                            foreach ($kvp in $BoundParameters.GetEnumerator()) {
                                $value = $kvp.Value
                                if ($value -is [switch]) {
                                    $value = $value.IsPresent
                                }
                                $named[$kvp.Key] = $value
                            }
                            Invoke-LocalCallback -Name $Name -Arguments $UnboundArguments -NamedArguments $named
                        })
                    . $scope.NewBoundScriptBlock($callback.Post) @localOutput
                }

                function Invoke-LocalCallback {
                    param ($Name, $Arguments, $NamedArguments)

                    # Raise the event which runs Callback on the client, then block
                    # until it's done so the repl does not prompt for further input
                    # while the client is still processing the callback.
                    $id = [Guid]::NewGuid().ToString()
                    $script:Completed = $null
                    $null = $Host.Runspace.Events.GenerateEvent(
                        $script:EventName,                          # sourceIdentifier
                        $null,                                      # sender
                        @($Name, $id, $Arguments, $NamedArguments), # args
                        $null)                                      # extraData

                    # The client stores the result in $script:Completed through a nested
                    # pipeline. That only runs between statements here, so poll rather
                    # than block on a wait handle. While only one callback can be
                    # waiting at a time, the id check means we ignore a late result from
                    # a previous callback that was stopped with Ctrl+C.
                    while ($script:Completed.Id -ne $id) {
                        Start-Sleep -Milliseconds 200
                    }
                    $result = $script:Completed
                    $script:Completed = $null

                    foreach ($e in $result.Errors) {
                        Write-Error -Message "Callback for '$Name' error: $e" -ErrorId CallbackError
                    }
                    if ($result.ErrorMessage) {
                        throw "Callback for '$Name' failed: $($result.ErrorMessage)"
                    }
                    $result.Output
                }

                # Define each callback as a function taking Pre's parameters that hands
                # them to Invoke-PSSessionCallback.
                foreach ($d in $Definitions) {
                    $pre = $null
                    if ($d.Pre) {
                        $pre = [ScriptBlock]::Create($d.Pre)
                    }
                    $script:Callbacks[$d.Name] = @{
                        Pre   = $pre
                        Post  = [ScriptBlock]::Create($d.Post)
                        State = $d.State
                    }

                    # We bind the function to this module so that it runs inside the
                    # module's scope and not the global one where it would be called. It
                    # looks up its own name so the name is never written into the script
                    # text.
                    $function = $ExecutionContext.SessionState.Module.NewBoundScriptBlock(
                        [ScriptBlock]::Create(@"
$($d.ParamBlock)
Invoke-PSSessionCallback -Name `$MyInvocation.MyCommand.Name -BoundParameters `$PSBoundParameters -UnboundArguments `$args
"@))
                    Set-Item -LiteralPath "function:$($d.Name)" -Value $function
                }

                Export-ModuleMember -Function @($Definitions | ForEach-Object Name)
            } -ArgumentList $EventName, $Definitions | Import-Module -Global
        }

        $connInfo = if ($ConnectionInfo) {
            $ConnectionInfo
        } elseif ($Transport -eq 'SSH') {
            # Parse [user@]host[:port] the same way Enter-PSSession -HostName does.
            $uri = $null
            if (-not [Uri]::TryCreate("ssh://$Target", [UriKind]::Absolute, [ref]$uri)) {
                $e = [System.Management.Automation.ErrorRecord]::new(
                    [ArgumentException]"'$Target' is not a valid SSH host, expecting [user@]host[:port].",
                    "InvalidSSHHost",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $Target)
                $PSCmdlet.ThrowTerminatingError($e)
            }

            $userName = if ($uri.UserInfo) { $uri.UserInfo }
            if ($uri.Port -eq -1) {
                [System.Management.Automation.Runspaces.SSHConnectionInfo]::new($userName, $uri.Host, $null)
            } else {
                [System.Management.Automation.Runspaces.SSHConnectionInfo]::new($userName, $uri.Host, $null, $uri.Port)
            }
        } elseif ($Transport -eq 'NamedPipe') {
            [System.Management.Automation.Runspaces.NamedPipeConnectionInfo]::new($Target)
        } elseif ($Transport -eq 'PwshProcess') {
            $processId = $Target -as [int]
            if ($null -eq $processId) {
                $e = [System.Management.Automation.ErrorRecord]::new(
                    [ArgumentException]"'$Target' is not a valid process id.",
                    "InvalidProcessId",
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $Target)
                $PSCmdlet.ThrowTerminatingError($e)
            }
            [System.Management.Automation.Runspaces.NamedPipeConnectionInfo]::new($processId)
        } else {
            [System.Management.Automation.Runspaces.WSManConnectionInfo]@{
                ComputerName = $Target
            }
        }

        $ps = $null
        # Use the default type table like Enter-PSSession so deserialized objects are
        # rehydrated the same way as a normal remote session.
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace(
            $connInfo,
            $Host,
            [System.Management.Automation.Runspaces.TypeTable]::LoadDefaultTypeFiles())
        try {
            # Forward events from the remote runspace to the local one like
            # New-PSSession does.
            $session = [PSCustomObject]@{
                Runspace       = $runspace
                ConnectionInfo = $connInfo
                Callbacks      = $localCallbacks
            }
            $runspace.Events.ReceivedEvents.add_PSEventReceived(
                $newForwardEventHandler.Invoke($session))
            $runspace.Open()

            $ps = [PowerShell]::Create()
            $ps.Runspace = $runspace
            # Run it in a child scope so its parameters don't become global variables in
            # the remote session.
            $null = $ps.AddScript($setupScript, $true)
            $null = $ps.AddArgument($invokeEventName)
            $null = $ps.AddArgument(@($definitions))

            try {
                $null = $ps.Invoke()
            } catch {
                # Unwrap the MethodInvocationException that .Invoke() adds and rethrow
                # the original inner exception if $setupScript threw an error.
                # Deviation from upstream: the original assigned the fallback inside the
                # if body, which yields no output and left $e null.
                $e = $_.Exception.InnerException.ErrorRecord
                if (-not $e) {
                    $e = $_
                }
                $e.ErrorDetails = "An error occurred while setting up the remote session: $e"
                $PSCmdlet.ThrowTerminatingError($e)
            }

            # Check if any non-terminating errors occurred during the setup script.
            if ($ps.HadErrors) {
                foreach ($e in $ps.Streams.Error) {
                    $e.ErrorDetails = "An error occurred while setting up the remote session: $e"
                    $PSCmdlet.WriteError($e)
                }

                return
            }

            # No public way to do this, it ensures the runspace is closed when someone
            # exits from the pushed runspace like how Enter-PSSession would. Without
            # this the session stays open. We can't use a finally block as the push is
            # not blocking and the script will continue out of the function like normal
            # with the pushed runspace.
            $closeOnPropPop = $runspace.GetType().GetProperty(
                'ShouldCloseOnPop',
                [System.Reflection.BindingFlags]'Instance, NonPublic')
            if (-not $closeOnPropPop) {
                throw "Failed to retrieve ShouldCloseOnPop property."
            }
            $closeOnPropPop.SetValue($runspace, $true)

            # This is what Enter-PSSession does, we push the remote runspace so the
            # current UI is inside the remote session. The function will continue
            # executing but the caller's host will be inside the remote session.
            $Host.PushRunspace($runspace)
        } catch {
            $runspace.Dispose()
            $PSCmdlet.ThrowTerminatingError($_)
        } finally {
            if ($ps) {
                $ps.Dispose()
            }
        }
    }
}
