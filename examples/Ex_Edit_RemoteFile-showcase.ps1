<#
  .SYNOPSIS
    This is a demonstration example of how to use the function Edit-RemoteFile.

  .NOTES
    Used by tools/Build-VhsMedia.ps1 -Showcase to record a real, working walkthrough.
    Requires a lab VM reachable at $vm with WinRM over HTTPS, and a credential cached with:
      Get-Credential -UserName 'cloudmgr' | Export-Clixml -Path "$env:TEMP\psbite-demo-cred.xml"
    Both are loaded here but never shown on screen, see the generator's hidden preamble.
#>

# Import the module
Import-Module -Name 'PSBITE'

$vm = '192.168.10.162'
$cred = Import-Clixml -Path "$env:TEMP\psbite-demo-cred.xml"
$remoteFile = 'C:\Users\cloudmgr\Documents\psbite-demo.ps1'

# Edit a remote PowerShell script with unidirectional sync
Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck

# Edit with bidirectional synchronization (remote changes are pulled to local)
Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck -Dual

# Edit with minimal output showing only essential messages
Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck -Silent

# Edit and delete temporary file when finished
Edit-RemoteFile -ComputerName $vm -RemotePath $remoteFile -Credential $cred -SkipCertificateCheck -DelTemp
