# ==============================================================================
# VHS Tape: Start-PSBite - Example 3
# Source: ExampleScript (Ex_Start-PSBite.ps1)
# Description: [server01]: PS C:\> bite C:\logs\app.log    -> VSCode / Notepad on your desktop
# ==============================================================================

# Output configuration
Output ../media/Start-PSBite-Examples/Start-PSBite-ex3.gif

# Terminal settings
Set Shell "pwsh"
Set FontSize 14
Set Width 1200
Set Height 700
Set Padding 20
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms
Set Framerate 24

# Environment setup
# Path is relative to tapes/, where -Render invokes vhs from (see Push-Location below).
Hide
Type "Get-ChildItem -Path ../src/functions -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }; Clear-Host"
Enter
Sleep 1s
Show

# Command demonstration
Type 'Start-PSBite -ComputerName "server01" -EnterSession'
Sleep 500ms
Enter

# Display result
Sleep 3s
