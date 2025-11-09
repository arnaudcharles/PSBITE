function Invoke-PSBiteKeyNavigation {
    <#
    .SYNOPSIS
        Handle key presses for PSBite editor, including VIM-style commands.

    .DESCRIPTION
        Handles key press events for the PSBite editor, including VIM-style commands.

    .PARAMETER Key
        Specifies the key press event to process.

    .PARAMETER Lines
        Specifies the lines of text in the editor.

    .PARAMETER CursorRow
        Specifies the current row of the cursor.

    .PARAMETER CursorCol
        Specifies the current column of the cursor.

    .PARAMETER Mode
        Specifies the current mode of the editor (e.g., NORMAL, INSERT).

    .PARAMETER Saved
        Specifies whether the current document has unsaved changes.

    .PARAMETER ScrollOffset
        Specifies the current scroll offset for the editor view.

    .EXAMPLE
        Invoke-PSBiteKeyNavigation -Key $key -Lines ([ref]$lines) -CursorRow ([ref]$row) -CursorCol ([ref]$col)
        -Mode ([ref]$mode) -Saved ([ref]$saved) -ScrollOffset ([ref]$offset)

    .NOTES
        Author: Arnaud Charles
        GitHub: https://github.com/arnaudcharles
        LinkedIn: https://www.linkedin.com/in/arnaudcharles
    #>
    [OutputType()]
    [CmdletBinding()]
    param($Key, [ref]$Lines, [ref]$CursorRow, [ref]$CursorCol, [ref]$Mode, [ref]$Saved, [ref]$ScrollOffset)

    # Handle VIM-style commands in NORMAL mode
    if ($Mode.Value -eq "NORMAL") {
        switch ($Key.Character) {
            'i' {
                $Mode.Value = "INSERT"
                return "CONTINUE"
            }
            'y' {
                # Yank (copy) current line
                $script:PSBiteClipboard = $Lines.Value[$CursorRow.Value].ToString()
                Write-PSBiteMessage "📋 Line yanked (copied)" "Green"
                return "CONTINUE"
            }
            'p' {
                # Paste line after current line
                if ($script:PSBiteClipboard) {
                    $newLines = @()
                    for ($i = 0; $i -le $CursorRow.Value; $i++) {
                        $newLines += $Lines.Value[$i].ToString()
                    }
                    $newLines += $script:PSBiteClipboard
                    for ($i = ($CursorRow.Value + 1); $i -lt $Lines.Value.Count; $i++) {
                        $newLines += $Lines.Value[$i].ToString()
                    }
                    $Lines.Value = $newLines
                    $CursorRow.Value++
                    $CursorCol.Value = 0
                    $Saved.Value = $false
                    Write-PSBiteMessage "📋 Line pasted" "Green"
                }
                return "CONTINUE"
            }
            'd' {
                # Check for dd (delete line) - need to wait for second 'd'
                $nextKey = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                if ($nextKey.Character -eq 'd') {
                    # dd - delete current line
                    $script:PSBiteClipboard = $Lines.Value[$CursorRow.Value].ToString()

                    if ($Lines.Value.Count -gt 1) {
                        $newLines = @()
                        for ($i = 0; $i -lt $Lines.Value.Count; $i++) {
                            if ($i -ne $CursorRow.Value) {
                                $newLines += $Lines.Value[$i].ToString()
                            }
                        }
                        $Lines.Value = $newLines

                        # Adjust cursor position
                        if ($CursorRow.Value -ge $Lines.Value.Count) {
                            $CursorRow.Value = $Lines.Value.Count - 1
                        }
                        $maxCol = $Lines.Value[$CursorRow.Value].ToString().Length
                        if ($CursorCol.Value -gt $maxCol) {
                            $CursorCol.Value = $maxCol
                        }
                    } else {
                        # Last line - just clear it
                        $Lines.Value[0] = ""
                        $CursorCol.Value = 0
                    }

                    $Saved.Value = $false
                    Write-PSBiteMessage "✂️ Line cut" "Yellow"
                }
                return "CONTINUE"
            }
        }
    }

    switch ($Key.VirtualKeyCode) {
        27 { $Mode.Value = "NORMAL" }  # Escape

        # Navigation
        37 { if ($CursorCol.Value -gt 0) { $CursorCol.Value-- } }  # Left
        39 {
            $maxCol = $Lines.Value[$CursorRow.Value].ToString().Length
            if ($CursorCol.Value -lt $maxCol) { $CursorCol.Value++ }
        }  # Right
        38 {
            if ($CursorRow.Value -gt 0) {
                $CursorRow.Value--
                $maxCol = $Lines.Value[$CursorRow.Value].ToString().Length
                if ($CursorCol.Value -gt $maxCol) { $CursorCol.Value = $maxCol }
            }
        }  # Up
        40 {
            if ($CursorRow.Value -lt ($Lines.Value.Count - 1)) {
                $CursorRow.Value++
                $maxCol = $Lines.Value[$CursorRow.Value].ToString().Length
                if ($CursorCol.Value -gt $maxCol) { $CursorCol.Value = $maxCol }
            }
        }  # Down

        # Backspace
        8 {
            if ($Mode.Value -eq "INSERT") {
                if ($CursorCol.Value -gt 0) {
                    $line = $Lines.Value[$CursorRow.Value].ToString()
                    $Lines.Value[$CursorRow.Value] = $line.Substring(0, $CursorCol.Value - 1) + $line.Substring($CursorCol.Value)
                    $CursorCol.Value--
                    $Saved.Value = $false
                } elseif ($CursorRow.Value -gt 0) {
                    $currentLine = $Lines.Value[$CursorRow.Value].ToString()
                    $CursorCol.Value = $Lines.Value[$CursorRow.Value - 1].ToString().Length
                    $Lines.Value[$CursorRow.Value - 1] = $Lines.Value[$CursorRow.Value - 1].ToString() + $currentLine

                    $newLines = @()
                    for ($i = 0; $i -lt $Lines.Value.Count; $i++) {
                        if ($i -ne $CursorRow.Value) {
                            $newLines += $Lines.Value[$i].ToString()
                        }
                    }
                    $Lines.Value = $newLines
                    $CursorRow.Value--
                    $Saved.Value = $false
                }
            }
        }

        # Enter
        13 {
            if ($Mode.Value -eq "INSERT") {
                $currentLine = $Lines.Value[$CursorRow.Value].ToString()
                $Lines.Value[$CursorRow.Value] = $currentLine.Substring(0, $CursorCol.Value)

                $newLines = @()
                for ($i = 0; $i -le $CursorRow.Value; $i++) {
                    $newLines += $Lines.Value[$i].ToString()
                }
                $newLines += $currentLine.Substring($CursorCol.Value)
                for ($i = ($CursorRow.Value + 1); $i -lt $Lines.Value.Count; $i++) {
                    $newLines += $Lines.Value[$i].ToString()
                }

                $Lines.Value = $newLines
                $CursorRow.Value++
                $CursorCol.Value = 0
                $Saved.Value = $false
            }
        }

        # Normal characters
        default {
            if ($Mode.Value -eq "INSERT" -and $Key.Character -and [char]::IsControl($Key.Character) -eq $false) {
                $line = $Lines.Value[$CursorRow.Value].ToString()
                $Lines.Value[$CursorRow.Value] = $line.Substring(0, $CursorCol.Value) + $Key.Character + $line.Substring($CursorCol.Value)
                $CursorCol.Value++
                $Saved.Value = $false
            }
        }
    }

    return "CONTINUE"
}
