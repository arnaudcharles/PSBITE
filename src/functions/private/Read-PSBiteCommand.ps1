<#
.SYNOPSIS
Reads a VIM-style command from user input in the PSBite editor.

.DESCRIPTION
Displays a command prompt (":") at the bottom of the console and reads user input
character by character to build a VIM-style command. Supports common input operations
like backspace for correction and escape to cancel. Used for PSBite editor commands
such as :w (save), :q (quit), :wq (save and quit), etc.

.PARAMETER None
This function takes no parameters.

.EXAMPLE
$command = Read-PSBiteCommand
# User types ":w" and presses Enter
# Returns "w"

Reads a save command from the user.

.EXAMPLE
$command = Read-PSBiteCommand
# User types ":wq" and presses Enter
# Returns "wq"

Reads a save-and-quit command from the user.

.EXAMPLE
$command = Read-PSBiteCommand
# User presses Escape
# Returns ""

Returns empty string when user cancels with Escape.
#>
function Read-PSBiteCommand {
    [OutputType()]
    [CmdletBinding()]
    param()

    $consoleHeight = $Host.UI.RawUI.WindowSize.Height
    [Console]::SetCursorPosition(0, $consoleHeight - 1)
    Write-Host ":" -NoNewline -ForegroundColor Yellow
    $command = ""

    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        if ($key.VirtualKeyCode -eq 13) { break }
        elseif ($key.VirtualKeyCode -eq 27) { return "" }
        elseif ($key.VirtualKeyCode -eq 8) {
            if ($command.Length -gt 0) {
                $command = $command.Substring(0, $command.Length - 1)
                Write-Host "`b `b" -NoNewline
            }
        } elseif ($key.Character -and [char]::IsControl($key.Character) -eq $false) {
            $command += $key.Character
            Write-Host $key.Character -NoNewline -ForegroundColor Yellow
        }
    }

    return $command
}
