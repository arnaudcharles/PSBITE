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

        It 'Should reject null or empty FilePath' {
            { Start-PSBite -FilePath "" } | Should -Throw
            { Start-PSBite -FilePath $null } | Should -Throw
        }
    }
}
