<#
  .SYNOPSIS
    This is a demonstration example of how to use the function Start-PSBite.
#>

# Import the module
Import-Module -Name 'PSBITE'

# Edit a local file
Start-PSBite -FilePath "C:\test.txt"

# Edit a remote file with real-time synchronization
Start-PSBite -FilePath "C:\scripts\remote.ps1" -ComputerName "server01"

# Enter a remote session, then edit from the remote prompt while the editor runs locally:
#   [server01]: PS C:\> psbite .\test.txt       -> PSBITE editor in your terminal
#   [server01]: PS C:\> bite C:\logs\app.log    -> VSCode / Notepad on your desktop
Start-PSBite -ComputerName "server01" -EnterSession

# Same thing, short form: ComputerName is positional when entering a session
psbite -es "server01"
