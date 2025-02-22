BeforeAll {
    . $PSScriptRoot\..\Public\Publish-GuestConfigurationPackage.ps1
    . $PSScriptRoot\..\Private\Test-ConfigurationFileSizeOnDisk.ps1
    . $PSScriptRoot\..\Private\Compress-ConfigurationFileSizeOnDisk.ps1

}

Describe 'Invoking Publish-GuestConfigurationPackage with minimal parameters' {
    Context 'testing parameter validation' {
        It 'should throw an error if the input provided for $Configuration is not a valid path' {
            { Publish-GuestConfigurationPackage -Configuration .\absentfile.ps1 } | Should -Throw "Cannot validate argument on parameter 'Configuration'. The `" Test-Path -Path `$_ -PathType Leaf `" validation script for the argument with value `".\absentfile.ps1`" did not return a result of True.*"
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
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
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
            Mock New-Item { return @{FullName = "$pwd\gch_staging" } }
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
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

        It 'should call Test-ConfigurationFileSizeOnDisk to validate the size of the created package' {
            Should -CommandName Test-ConfigurationFileSizeOnDisk -Exactly 1
        }
        It 'should call New-Item to create a staging folder' {
            Should -CommandName New-Item -Exactly 1 -ParameterFilter { $ItemType -eq 'Directory' }
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
        }
    }
    Context 'testing error handling' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
        }
        It 'should throw an error if it finds multiple configurations in the configuration file' {
            Mock Get-Content { return "Configuration SimpleDscConfiguration {} `nConfiguration AnotherConfiguration {}" }
            { Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" } | Should -Throw "Found multiple configurations in configuration file: *"
        }
        It 'should throw an error if it fails to detect configurations in the configuration file' {
            Mock Get-Content {}
            { Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" } | Should -Throw  "Failed to detect any configurations in configuration file: *"
        }
        It 'should throw an error if it fails to generate a MOF file from the configuration file' {
            Mock Test-Path -ParameterFilter { $Path -like "*localhost.mof" } { return $false }
            { Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" } | Should -Throw "Failed to generate MOF file from configuration file: *"
        }
        It 'should throw an error if it fails to create the GuestConfigurationPackage' {
            Mock New-GuestConfigurationPackage { return $null }
            { Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" } | Should -Throw "Failed to create package for configuration: SimpleDscConfiguration"
        }
        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Invoking Publish-GuestConfigurationPackage with the output folder parameter' {
    Context 'testing parameter validation' {
        BeforeEach{
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
        }
        It 'should throw an error if the specified output folder does not exist' {
            { Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -OutputFolder 'C:\NonExistentFolder' } | Should -Throw "Cannot validate argument on parameter 'OutputFolder'. The `" Test-Path -Path `$_ -PathType Container `" validation script for the argument with value `"C:\NonExistentFolder`" did not return a result of True.*"
        }
    }
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -OutputFolder "$pwd\Tests\SampleConfigs"
        }
        BeforeEach{
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
        }
        It 'should create a GuestConfigurationPackage in the target directory with the same name as the configuration' {
            Test-Path -Path "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.zip" -PathType Leaf | Should -Be $true
        }
        It 'should return the path to the created GuestConfigurationPackage' {
            $result.ConfigurationPackage | Should -Be "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.zip"
        }
        AfterEach {
            Remove-Item -Path "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
        }
    }
    Context 'testing cmdlet invocation' {
        BeforeEach {
            $outputFolder = "$pwd\Tests\SampleConfigs"
            Mock New-GuestConfigurationPackage { return @{Path = "$outputFolder\SimpleDscConfiguration.zip" } }
            Mock Test-Path { return $true }
            Mock Get-FileHash {}
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
            Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -OutputFolder $outputFolder
        }

        It 'should call New-GuestConfigurationPackage to create the package' {
            Should -CommandName New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Name -eq 'SimpleDscConfiguration' -and $Configuration -like '*\SimpleDscConfiguration\SimpleDscConfiguration.mof' -and $Path -like '*\Tests\SampleConfigs' }
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}

Describe 'Invoking Publish-GuestConfigurationPackage with the NoCleanup switch' {
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -NoCleanup
        }
        BeforeEach{
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
        }
        It 'should leave the temporary files in place' {
            Test-Path -Path "$pwd\SimpleDscConfiguration" -PathType Container | Should -Be $true
            Test-Path -Path "$pwd\SimpleDscConfiguration\SimpleDscConfiguration.mof" -PathType Leaf | Should -Be $true
            Test-Path -Path "$pwd\gch_staging" -PathType Container | Should -Be $true
        }
        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
    Context 'testing cmdlet invocation' {
        BeforeEach {
            Mock Remove-Item {}
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
            Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -NoCleanup
        }

        It 'should not call Remove-Item to clean up the temporary files' {
            Should -CommandName Remove-Item -Exactly 0
        }

        AfterAll {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}	

Describe 'Invoking Publish-GuestConfigurationPackage with the CompressConfiguration switch' {
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -CompressConfiguration
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
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
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
            Mock New-Item { return @{FullName = "$pwd\gch_staging" } }
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
            Mock Compress-Archive {}
            Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -CompressConfiguration
        }

        It 'should call Compress-ConfigurationFileSizeOnDisk to compress the configuration package' {
            Should -CommandName Test-ConfigurationFileSizeOnDisk -Exactly 1 -ParameterFilter { $CompressConfiguration -eq $true }
        }

        It 'should call Compress-Archive to compress the configuration package' {
            Should -CommandName Compress-Archive -Exactly 1
        }

        AfterAll {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}	

Describe 'Invoking Publish-GuestConfigurationPackage with the OverrideDefaultConfigurationName parameter' {
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -OverrideDefaultConfigurationName 'NewName' -Verbose
        }
        It 'should create a GuestConfigurationPackage in the current directory with the same name as the configuration' {
            Test-Path -Path .\NewName.zip -PathType Leaf | Should -Be $true
        }
        It 'should return the path to the created GuestConfigurationPackage' {
            $result.ConfigurationPackage | Should -Be "$pwd\NewName.zip"
        }
        It 'should output the name of the configuration' {
            $result.ConfigurationName | Should -Be 'NewName'
        }
        It 'should output a file hash of the created GuestConfigurationPackage' {
            $result.ConfigurationFileHash | Should -Not -BeNullOrEmpty
        }
        AfterEach {
            Remove-Item -Path "$pwd\NewName.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
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
            Mock New-Item { return @{FullName = "$pwd\gch_staging" } }
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
            Publish-GuestConfigurationPackage -Configuration "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.ps1" -OverrideDefaultConfigurationName 'NewName'
        }

        It 'should rename the MOF file to the specified name' {
            Should -CommandName Rename-Item -Exactly 1 -ParameterFilter { $NewName -eq 'NewName.mof' }
        }

        It 'should create a GuestConfigurationPackage with the specified name' {
            Should -CommandName New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Name -eq 'NewName' }
        }

        AfterAll {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}
