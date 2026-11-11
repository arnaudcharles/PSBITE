BeforeAll {
    # Import the function (adjust path as needed)
    # . "$PSScriptRoot\Start-PSBite.ps1"

    # Mock the helper functions
    function Start-LocalPSBite { param($FilePath, $AutoSave) }
    function Start-RemotePSBite { param($FilePath, $ComputerName, $UseSSL, $AutoSave) }
    function Start-PSBiteSession { param($ComputerName, $UseSSL, [PSCredential]$Credential, $SkipCertificateCheck) }
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

    Context 'Parameter Sets' {

        It 'Should default to the File parameter set' {
            (Get-Command Start-PSBite).DefaultParameterSet | Should -Be 'File'
        }

        It 'Should expose both the File and EnterSession parameter sets' {
            $sets = (Get-Command Start-PSBite).ParameterSets.Name
            $sets | Should -Contain 'File'
            $sets | Should -Contain 'EnterSession'
        }

        It 'Should have EnterSession with alias: es' {
            (Get-Command Start-PSBite).Parameters['EnterSession'].Aliases | Should -Contain 'es'
        }

        It 'Should require ComputerName when using EnterSession' {
            $param = (Get-Command Start-PSBite).ParameterSets |
                Where-Object Name -EQ 'EnterSession' |
                ForEach-Object { $_.Parameters } |
                Where-Object Name -EQ 'ComputerName'
            $param.IsMandatory | Should -Be $true
        }

        It 'Should not expose FilePath in the EnterSession parameter set' {
            $names = (Get-Command Start-PSBite).ParameterSets |
                Where-Object Name -EQ 'EnterSession' |
                ForEach-Object { $_.Parameters.Name }
            $names | Should -Not -Contain 'FilePath'
        }

        # Position 0 is FilePath when editing and ComputerName when entering a session. The two
        # must never collide: 'psbite some-file.txt' has to stay a local edit, never a connection
        # attempt to a host that happens to be named like the path.
        It 'Should take FilePath positionally in the File parameter set' {
            $param = (Get-Command Start-PSBite).ParameterSets |
                Where-Object Name -EQ 'File' |
                ForEach-Object { $_.Parameters } |
                Where-Object Name -EQ 'FilePath'
            $param.Position | Should -Be 0
        }

        It 'Should take ComputerName positionally in the EnterSession parameter set' {
            $param = (Get-Command Start-PSBite).ParameterSets |
                Where-Object Name -EQ 'EnterSession' |
                ForEach-Object { $_.Parameters } |
                Where-Object Name -EQ 'ComputerName'
            $param.Position | Should -Be 0
        }

        It 'Should not make ComputerName positional in the File parameter set' {
            $param = (Get-Command Start-PSBite).ParameterSets |
                Where-Object Name -EQ 'File' |
                ForEach-Object { $_.Parameters } |
                Where-Object Name -EQ 'ComputerName'
            $param.Position | Should -Be ([int]::MinValue)
        }
    }

    Context 'Session Mode Contract' {

        # Session mode re-invokes these commands locally with the connection options of the
        # session itself, so both have to accept them or the callback fails at runtime.
        It 'Should have <Command> accepting <Parameter>' -ForEach @(
            @{ Command = 'Start-PSBite'; Parameter = 'UseSSL' }
            @{ Command = 'Start-PSBite'; Parameter = 'Credential' }
            @{ Command = 'Start-PSBite'; Parameter = 'SkipCertificateCheck' }
            @{ Command = 'Edit-RemoteFile'; Parameter = 'UseSSL' }
            @{ Command = 'Edit-RemoteFile'; Parameter = 'Credential' }
            @{ Command = 'Edit-RemoteFile'; Parameter = 'SkipCertificateCheck' }
        ) {
            (Get-Command $Command).Parameters.Keys | Should -Contain $Parameter
        }

        It 'Should type Credential as PSCredential on <Command>' -ForEach @(
            @{ Command = 'Start-PSBite' }
            @{ Command = 'Edit-RemoteFile' }
        ) {
            (Get-Command $Command).Parameters['Credential'].ParameterType | Should -Be ([PSCredential])
        }
    }
}
