# ==============================================================================
# VHS Tape: Start-PSBite - Example 2
# Source: ExampleScript (Ex_Start-PSBite.ps1)
# Description: Edit a remote file with real-time synchronization
# ==============================================================================

# Output configuration
Output ../media/Start-PSBite-Examples/Start-PSBite-ex2.gif

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
Type 'Start-PSBite -FilePath "C:\scripts\remote.ps1" -ComputerName "server01"'
Sleep 500ms
Enter

# Display result
Sleep 3s
