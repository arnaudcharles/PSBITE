function Start-LocalPSBite {
    <#
    .SYNOPSIS
        Starts a local instance of the PSBite editor.

    .DESCRIPTION
        Starts a local instance of the PSBite editor, allowing the user to edit files in a terminal-based interface.

    .PARAMETER FilePath
        Specifies the path to the file to edit.

    .EXAMPLE
        Start-LocalPSBite -FilePath "C:\path\to\file.txt"

    .NOTES
        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [OutputType()]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter()]
        [switch]$AutoSave,

        [Parameter(HelpMessage = "1-based line number to place the cursor on when the editor opens")]
        [int]$InitialLine = 1
    )

    # Resolve full path
    $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)

    # Check permissions first
    Write-Host "🔐 Checking permissions..." -ForegroundColor Yellow
    $permissionCheck = Test-PSBitePermission -FilePath $FilePath
    Write-Host $permissionCheck.Message -ForegroundColor $permissionCheck.Color

    if (-not $permissionCheck.CanWrite) {
        Write-Host "⚠️  Cannot proceed - insufficient permissions" -ForegroundColor Red
        return
    }

    # Initialisation
    $lines = @()
    $cursorRow = 0
    $cursorCol = 0
    $mode = "NORMAL"
    $saved = $true
    $scrollOffset = 0
    $lastSaveTime = Get-Date
    $autoSaveInterval = [TimeSpan]::FromMinutes(5)

    # Load or create file
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath
        if ($null -eq $content) {
            $lines = [string[]]@("")
        } elseif ($content -is [string]) {
            $lines = [string[]]@($content)
        } else {
            $lines = [string[]]$content
        }
    } else {
        $lines = [string[]]@(" ")
        $saved = $false
    }

    # Place the cursor on the requested line, clamped to the file's actual bounds
    $cursorRow = [Math]::Min([Math]::Max(0, $InitialLine - 1), $lines.Count - 1)

    try {
        while ($true) {
            Write-PSBiteEditor -Lines $lines -CursorRow $cursorRow -CursorCol $cursorCol -Mode $mode -FilePath $FilePath -Saved $saved -IsRemote $false -ScrollOffset ([ref]$scrollOffset)

            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            # AutoSave check
            if ($AutoSave -and ((Get-Date) - $lastSaveTime) -ge $autoSaveInterval) {
                if (-not $saved) {
                    Save-PSBiteFile -Lines $lines -FilePath $FilePath
                    $saved = $true
                    $lastSaveTime = Get-Date
                    Write-PSBiteMessage "💾 AutoSave: File saved (5 min elapsed)" "Green"
                    Start-Sleep -Milliseconds 1000
                } else {
                    $lastSaveTime = Get-Date
                }
            }

            $result = Invoke-PSBiteKeyPress -Key $key -Lines ([ref]$lines) -CursorRow ([ref]$cursorRow) -CursorCol ([ref]$cursorCol) -Mode ([ref]$mode) -FilePath $FilePath -Saved ([ref]$saved) -ScrollOffset ([ref]$scrollOffset)

            if ($result -eq "EXIT") {
                break
            }
        }
    } finally {
        [Console]::Clear()
    }
}
