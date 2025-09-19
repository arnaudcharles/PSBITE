<#
  .SYNOPSIS
    This is a demonstration example of how to use the function Edit-RemoteFile.
#>

# Import the module
Import-Module -Name 'PSBITE'

# Edit a local file
Start-PSBite -FilePath "C:\test.txt"

# Edit a remote file with real-time synchronization
Start-PSBite -FilePath "C:\scripts\remote.ps1" -ComputerName "server01"
