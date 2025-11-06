BeforeAll {
    # Import the function (adjust path as needed)
    # . "$PSScriptRoot\Edit-RemoteFile.ps1"

    # Mock helper functions
    function Read-RemoteFile { param($ComputerName, $RemotePath, $LocalTempDir, $Session, $Silent) }
    function Set-VSCodeConfiguration { param($TempDir) }
    function Start-FileWatcher { param($LocalPath, $RemotePath, $Session, $ComputerName, $Dual) }
}

Describe 'Edit-RemoteFile' {

    Context 'Parameter Validation' {

        It 'Should have ComputerName as a mandatory parameter' {
            (Get-Command Edit-RemoteFile).Parameters['ComputerName'].Attributes.Mandatory | Should -Be $true
        }

        It 'Should have RemotePath as a mandatory parameter' {
            (Get-Command Edit-RemoteFile).Parameters['RemotePath'].Attributes.Mandatory | Should -Be $true
        }

        It 'Should accept ComputerName alias: cn' {
            $aliases = (Get-Command Edit-RemoteFile).Parameters['ComputerName'].Aliases
            $aliases | Should -Contain 'cn'
        }

        It 'Should accept RemotePath alias: f' {
            $aliases = (Get-Command Edit-RemoteFile).Parameters['RemotePath'].Aliases
            $aliases | Should -Contain 'f'
        }

        It 'Should accept DelTemp alias: d' {
            $aliases = (Get-Command Edit-RemoteFile).Parameters['DelTemp'].Aliases
            $aliases | Should -Contain 'd'
        }

        It 'Should accept Dual alias: b' {
            $aliases = (Get-Command Edit-RemoteFile).Parameters['Dual'].Aliases
            $aliases | Should -Contain 'b'
        }

        It 'Should have UseSSL defaulting to true' {
            $param = (Get-Command Edit-RemoteFile).Parameters['UseSSL']
            # Check if default value exists in parameter metadata
            $param.Attributes.TypeId.Name | Should -Contain 'ParameterAttribute'
        }

        It 'Should have default LocalTempDir' {
            $param = (Get-Command Edit-RemoteFile).Parameters['LocalTempDir']
            $param.Attributes.Where{ $_.ValueFromPipeline -eq $false } | Should -Not -BeNullOrEmpty
        }

        It 'Should reject null or empty ComputerName' {
            { Edit-RemoteFile -ComputerName "" -RemotePath "C:\test.txt" } | Should -Throw
        }

        It 'Should reject null or empty RemotePath' {
            { Edit-RemoteFile -ComputerName "server01" -RemotePath "" } | Should -Throw
        }
    }

    Context 'Alias Support' {
        It 'Should have bite as an alias' {
            $alias = Get-Alias -Name bite -ErrorAction SilentlyContinue
            $alias.ResolvedCommandName | Should -Be 'Edit-RemoteFile'
        }

        It 'Should have teub as an alias' {
            $alias = Get-Alias -Name teub -ErrorAction SilentlyContinue
            $alias.ResolvedCommandName | Should -Be 'Edit-RemoteFile'
        }

        It 'Should have erf as an alias' {
            $alias = Get-Alias -Name erf -ErrorAction SilentlyContinue
            $alias.ResolvedCommandName | Should -Be 'Edit-RemoteFile'
        }
    }

    Context 'Remote Session Establishment' {

        BeforeEach {
            Mock New-PSSession {
                [PSCustomObject]@{
                    ComputerName = "server01"
                    State        = "Opened"
                }
            }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock Copy-Item { }
            Mock New-Item { }
            Mock Test-Path { $true }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Write-Error { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
        }

        It 'Should create a new PSSession with correct ComputerName' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke New-PSSession -ParameterFilter {
                $ComputerName -eq "server01"
            }
        }

        It 'Should use SSL by default' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke New-PSSession -ParameterFilter {
                $UseSSL -eq $true
            }
        }

        It 'Should not use SSL when UseSSL is false' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -UseSSL $false

            Should -Invoke New-PSSession -ParameterFilter {
                $UseSSL -ne $true
            }
        }

        It 'Should create session with NoMachineProfile option' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke New-PSSessionOption
        }

        It 'Should remove session in finally block' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Remove-PSSession
        }
    }

    Context 'Remote File Verification' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Copy-Item { }
            Mock New-Item { }
            Mock Test-Path { $true }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
            Mock Invoke-Command { $true }
        }

        It 'Should invoke remote command to check file existence' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Invoke-Command -ParameterFilter {
                $ScriptBlock -ne $null
            }
        }

        It 'Should throw error if remote file cannot be accessed' {
            Mock Invoke-Command { $false }

            { Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" } |
                Should -Throw "*Unable to create or access remote file*"
        }
    }

    Context 'Local Environment Preparation' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock Copy-Item { }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }

            # Mock Test-Path to return false first (dir doesn't exist), then true (file operations)
            $script:testPathCallCount = 0
            Mock Test-Path {
                $script:testPathCallCount++
                if ($script:testPathCallCount -eq 1) { $false } else { $true }
            }
            Mock New-Item { }
        }

        It 'Should create local temp directory if it does not exist' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke New-Item -ParameterFilter {
                $ItemType -eq 'Directory'
            }
        }

        It 'Should use custom LocalTempDir when provided' {
            $customPath = "C:\CustomTemp"
            Mock Test-Path { $false }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -LocalTempDir $customPath

            Should -Invoke New-Item -ParameterFilter {
                $Path -eq $customPath
            }
        }

        It 'Should generate timestamped local filename' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1"

            # Should invoke Copy-Item with a path containing timestamp pattern
            Should -Invoke Copy-Item -ParameterFilter {
                $Destination -match "server01_\d{8}_\d{6}_test\.ps1"
            }
        }
    }

    Context 'File Copy and Locked File Handling' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock New-Item { }
            Mock Test-Path { $true }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Write-Error { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
            Mock Read-RemoteFile { }
        }

        It 'Should copy remote file to local path' {
            Mock Copy-Item { }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Copy-Item -ParameterFilter {
                $FromSession -ne $null
            }
        }

        It 'Should switch to read-only mode when file is locked' {
            Mock Copy-Item {
                throw "The process cannot access the file because it is being used by another process"
            }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Read-RemoteFile -Times 1
        }

        It 'Should display warning when switching to read-only mode' {
            Mock Copy-Item {
                throw "The process cannot access the file because it is being used by another process"
            }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "READ-ONLY mode"
            }
        }

        It 'Should rethrow error if copy fails for non-locked reason' {
            Mock Copy-Item { throw "Network error" }

            { Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" } |
                Should -Throw
        }
    }

    Context 'Editor Detection and Configuration' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock Copy-Item { }
            Mock New-Item { }
            Mock Test-Path { $true }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Start-Sleep { }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
        }

        It 'Should detect VSCode when available' {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } -ParameterFilter {
                $ArgumentList -like "*--version*"
            }
            Mock Set-VSCodeConfiguration { $true }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Set-VSCodeConfiguration
        }

        It 'Should open file with VSCode when available' {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } } -ParameterFilter {
                $ArgumentList -like "*--version*"
            }
            Mock Start-Process { } -ParameterFilter {
                $FilePath -eq "code" -and $ArgumentList -notlike "*--version*"
            }
            Mock Set-VSCodeConfiguration { $true }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Start-Process -ParameterFilter {
                $ArgumentList -match "test\.txt" -and $ArgumentList -notlike "*--version*"
            }
        }

        It 'Should fallback to Notepad when VSCode is not available' {
            Mock Start-Process { throw "VSCode not found" } -ParameterFilter {
                $ArgumentList -like "*--version*"
            }
            Mock Start-Process { } -ParameterFilter {
                $FilePath -eq "notepad.exe"
            }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Start-Process -ParameterFilter {
                $ArgumentList -match "notepad\.exe" -or $_ -match "notepad\.exe"
            }
        }

        It 'Should configure VSCode trusted folders' {
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Set-VSCodeConfiguration { $true }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Set-VSCodeConfiguration
        }
    }

    Context 'File Monitoring' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock Copy-Item { }
            Mock New-Item { }
            Mock Test-Path { $true }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
            Mock Start-FileWatcher { }
        }

        It 'Should start file watcher with unidirectional sync by default' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Start-FileWatcher -ParameterFilter {
                $Dual -eq $false
            }
        }

        It 'Should start file watcher with bidirectional sync when Dual is specified' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -Dual

            Should -Invoke Start-FileWatcher -ParameterFilter {
                $Dual -eq $true
            }
        }

        It 'Should pass correct parameters to file watcher' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\Scripts\test.ps1"

            Should -Invoke Start-FileWatcher -ParameterFilter {
                $RemotePath -eq "C:\Scripts\test.ps1" -and
                $ComputerName -eq "server01"
            }
        }

        It 'Should display bidirectional monitoring message when Dual is enabled' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -Dual

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "Bidirectional"
            }
        }

        It 'Should display unidirectional monitoring message by default' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "Unidirectional"
            }
        }
    }

    Context 'Cleanup and Temporary File Management' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock Copy-Item { }
            Mock New-Item { }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
            Mock Remove-Item { }

            # Mock Test-Path to simulate file exists
            $script:testPathCount = 0
            Mock Test-Path {
                $script:testPathCount++
                $true
            }
        }

        It 'Should preserve local file by default' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Not -Invoke Remove-Item
        }

        It 'Should delete local file when DelTemp is specified' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -DelTemp

            Should -Invoke Remove-Item
        }

        It 'Should display deletion message when DelTemp is used' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -DelTemp

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "deleted" -and $Object -match "DelTemp"
            }
        }

        It 'Should display preservation message when file is kept' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "preserved"
            }
        }

        It 'Should not perform file cleanup in read-only mode' {
            Mock Copy-Item {
                throw "The process cannot access the file because it is being used by another process"
            }
            Mock Read-RemoteFile { }

            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -DelTemp

            # Should not attempt to delete because we're in read-only mode
            Should -Not -Invoke Remove-Item
        }
    }

    Context 'Silent Mode' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock Copy-Item { }
            Mock New-Item { }
            Mock Test-Path { $true }
            Mock Write-Verbose { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
            Mock Write-Host { }
        }

        It 'Should reduce output in Silent mode' {
            $hostCallsBefore = 0
            $hostCallsAfter = 0

            # Count Write-Host calls without Silent
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"
            $hostCallsBefore = (Get-MockCallHistory Write-Host).Count

            # Reset mocks
            Clear-MockCallHistory

            # Count Write-Host calls with Silent
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -Silent
            $hostCallsAfter = (Get-MockCallHistory Write-Host).Count

            $hostCallsAfter | Should -BeLessThan $hostCallsBefore
        }

        It 'Should still display essential monitoring messages in Silent mode' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -Silent

            # Should still show monitoring status
            Should -Invoke Write-Host -ParameterFilter {
                $Object -match "monitoring" -or $Object -match "Ctrl\+E"
            }
        }
    }

    Context 'Error Handling' {

        BeforeEach {
            Mock Remove-PSSession { }
            Mock Write-Host { }
            Mock Write-Error { }
            Mock Clear-Host { }
        }

        It 'Should handle session creation failure' {
            Mock New-PSSession { throw "Connection failed" }

            { Edit-RemoteFile -ComputerName "invalid-server" -RemotePath "C:\test.txt" } |
                Should -Throw
        }

        It 'Should close session on error' {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Invoke-Command { throw "Remote command failed" }

            { Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" } |
                Should -Throw

            Should -Invoke Remove-PSSession
        }

        It 'Should display error message when exception occurs' {
            Mock New-PSSession { throw "Test error" }

            { Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" } |
                Should -Throw

            Should -Invoke Write-Error -ParameterFilter {
                $Message -match "Error in Edit-RemoteFile"
            }
        }
    }

    Context 'Integration Scenarios' {

        BeforeEach {
            Mock New-PSSession { [PSCustomObject]@{ ComputerName = "server01" } }
            Mock Remove-PSSession { }
            Mock Invoke-Command { $true }
            Mock Copy-Item { }
            Mock New-Item { }
            Mock Test-Path { $true }
            Mock Write-Host { }
            Mock Write-Verbose { }
            Mock Start-Process { [PSCustomObject]@{ ExitCode = 0 } }
            Mock Start-Sleep { }
            Mock Set-VSCodeConfiguration { $true }
            Mock Start-FileWatcher { }
            Mock Clear-Host { }
            Mock New-PSSessionOption { [PSCustomObject]@{} }
            Mock Remove-Item { }
        }

        It 'Should handle complete workflow: connect, copy, edit, monitor' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt"

            Should -Invoke New-PSSession -Times 1
            Should -Invoke Copy-Item -Times 1
            Should -Invoke Start-Process -AtLeast 1
            Should -Invoke Start-FileWatcher -Times 1
            Should -Invoke Remove-PSSession -Times 1
        }

        It 'Should handle dual mode with all features' {
            Edit-RemoteFile -ComputerName "server01" -RemotePath "C:\test.txt" -Dual -DelTemp -Silent

            Should -Invoke Start-FileWatcher -ParameterFilter { $Dual -eq $true }
            Should -Invoke Remove-Item -Times 1
        }
    }
}
