<#
  .SYNOPSIS
    This is a demonstration example of how to use the function Edit-RemoteFile.
#>

# Import the module
Import-Module -Name 'PSBITE'

# Edit a remote PowerShell script with SSL and unidirectional sync
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1"

# Edit with bidirectional synchronization (remote changes are pulled to local)
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Dual

# Edit with minimal output showing only essential messages
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Silent

# Edit and delete temporary file when finished
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -DelTemp

# Edit with verbose output showing file paths
Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1" -Verbose
