# ==============================================================================
# VHS Showcase: Start-PSBite - Full Walkthrough
# Source: Ex_Start-PSBite-showcase.ps1
# Total Steps: 5
# ==============================================================================

# Output configuration
Output ../media/Start-PSBite-Examples/Start-PSBite-showcase.gif

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
Type "Set-PSReadLineOption -HistorySaveStyle SaveNothing; function prompt { Write-Host -ForegroundColor Blue -NoNewline '❯ '; return ' ' }"
Enter
Sleep 300ms
Type "Get-ChildItem -Path ../src/functions -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }"
Enter
Sleep 500ms
Type "$vm = '192.168.10.162'"
Enter
Sleep 300ms
Type '$cred = Import-Clixml -Path "$env:TEMP\psbite-demo-cred.xml"'
Enter
Sleep 300ms
Type "Clear-Host"
Enter
Sleep 2s
Show

# ------------------------------------------------------------------------------
# Step 1: Edit a local file
# ------------------------------------------------------------------------------
Type "# Step 1: Edit a local file"
Enter
Sleep 200ms
Type 'Start-PSBite -FilePath "$env:TEMP\psbite-demo.txt"'
Sleep 500ms
Enter
Sleep 2s
Type "i"
Sleep 300ms
Type "This is a demo for step 1"
Sleep 600ms
Escape
Sleep 300ms
Type ":wq"
Sleep 200ms
Enter
Sleep 800ms
Type "Clear-Host"
Enter
Sleep 200ms
# ------------------------------------------------------------------------------
# Step 2: Edit a remote file with real-time synchronization
# ------------------------------------------------------------------------------
Type "# Step 2: Edit a remote file with real-time synchronization"
Enter
Sleep 200ms
Type 'Start-PSBite -FilePath "C:\Users\cloudmgr\Documents\psbite-demo.ps1" -ComputerName $vm -SkipCertificateCheck -Credential $cred'
Sleep 500ms
Enter
Sleep 2s
Type "i"
Sleep 300ms
Type "This is a demo on a remote file"
Sleep 600ms
Escape
Sleep 300ms
Type ":wq"
Sleep 200ms
Enter
Sleep 800ms
Type "Clear-Host"
Enter
Sleep 200ms
# ------------------------------------------------------------------------------
# Step 3: Enter an interactive session, PSBITE commands now run on this machine (-es is short for -EnterSession)
# ------------------------------------------------------------------------------
Type "# Step 3: Enter an interactive session, PSBITE commands now run on this machine (-es is short for -EnterSession)"
Enter
Sleep 200ms
Type "psbite -es $vm -SkipCertificateCheck -Credential $cred"
Sleep 500ms
Enter
Sleep 2s
Type "Clear-Host"
Enter
Sleep 200ms
# ------------------------------------------------------------------------------
# Step 4: From inside the session: psbite still opens here, against the remote path
# ------------------------------------------------------------------------------
Type "# Step 4: From inside the session: psbite still opens here, against the remote path"
Enter
Sleep 200ms
Type "psbite .\psbite-demo-session.txt"
Sleep 500ms
Enter
Sleep 2s
Type "i"
Sleep 300ms
Type "Editing file from the remote host"
Sleep 600ms
Escape
Sleep 300ms
Type ":wq"
Sleep 200ms
Enter
Sleep 800ms
Type "Clear-Host"
Enter
Sleep 200ms
# ------------------------------------------------------------------------------
# Step 5: Leave the remote session
# ------------------------------------------------------------------------------
Type "# Step 5: Leave the remote session"
Enter
Sleep 200ms
Type "exit"
Sleep 500ms
Enter
Sleep 2s
Type "Clear-Host"
Enter
Sleep 200ms

