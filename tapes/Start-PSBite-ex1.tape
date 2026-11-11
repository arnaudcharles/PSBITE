# ==============================================================================
# VHS Tape: Start-PSBite - Example 1
# Source: ExampleScript (Ex_Start-PSBite.ps1)
# Description: Edit a local file
# ==============================================================================

# Output configuration
Output ../media/Start-PSBite-Examples/Start-PSBite-ex1.gif

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
Type 'Start-PSBite -FilePath "C:\test.txt"'
Sleep 500ms
Enter

# Display result
Sleep 3s
