BeforeAll {
    . $PSScriptRoot\..\Public\Publish-GuestConfigurationPackage.ps1
}

Describe 'invoking Publish-GuestConfigurationPackage with minimal parameters' {
    Context 'testing parameter validation' {
        It 'should throw an error if the input provided for $Configuration is not a valid path' {
            { Publish-GuestConfigurationPackage -Configuration .\absentfile.ps1 } | Should -Throw "Cannot validate argument on parameter 'Configuration'. The `" Test-Path -Path `$_ -PathType Leaf `" validation script for the argument with value `".\absentfile.ps1`" did not return a result of True.*"
        }
    }
    Context 'testing cmdlet invocation' {
        BeforeEach {
            $sampleConfiguration = Get-Content -Path "$PSScriptRoot\SampleConfigs\SimpleDscConfiguration.ps1" -ErrorAction Stop
            Mock Get-Item { return @{FullName = "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" } }
            Mock Get-Content { return $sampleConfiguration }
            Mock Join-Path { return "$pwd\SimpleDscConfiguration\SimpleDscConfiguration.mof" }
            Mock Rename-Item {}
            Mock New-GuestConfigurationPackage { return @{Path = "$pwd\SimpleDscConfiguration.zip" } }
            Mock Test-Path { return $true }
            Mock Remove-Item {}
            Mock Get-FileHash { return 'EFE785C0BFD22E7A44285BB1D9725C3AE06B9110CCA40D568BAFA9B5D824506B' }
            Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1"
        }
        It 'should call Get-Item with the path to the configuration file' {
            Should -CommandName Get-Item -ParameterFilter { $Path -like '*\Tests\SampleConfigs\SimpleDscConfiguration.ps1' } -Exactly 1
        }

        It 'should call Get-Content with the path to the configuration file' {
            Should -CommandName Get-Content -Exactly 1 -ParameterFilter { $Path -like '*\Tests\SampleConfigs\SimpleDscConfiguration.ps1' }
        }

        It 'should call Join-Path with the path to predict the path of the final MOF file' {
            Should -CommandName Join-Path -Exactly 1 -ParameterFilter { $ChildPath -eq 'SimpleDscConfiguration' -and $AdditionalChildPath -eq 'SimpleDscConfiguration.mof' }
        }

        It 'should call Rename-Item to rename the MOF file' {
            Should -CommandName Rename-Item -Exactly 1 -ParameterFilter { $Path -eq "$pwd\SimpleDscConfiguration\localhost.mof" -and $NewName -eq 'SimpleDscConfiguration.mof' }
        }

        It 'should call New-GuestConfigurationPackage to create the package' {
            Should -CommandName New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Name -eq 'SimpleDscConfiguration' -and $Configuration -like '*\SimpleDscConfiguration\SimpleDscConfiguration.mof' }
        }

        It 'should call Remove-Item to clean up the temporary files' {
            Should -CommandName Remove-Item -Exactly 1 -ParameterFilter { $Path -eq "$pwd\SimpleDscConfiguration" -and $Force -eq $true -and $Recurse -eq $true }
        }

        It 'should call Get-FileHash to calculate the hash of the created package' {
            Should -CommandName Get-FileHash -Exactly 1 -ParameterFilter { $Path -eq "$pwd\SimpleDscConfiguration.zip" }
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
        }
    }
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1"
        }
        It 'should create a GuestConfigurationPackage in the current directory with the same name as the configuration' {
            Test-Path -Path .\SimpleDscConfiguration.zip -PathType Leaf | Should -Be $true
        }
        It 'should return the path to the created GuestConfigurationPackage' {
            $result.ConfigurationPackage | Should -Be "$pwd\SimpleDscConfiguration.zip"
        }
        It 'should output the name of the configuration' {
            $result.ConfigurationName | Should -Be 'SimpleDscConfiguration'
        }
        It 'should output a file hash of the created GuestConfigurationPackage' {
            $result.ConfigurationFileHash | Should -Not -BeNullOrEmpty
        }
        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
        }
    }
}

AfterAll {

}
