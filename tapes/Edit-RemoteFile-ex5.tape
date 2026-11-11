# ==============================================================================
# VHS Tape: Edit-RemoteFile - Example 5
# Source: ExampleScript (Ex_Edit_RemoteFile.ps1)
# Description: Edit with verbose output showing file paths
# ==============================================================================

# Output configuration
Output ../media/Edit-RemoteFile-Examples/Edit-RemoteFile-ex5.gif

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
Type 'Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Verbose'
Sleep 500ms
Enter

# Display result
Sleep 3s
