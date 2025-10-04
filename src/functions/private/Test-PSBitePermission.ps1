<#
.SYNOPSIS
Test read/write permissions for PSBITE file editing (local or remote).

.DESCRIPTION
Tests if the current user has the necessary read/write permissions for the specified file, either locally or on a remote server via a PowerShell session.

.PARAMETER FilePath
Specifies the path to the file to test for read/write permissions.

.PARAMETER IsRemote
Indicates whether the file is located on a remote server.

.PARAMETER Session
Specifies the remote session to use if the file is on a remote server.
#>
function Test-PSBitePermission {
    [OutputType()]
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [switch]$IsRemote,
        $Session = $null
    )

    if ($IsRemote -and $Session) {
        # Test permissions on remote server
        return Invoke-Command -Session $Session -ScriptBlock {
            param($Path)

            try {
                # Test if we can write to the directory
                $directory = Split-Path $Path -Parent
                if (-not $directory) { $directory = "." }

                # Try to create a test file
                $testFile = Join-Path $directory "psbite_permission_test_$(Get-Random).tmp"
                "test" | Out-File -FilePath $testFile -Force -ErrorAction Stop
                Remove-Item $testFile -Force -ErrorAction SilentlyContinue

                return @{
                    CanWrite = $true
                    Message  = "✅ Write permissions OK"
                    Color    = "Green"
                }
            } catch {
                return @{
                    CanWrite = $false
                    Message  = "❌ No write permissions for this file"
                    Color    = "Red"
                }
            }
        } -ArgumentList $FilePath
    } else {
        # Test permissions locally
        try {
            $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
            $directory = Split-Path $fullPath -Parent
            if (-not $directory) { $directory = "." }

            # Ensure directory exists or can be created
            if (-not (Test-Path $directory)) {
                $null = New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop
            }

            # Try to create a test file
            $testFile = Join-Path $directory "psbite_permission_test_$(Get-Random).tmp"
            "test" | Out-File -FilePath $testFile -Force -ErrorAction Stop
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue

            return @{
                CanWrite = $true
                Message  = "✅ Write permissions OK"
                Color    = "Green"
            }
        } catch {
            return @{
                CanWrite = $false
                Message  = "❌ No write permissions for this file"
                Color    = "Red"
            }
        }
    }
}
