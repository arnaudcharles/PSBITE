<#
.SYNOPSIS
Handles key press events for PSBITE editor command mode operations.

.DESCRIPTION
Processes keyboard input specifically for VIM-style command mode operations in the PSBITE text editor.
This function intercepts colon (':') commands in NORMAL mode and routes them to appropriate handlers
for file operations like save, quit, and save-and-quit operations.

.PARAMETER Key
The key press event object containing information about the pressed key, including character and virtual key code.

.PARAMETER Lines
Reference to the array containing all text lines in the current document. Passed by reference to allow modifications.

.PARAMETER CursorRow
Reference to the current cursor row position (zero-based index). Passed by reference to allow position updates.

.PARAMETER CursorCol
Reference to the current cursor column position (zero-based index). Passed by reference to allow position updates.

.PARAMETER Mode
Reference to the current editor mode string ('NORMAL' or 'INSERT'). Passed by reference to allow mode changes.

.PARAMETER FilePath
The full path to the file being edited. Used for save operations and display purposes.

.PARAMETER Saved
Reference to the boolean flag indicating whether the file has been saved since last modification.

.PARAMETER ScrollOffset
Reference to the current scroll offset for handling large files that exceed screen height.

.OUTPUTS
String
Returns "CONTINUE" to continue the editing session or "EXIT" to terminate the editor.

.EXAMPLE
$result = Invoke-PSBiteKeyPress -Key $keyEvent -Lines ([ref]$lines) -CursorRow ([ref]$row) -CursorCol ([ref]$col)
    -Mode ([ref]$mode) -FilePath "C:\script.ps1" -Saved ([ref]$saved) -ScrollOffset ([ref]$offset)

Processes a key press event and returns the next action to take.

.NOTES
This function specifically handles VIM command mode operations:
- :w  - Save file
- :q  - Quit (with unsaved changes warning)
- :q! - Force quit without saving
- :wq - Save and quit
- :x  - Save and quit (alternative)

Non-command key presses are forwarded to Invoke-PSBiteKeyNavigation for further processing.
#>
function Invoke-PSBiteKeyPress {
    [OutputType()]
    [CmdletBinding()]
    param($Key, [ref]$Lines, [ref]$CursorRow, [ref]$CursorCol, [ref]$Mode, $FilePath, [ref]$Saved, [ref]$ScrollOffset)

    # VIM commands
    if ($Key.Character -eq ':' -and $Mode.Value -eq "NORMAL") {
        $command = Read-PSBiteCommand
        switch ($command) {
            "w" {
                Save-PSBiteFile -Lines $Lines.Value -FilePath $FilePath
                $Saved.Value = $true
                return "CONTINUE"
            }
            "q" {
                if (-not $Saved.Value) {
                    Write-PSBiteMessage "⚠️  File not saved! Use :q! to force quit or :wq to save and quit" "Red"
                    return "CONTINUE"
                }
                return "EXIT"
            }
            "q!" { return "EXIT" }
            { $_ -eq "wq" -or $_ -eq "x" } {
                Save-PSBiteFile -Lines $Lines.Value -FilePath $FilePath
                $Saved.Value = $true
                return "EXIT"
            }
            default {
                Write-PSBiteMessage "⚠️  Unknown command: :$command" "Red"
            }
        }
        return "CONTINUE"
    }

    return Invoke-PSBiteKeyNavigation -Key $Key -Lines $Lines -CursorRow $CursorRow -CursorCol $CursorCol -Mode $Mode -Saved $Saved -ScrollOffset $ScrollOffset
}
