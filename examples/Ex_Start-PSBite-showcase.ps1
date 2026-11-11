<#
  .SYNOPSIS
    This is a demonstration example of how to use the function Start-PSBite.

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

# Edit a local file @demo: This is a demo for step 1
Start-PSBite -FilePath "$env:TEMP\psbite-demo.txt"

# Edit a remote file with real-time synchronization @demo: This is a demo on a remote file
Start-PSBite -FilePath "C:\Users\cloudmgr\Documents\psbite-demo.ps1" -ComputerName $vm -SkipCertificateCheck -Credential $cred

# Enter an interactive session, PSBITE commands now run on this machine (-es is short for -EnterSession)
psbite -es $vm -SkipCertificateCheck -Credential $cred

# From inside the session: psbite still opens here, against the remote path @demo: Editing file from the remote host
psbite .\psbite-demo-session.txt

# Leave the remote session
exit
