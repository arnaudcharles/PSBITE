function Write-PSBiteEditor {
    <#
    .SYNOPSIS
        Render the PSBite text editor interface in the console.

    .DESCRIPTION
        Renders the PSBite text editor interface in the console, displaying the current file content, cursor position, and available commands.

    .PARAMETER Lines
        Specifies the lines of text to display in the editor.

    .PARAMETER CursorRow
        Specifies the current row of the cursor.

    .PARAMETER CursorCol
        Specifies the current column of the cursor.

    .PARAMETER Mode
        Specifies the current mode of the editor (e.g., NORMAL, INSERT).

    .PARAMETER FilePath
        Specifies the path to the file being edited.

    .PARAMETER Saved
        Indicates whether the current changes have been saved.

    .PARAMETER IsRemote
        Indicates whether the editor is running in a remote session.

    .PARAMETER ScrollOffset
        Specifies the current scroll offset for the editor view.

    .EXAMPLE
        Write-PSBiteEditor -Lines $lines -CursorRow $cursorRow -CursorCol $cursorCol -Mode $mode -FilePath $filePath -Saved $saved -IsRemote $false -ScrollOffset ([ref]$scrollOffset)

    .NOTES
        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [OutputType()]
    [CmdletBinding()]
    param($Lines, $CursorRow, $CursorCol, $Mode, $FilePath, $Saved, $IsRemote, [ref]$ScrollOffset)

    [Console]::Clear()

    # Calculate available lines for content
    $consoleHeight = $Host.UI.RawUI.WindowSize.Height
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $footerLines = 4  # Footer: separator + file info + position + commands
    $cursorLine = 1   # Reserve space for PowerShell cursor
    $maxContentLines = [Math]::Max(1, $consoleHeight - $footerLines - $cursorLine)

    # Adjust scroll if cursor is out of view
    if ($CursorRow -lt $ScrollOffset.Value) {
        $ScrollOffset.Value = $CursorRow
    } elseif ($CursorRow -ge ($ScrollOffset.Value + $maxContentLines)) {
        $ScrollOffset.Value = $CursorRow - $maxContentLines + 1
    }

    # File content from top of screen
    for ($i = 0; $i -lt $maxContentLines; $i++) {
        $lineIndex = $ScrollOffset.Value + $i

        if ($lineIndex -ge $Lines.Count) {
            # Empty lines beyond file content - but don't write if at bottom
            if ($i -lt ($maxContentLines - 1)) {
                Write-Host ""
            }
            continue
        }

        # Cursor indicator BEFORE line number
        if ($lineIndex -eq $CursorRow) {
            if ($Mode -eq "NORMAL") {
                Write-Host "►" -NoNewline -ForegroundColor Blue
            } else {
                Write-Host " " -NoNewline
            }
        } else {
            Write-Host " " -NoNewline
        }

        # Line number
        $lineNumber = "{0,3}: " -f ($lineIndex + 1)
        Write-Host $lineNumber -NoNewline -ForegroundColor DarkCyan

        # Line content
        if ($lineIndex -eq $CursorRow -and $Mode -eq "INSERT") {
            # INSERT mode - highlight character at cursor position
            $line = $Lines[$lineIndex].ToString()
            if ($CursorCol -lt $line.Length) {
                Write-Host $line.Substring(0, $CursorCol) -NoNewline
                Write-Host $line[$CursorCol] -NoNewline -BackgroundColor Yellow -ForegroundColor Black
                if ($CursorCol + 1 -lt $line.Length) {
                    if ($i -eq ($maxContentLines - 1)) {
                        Write-Host $line.Substring($CursorCol + 1) -NoNewline
                    } else {
                        Write-Host $line.Substring($CursorCol + 1)
                    }
                } else {
                    if ($i -ne ($maxContentLines - 1)) {
                        Write-Host ""
                    }
                }
            } else {
                Write-Host $line -NoNewline
                Write-Host " " -BackgroundColor Yellow -NoNewline
                if ($i -ne ($maxContentLines - 1)) {
                    Write-Host ""
                }
            }
        } else {
            $lineContent = $Lines[$lineIndex].ToString()
            if ($i -eq ($maxContentLines - 1)) {
                Write-Host $lineContent -NoNewline
            } else {
                Write-Host $lineContent
            }
        }
    }

    # FOOTER - Calculate position more carefully
    $footerStartLine = $maxContentLines
    [Console]::SetCursorPosition(0, $footerStartLine)
    Write-Host ("═" * $consoleWidth) -ForegroundColor DarkGray
    Write-Host ("📁 File: {0}" -f $FilePath) -ForegroundColor Gray
    Write-Host ("🎯 Position: Line {0}, Col {1} | Total Lines: {2}" -f ($CursorRow + 1), ($CursorCol + 1), $Lines.Count) -ForegroundColor DarkGray

    # Context commands with mode indicator
    $modeColor = if ($Mode -eq "INSERT") { [ConsoleColor]::Red } else { [ConsoleColor]::Green }
    $saveIndicator = if ($Saved) { "💾" } else { "⚠️" }
    $remoteIndicator = if ($IsRemote) { "🌐" } else { "💻" }

    if ($Mode -eq "NORMAL") {
        $commands = "[i] Insert | [:w] Save | [:q] Quit | [:q!] Force Quit | [:wq] Save&Quit"
        if ($IsRemote) { $commands += " | Remote: Auto-sync" }
        Write-Host "📋 NORMAL MODE ${saveIndicator} ${remoteIndicator}: $commands" -NoNewline -ForegroundColor $modeColor
    } else {
        Write-Host "📋 INSERT MODE ${saveIndicator} ${remoteIndicator}: [Esc] Normal Mode | [Enter] New Line | [Backspace] Delete" -NoNewline -ForegroundColor $modeColor
    }

    # Position cursor at the very end to control where PowerShell places it
    [Console]::SetCursorPosition(0, $footerStartLine + 3)
}
