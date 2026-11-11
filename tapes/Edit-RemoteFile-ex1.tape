# ==============================================================================
# VHS Tape: Edit-RemoteFile - Example 1
# Source: ExampleScript (Ex_Edit_RemoteFile.ps1)
# Description: Edit a remote PowerShell script with SSL and unidirectional sync
# ==============================================================================

# Output configuration
Output ../media/Edit-RemoteFile-Examples/Edit-RemoteFile-ex1.gif

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
Type 'Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1"'
Sleep 500ms
Enter

# Display result
Sleep 3s
