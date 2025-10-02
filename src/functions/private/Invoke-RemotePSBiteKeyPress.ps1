<#
.SYNOPSIS
Handles key press events for PSBite remote editor with automatic synchronization.

.DESCRIPTION
Processes keyboard input for the PSBite remote editor, managing VIM-style commands
and file synchronization between local temporary files and remote destinations.
Supports standard VIM commands (:w, :q, :wq, :x, :q!) with remote sync capabilities.

.PARAMETER Key
The key press event object containing character and key information.

.PARAMETER Lines
Reference to the array containing all file lines. Modified by reference.

.PARAMETER CursorRow
Reference to the current cursor row position (0-based). Modified by reference.

.PARAMETER CursorCol
Reference to the current cursor column position (0-based). Modified by reference.

.PARAMETER Mode
Reference to the current editor mode ("NORMAL" or "INSERT"). Modified by reference.

.PARAMETER LocalPath
Path to the local temporary file used for editing.

.PARAMETER RemotePath
Path to the target file on the remote computer.

.PARAMETER Session
Active PowerShell session for remote communication.

.PARAMETER ComputerName
Name of the remote computer for display purposes.

.PARAMETER Saved
Reference to the save state flag. Modified by reference.

.PARAMETER ScrollOffset
Reference to the current scroll offset for display. Modified by reference.

.EXAMPLE
$result = Invoke-RemotePSBiteKeyPress -Key $keyPress -Lines ([ref]$fileLines) -CursorRow ([ref]$row) -CursorCol ([ref]$col)
    -Mode ([ref]$editorMode)-LocalPath "C:\temp\file.ps1" -RemotePath "C:\Scripts\file.ps1" -Session $psSession
    -ComputerName "Server01" -Saved ([ref]$isSaved) -ScrollOffset ([ref]$offset)

Processes a key press event in remote editing mode, handling navigation and commands.

.EXAMPLE
# Command execution example
# User presses ':' then 'w' then Enter
# Function saves locally then syncs to remote server
Invoke-RemotePSBiteKeyPress -Key $colonKey -Lines ([ref]$lines) -CursorRow ([ref]$row) -CursorCol ([ref]$col)
    -Mode ([ref]$mode) -LocalPath $local -RemotePath $remote -Session $session
    -ComputerName "Server01" -Saved ([ref]$saved) -ScrollOffset ([ref]$scroll)
#>
function Invoke-RemotePSBiteKeyPress {
    [OutputType()]
    [CmdletBinding()]
    param($Key, [ref]$Lines, [ref]$CursorRow, [ref]$CursorCol, [ref]$Mode, $LocalPath, $RemotePath, $Session, $ComputerName, [ref]$Saved, [ref]$ScrollOffset)

    # VIM commands with remote sync
    if ($Key.Character -eq ':' -and $Mode.Value -eq "NORMAL") {
        $command = Read-PSBiteCommand
        switch ($command) {
            "w" {
                # Save locally then sync to remote
                Save-PSBiteFile -Lines $Lines.Value -FilePath $LocalPath
                try {
                    Copy-Item -Path $LocalPath -Destination $RemotePath -ToSession $Session -Force
                    Write-PSBiteMessage "💾 Saved and synced to $ComputerName" "Green"
                    $Saved.Value = $true
                } catch {
                    Write-PSBiteMessage "❌ Save failed: $_" "Red"
                }
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
                Save-PSBiteFile -Lines $Lines.Value -FilePath $LocalPath
                try {
                    Copy-Item -Path $LocalPath -Destination $RemotePath -ToSession $Session -Force
                    Write-PSBiteMessage "💾 Saved and synced to $ComputerName" "Green"
                    $Saved.Value = $true
                    return "EXIT"
                } catch {
                    Write-PSBiteMessage "❌ Save failed: $_" "Red"
                    return "CONTINUE"
                }
            }
            default {
                Write-PSBiteMessage "⚠️  Unknown command: :$command" "Red"
            }
        }
        return "CONTINUE"
    }

    return Invoke-PSBiteKeyNavigation -Key $Key -Lines $Lines -CursorRow $CursorRow -CursorCol $CursorCol -Mode $Mode -Saved $Saved -ScrollOffset $ScrollOffset
}
