BeforeAll {
    # Import the function (adjust path as needed)
    # . "$PSScriptRoot\Start-PSBite.ps1"

    # Mock the helper functions
    function Start-LocalPSBite { param($FilePath, $AutoSave) }
    function Start-RemotePSBite { param($FilePath, $ComputerName, $UseSSL, $AutoSave) }
}

Describe 'Start-PSBite' {

    Context 'Parameter Validation' {

        It 'Should have FilePath as a mandatory parameter' {
            (Get-Command Start-PSBite).Parameters['FilePath'].Attributes.Mandatory | Should -Be $true
        }

        It 'Should accept FilePath aliases: f, File' {
            $aliases = (Get-Command Start-PSBite).Parameters['FilePath'].Aliases
            $aliases | Should -Contain 'f'
            $aliases | Should -Contain 'File'
        }

        It 'Should have ComputerName with aliases: cn, Computer' {
            $aliases = (Get-Command Start-PSBite).Parameters['ComputerName'].Aliases
            $aliases | Should -Contain 'cn'
            $aliases | Should -Contain 'Computer'
        }

        # It 'Should have UseSSL defaulting to true' {
        #     (Get-Command Start-PSBite).Parameters['UseSSL'].Attributes.Where{ $_.TypeId.Name -eq 'DefaultParameterValueAttribute' } | Should -Not -BeNullOrEmpty
        # }

        It 'Should reject null or empty FilePath' {
            { Start-PSBite -FilePath "" } | Should -Throw
            { Start-PSBite -FilePath $null } | Should -Throw
        }
    }

#     Context 'Local Mode Execution' {
# 
#         BeforeEach {
#             Mock Start-LocalPSBite { }
#             Mock Start-RemotePSBite { }
#             Mock Write-Host { }
#             Mock Write-Error { }
#         }
# 
#         It 'Should call Start-LocalPSBite when no ComputerName is provided' {
#             Start-PSBite -FilePath "C:\test.txt"
# 
#             Should -Invoke Start-LocalPSBite -Times 1 -Exactly
#             Should -Invoke Start-RemotePSBite -Times 0
#         }
# 
#         It 'Should pass FilePath to Start-LocalPSBite' {
#             Start-PSBite -FilePath "C:\test.txt"
# 
#             Should -Invoke Start-LocalPSBite -ParameterFilter {
#                 $FilePath -eq "C:\test.txt"
#             }
#         }
# 
#         It 'Should pass AutoSave switch to Start-LocalPSBite when enabled' {
#             Start-PSBite -FilePath "C:\test.txt" -AutoSave
# 
#             Should -Invoke Start-LocalPSBite -ParameterFilter {
#                 $AutoSave -eq $true
#             }
#         }
# 
#         It 'Should display local mode header' {
#             Start-PSBite -FilePath "C:\test.txt"
# 
#             Should -Invoke Write-Host -ParameterFilter {
#                 $Object -match "Local Mode"
#             }
#         }
# 
#         It 'Should display AutoSave message when enabled' {
#             Start-PSBite -FilePath "C:\test.txt" -AutoSave
# 
#             Should -Invoke Write-Host -ParameterFilter {
#                 $Object -match "AutoSave"
#             }
#         }
#     }
# 
#     Context 'Remote Mode Execution' {
# 
#         BeforeEach {
#             Mock Start-LocalPSBite { }
#             Mock Start-RemotePSBite { }
#             Mock Write-Host { }
#             Mock Write-Error { }
#         }
# 
#         It 'Should call Start-RemotePSBite when ComputerName is provided' {
#             Start-PSBite -FilePath "C:\remote.txt" -ComputerName "server01"
# 
#             Should -Invoke Start-RemotePSBite -Times 1 -Exactly
#             Should -Invoke Start-LocalPSBite -Times 0
#         }
# 
#         It 'Should pass all parameters to Start-RemotePSBite' {
#             Start-PSBite -FilePath "C:\remote.txt" -ComputerName "server01" -UseSSL $false
# 
#             Should -Invoke Start-RemotePSBite -ParameterFilter {
#                 $FilePath -eq "C:\remote.txt" -and
#                 $ComputerName -eq "server01" -and
#                 $UseSSL -eq $false
#             }
#         }
# 
#         It 'Should display remote mode header' {
#             Start-PSBite -FilePath "C:\remote.txt" -ComputerName "server01"
# 
#             Should -Invoke Write-Host -ParameterFilter {
#                 $Object -match "Remote Mode"
#             }
#         }
# 
#         It 'Should reject relative paths in remote mode' {
#             Start-PSBite -FilePath "relative\path.txt" -ComputerName "server01"
# 
#             Should -Invoke Write-Error -ParameterFilter {
#                 $Message -match "absolute"
#             }
#             Should -Invoke Start-RemotePSBite -Times 0
#         }
# 
#         It 'Should accept absolute paths in remote mode' {
#             Start-PSBite -FilePath "C:\absolute\path.txt" -ComputerName "server01"
# 
#             Should -Invoke Start-RemotePSBite -Times 1
#             Should -Not -Invoke Write-Error
#         }
#     }
# 
#     Context 'Global Clipboard Initialization' {
# 
#         BeforeEach {
#             Mock Start-LocalPSBite { }
#             Mock Write-Host { }
# 
#             # Remove script-scoped variable if it exists
#             if (Get-Variable -Name PSBiteClipboard -Scope Script -ErrorAction SilentlyContinue) {
#                 Remove-Variable -Name PSBiteClipboard -Scope Script
#             }
#         }
# 
#         It 'Should initialize PSBiteClipboard if it does not exist' {
#             Start-PSBite -FilePath "C:\test.txt"
# 
#             Get-Variable -Name PSBiteClipboard -Scope Script -ErrorAction SilentlyContinue |
#                 Should -Not -BeNullOrEmpty
#         }
# 
#         It 'Should initialize PSBiteClipboard as empty string' {
#             Start-PSBite -FilePath "C:\test.txt"
# 
#             $script:PSBiteClipboard | Should -Be ""
#         }
# 
#         It 'Should not reinitialize PSBiteClipboard if it already exists' {
#             $script:PSBiteClipboard = "existing content"
# 
#             Start-PSBite -FilePath "C:\test.txt"
# 
#             $script:PSBiteClipboard | Should -Be "existing content"
#         }
#     }
# 
#     Context 'Alias Support' {
# 
#         It 'Should have psbite as an alias' {
#             $alias = Get-Alias -Name psbite -ErrorAction SilentlyContinue
#             $alias.ResolvedCommandName | Should -Be 'Start-PSBite'
#         }
#     }
# 
#     Context 'Edge Cases' {
# 
#         BeforeEach {
#             Mock Start-LocalPSBite { }
#             Mock Start-RemotePSBite { }
#             Mock Write-Host { }
#             Mock Write-Error { }
#         }
# 
#         It 'Should handle empty ComputerName as local mode' {
#             Start-PSBite -FilePath "C:\test.txt" -ComputerName ""
# 
#             Should -Invoke Start-LocalPSBite -Times 1
#         }
# 
#         It 'Should handle UNC paths in local mode' {
#             Start-PSBite -FilePath "\\server\share\file.txt"
# 
#             Should -Invoke Start-LocalPSBite -Times 1
#         }
# 
#         It 'Should handle paths with spaces' {
#             Start-PSBite -FilePath "C:\my folder\test file.txt"
# 
#             Should -Invoke Start-LocalPSBite -ParameterFilter {
#                 $FilePath -eq "C:\my folder\test file.txt"
#             }
#         }
#     }
}
