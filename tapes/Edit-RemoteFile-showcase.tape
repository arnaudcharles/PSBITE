# ==============================================================================
# VHS Showcase: Edit-RemoteFile - Full Walkthrough
# Source: Ex_Edit_RemoteFile-showcase.ps1
# Total Steps: 4
# ==============================================================================

# Output configuration
Output ../media/Edit-RemoteFile-Examples/Edit-RemoteFile-showcase.gif

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
Type "$remoteFile = 'C:\Users\cloudmgr\Documents\psbite-demo.ps1'"
Enter
Sleep 300ms
Type "Clear-Host"
Enter
Sleep 2s
Show

# ------------------------------------------------------------------------------
# Step 1: Edit a remote PowerShell script with unidirectional sync
# ------------------------------------------------------------------------------
Type "# Step 1: Edit a remote PowerShell script with unidirectional sync"
Enter
Sleep 200ms
Type "Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck"
Sleep 500ms
Enter
Sleep 2s
Ctrl+E
Sleep 1s
Type "Clear-Host"
Enter
Sleep 200ms
# ------------------------------------------------------------------------------
# Step 2: Edit with bidirectional synchronization (remote changes are pulled to local)
# ------------------------------------------------------------------------------
Type "# Step 2: Edit with bidirectional synchronization (remote changes are pulled to local)"
Enter
Sleep 200ms
Type "Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck -Dual"
Sleep 500ms
Enter
Sleep 2s
Ctrl+E
Sleep 1s
Type "Clear-Host"
Enter
Sleep 200ms
# ------------------------------------------------------------------------------
# Step 3: Edit with minimal output showing only essential messages
# ------------------------------------------------------------------------------
Type "# Step 3: Edit with minimal output showing only essential messages"
Enter
Sleep 200ms
Type "Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck -Silent"
Sleep 500ms
Enter
Sleep 2s
Ctrl+E
Sleep 1s
Type "Clear-Host"
Enter
Sleep 200ms
# ------------------------------------------------------------------------------
# Step 4: Edit and delete temporary file when finished
# ------------------------------------------------------------------------------
Type "# Step 4: Edit and delete temporary file when finished"
Enter
Sleep 200ms
Type "Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck -DelTemp"
Sleep 500ms
Enter
Sleep 2s
Ctrl+E
Sleep 1s
Type "Clear-Host"
Enter
Sleep 200ms

