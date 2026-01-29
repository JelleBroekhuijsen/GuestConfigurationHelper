BeforeAll {
    . $PSScriptRoot\..\Public\Publish-GuestConfigurationPackage.ps1
    . $PSScriptRoot\..\Private\Test-ConfigurationFileSizeOnDisk.ps1
    . $PSScriptRoot\..\Private\Compress-ConfigurationFileSizeOnDisk.ps1

    # Use test-friendly configuration that doesn't require PSDscResources module
    $script:TestConfigPath = "$PSScriptRoot\SampleConfigs\SimpleDscConfiguration.ps1"
    $script:TestWithParametersConfigPath = "$PSScriptRoot\SampleConfigs\SimpleDscConfigurationWithParameters.ps1"
    # Mock-friendly configuration for cmdlet invocation tests (does no file I/O when dot-sourced)
    $script:MockConfigPath = "$PSScriptRoot\SampleConfigs\SimpleDscConfigurationMock.ps1"

    # Create a stub function for the external New-GuestConfigurationPackage command
    # This command is from the GuestConfiguration module (external dependency)
    # We stub it here to allow tests to run without requiring the module to be installed
    function New-GuestConfigurationPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [string]$Configuration,

            [Parameter(Mandatory)]
            [string]$Path,

            [Parameter()]
            [string]$Type,

            [Parameter()]
            [switch]$Force
        )

        # Return object structure similar to actual New-GuestConfigurationPackage output
        $packagePath = Join-Path $Path "$Name.zip"
        # Create actual zip file for tests that check file existence
        if (-not (Test-Path $packagePath)) {
            $tempFile = New-TemporaryFile
            Compress-Archive -Path $tempFile.FullName -DestinationPath $packagePath -Force
            Remove-Item $tempFile.FullName -Force
        }
        return [PSCustomObject]@{
            Path = $packagePath
            Name = $Name
            Configuration = $Configuration
        }
    }
}

Describe 'Invoking Publish-GuestConfigurationPackage with minimal parameters' {
    Context 'testing parameter validation' {
        It 'should throw an error if the input provided for $Configuration is not a valid path' {
            { Publish-GuestConfigurationPackage -Configuration .\absentfile.ps1 } | Should -Throw "Cannot validate argument on parameter 'Configuration'. The `" Test-Path -Path `$_ -PathType Leaf `" validation script for the argument with value `".\absentfile.ps1`" did not return a result of True.*"
        }
    }
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath"
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
            $sampleConfiguration = Get-Content -Path $script:MockConfigPath -ErrorAction Stop
            # Return different values for Get-Item based on what's being requested
            Mock Get-Item {
                if ($Path -like '*.ps1') {
                    return @{FullName = "$script:MockConfigPath" }
                } else {
                    # For MOF file requests, return the expected localhost.mof path
                    return @{FullName = "$pwd\SimpleDscConfigurationMock\localhost.mof" }
                }
            }
            Mock Get-Content { return $sampleConfiguration }
            Mock Join-Path { return "$pwd\SimpleDscConfigurationMock\SimpleDscConfigurationMock.mof" }
            Mock Rename-Item {}
            Mock New-GuestConfigurationPackage { return @{Path = "$pwd\SimpleDscConfigurationMock.zip" } }
            Mock Test-Path { return $true }
            Mock Remove-Item {}
            Mock Get-FileHash { return 'EFE785C0BFD22E7A44285BB1D9725C3AE06B9110CCA40D568BAFA9B5D824506B' }
            Mock New-Item { return @{FullName = "$pwd\gch_staging" } }
            Mock Test-ConfigurationFileSizeOnDisk
            Mock Compress-ConfigurationFileSizeOnDisk
            Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath"
        }
        It 'should call Get-Item with the path to the configuration file' {
            Should -CommandName Get-Item -ParameterFilter { $Path -like '*SimpleDscConfigurationMock.ps1' } -Exactly 1
        }

        It 'should call Get-Content with the path to the configuration file' {
            Should -CommandName Get-Content -Exactly 1 -ParameterFilter { $Path -like '*SimpleDscConfigurationMock.ps1' }
        }

        It 'should call Join-Path with the path to predict the path of the final MOF file' {
            Should -CommandName Join-Path -Exactly 1 -ParameterFilter { $ChildPath -eq 'SimpleDscConfigurationMock' -and $AdditionalChildPath -eq 'SimpleDscConfigurationMock.mof' }
        }

        It 'should call Rename-Item to rename the MOF file' {
            Should -CommandName Rename-Item -Exactly 1 -ParameterFilter { $Path -eq "$pwd\SimpleDscConfigurationMock\localhost.mof" -and $NewName -eq 'SimpleDscConfigurationMock.mof' }
        }

        It 'should call New-GuestConfigurationPackage to create the package with default AuditAndSet type' {
            Should -CommandName New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Name -eq 'SimpleDscConfigurationMock' -and $Configuration -like '*\SimpleDscConfigurationMock\SimpleDscConfigurationMock.mof' -and $Type -eq 'AuditAndSet' }
        }

        It 'should call Remove-Item to clean up the temporary files' {
            Should -CommandName Remove-Item -Exactly 1 -ParameterFilter { $Path -eq "$pwd\SimpleDscConfigurationMock" -and $Force -eq $true -and $Recurse -eq $true }
        }

        It 'should call Get-FileHash to calculate the hash of the created package' {
            Should -CommandName Get-FileHash -Exactly 1 -ParameterFilter { $Path -eq "$pwd\SimpleDscConfigurationMock.zip" }
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
            # Need to mock Get-Content before calling the function
            Mock Get-Content { return @("Configuration SimpleDscConfigurationMock {}", "Configuration AnotherConfiguration {}") }
            { Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath" } | Should -Throw "Found multiple configurations in configuration file: *"
        }
        It 'should throw an error if it fails to detect configurations in the configuration file' {
            Mock Get-Content { return @() }
            { Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath" } | Should -Throw  "Failed to detect any configurations in configuration file: *"
        }
        It 'should throw an error if it fails to generate a MOF file from the configuration file' {
            # Use mock config which doesn't create any files
            { Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath" } | Should -Throw "Failed to generate MOF file from configuration file: *"
        }
        It 'should throw an error if it fails to create the GuestConfigurationPackage' {
            Mock New-GuestConfigurationPackage { return @{ Path = $null } }
            # The error message uses $configurationFile.BaseName which is SimpleDscConfiguration
            { Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" } | Should -Throw "Failed to create package for configuration: SimpleDscConfiguration"
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
            { Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -OutputFolder 'C:\NonExistentFolder' } | Should -Throw "Cannot validate argument on parameter 'OutputFolder'. The `" Test-Path -Path `$_ -PathType Container `" validation script for the argument with value `"C:\NonExistentFolder`" did not return a result of True.*"
        }
    }
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -OutputFolder "$pwd\Tests\SampleConfigs"
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
            Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -OutputFolder $outputFolder
        }

        It 'should call New-GuestConfigurationPackage to create the package with default AuditAndSet type' {
            Should -CommandName New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Name -eq 'SimpleDscConfiguration' -and $Configuration -like '*\SimpleDscConfiguration\SimpleDscConfiguration.mof' -and $Path -like '*\Tests\SampleConfigs' -and $Type -eq 'AuditAndSet' }
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}

Describe 'Invoking Publish-GuestConfigurationPackage with the NoCleanup switch' {
    Context 'validating results' {
        BeforeAll {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -NoCleanup
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
            # Only mock Remove-Item calls targeting the config folder or staging folder (cleanup paths)
            Mock Remove-Item {} -ParameterFilter { $Path -like '*SimpleDscConfiguration*' -or $Path -like '*GCH_Staging*' }
            Mock Test-ConfigurationFileSizeOnDisk
            Mock Compress-ConfigurationFileSizeOnDisk
            Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -NoCleanup
        }

        It 'should not call Remove-Item to clean up the temporary files' {
            Should -CommandName Remove-Item -ParameterFilter { $Path -like '*SimpleDscConfiguration*' -or $Path -like '*GCH_Staging*' } -Exactly 0
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
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -CompressConfiguration
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
            $sampleConfiguration = Get-Content -Path $script:MockConfigPath -ErrorAction Stop
            Mock Get-Item { return @{FullName = "$script:MockConfigPath" } }
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
            Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath" -CompressConfiguration
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
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -OverrideDefaultConfigurationName 'NewName' -Verbose
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
            $sampleConfiguration = Get-Content -Path $script:MockConfigPath -ErrorAction Stop
            Mock Get-Item { return @{FullName = "$script:MockConfigPath" } }
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
            Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath" -OverrideDefaultConfigurationName 'NewName'
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

Describe 'Invoking Publish-GuestConfigurationPackage with the Mode parameter' {
    Context 'testing parameter validation' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk
            Mock Compress-ConfigurationFileSizeOnDisk
        }

        It 'should throw an error if an invalid Mode value is provided' {
            { Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -Mode 'InvalidMode' } | Should -Throw "*Cannot validate argument on parameter 'Mode'*"
        }

        It 'should accept Audit as a valid Mode value' {
            { Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -Mode 'Audit' } | Should -Not -Throw
        }

        It 'should accept AuditAndSet as a valid Mode value' {
            { Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -Mode 'AuditAndSet' } | Should -Not -Throw
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }

    Context 'testing cmdlet invocation with Mode parameter' {
        BeforeEach {
            $sampleConfiguration = Get-Content -Path $script:MockConfigPath -ErrorAction Stop
            Mock Get-Item {
                if ($Path -like '*.ps1') {
                    return @{FullName = "$script:MockConfigPath" }
                } else {
                    return @{FullName = "$pwd\SimpleDscConfigurationMock\localhost.mof" }
                }
            }
            Mock Get-Content { return $sampleConfiguration }
            Mock Join-Path { return "$pwd\SimpleDscConfigurationMock\SimpleDscConfigurationMock.mof" }
            Mock Rename-Item {}
            Mock New-GuestConfigurationPackage { return @{Path = "$pwd\SimpleDscConfigurationMock.zip" } }
            Mock Test-Path { return $true }
            Mock Remove-Item {}
            Mock Get-FileHash { return 'EFE785C0BFD22E7A44285BB1D9725C3AE06B9110CCA40D568BAFA9B5D824506B' }
            Mock New-Item { return @{FullName = "$pwd\gch_staging" } }
            Mock Test-ConfigurationFileSizeOnDisk
            Mock Compress-ConfigurationFileSizeOnDisk
        }

        It 'should call New-GuestConfigurationPackage with Type Audit when Mode is Audit' {
            Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath" -Mode 'Audit'
            Should -Invoke New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Type -eq 'Audit' }
        }

        It 'should call New-GuestConfigurationPackage with Type AuditAndSet when Mode is AuditAndSet' {
            Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath" -Mode 'AuditAndSet'
            Should -Invoke New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Type -eq 'AuditAndSet' }
        }

        It 'should default to AuditAndSet when Mode is not specified' {
            Publish-GuestConfigurationPackage -Configuration "$script:MockConfigPath"
            Should -Invoke New-GuestConfigurationPackage -Exactly 1 -ParameterFilter { $Type -eq 'AuditAndSet' }
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfigurationMock.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfigurationMock" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }

    Context 'validating results with different modes' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk
            Mock Compress-ConfigurationFileSizeOnDisk
        }

        It 'should create packages successfully with Audit mode' {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -Mode 'Audit'
            $result.ConfigurationPackage | Should -Not -BeNullOrEmpty
            Test-Path -Path $result.ConfigurationPackage -PathType Leaf | Should -Be $true
        }

        It 'should create packages successfully with AuditAndSet mode' {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -Mode 'AuditAndSet'
            $result.ConfigurationPackage | Should -Not -BeNullOrEmpty
            Test-Path -Path $result.ConfigurationPackage -PathType Leaf | Should -Be $true
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}

Describe 'Invoking Publish-GuestConfigurationPackage with deeply nested ConfigurationParameters' {
    Context 'testing that deeply nested parameters do not cause JSON truncation warnings' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk 
            Mock Compress-ConfigurationFileSizeOnDisk
        }
        It 'should not produce JSON truncation warnings when ConfigurationParameters contain deeply nested objects' {
            # Create a deeply nested parameter structure similar to the issue reported
            $deeplyNestedParams = @{
                Verbose = $true
                ConfigurationData = @{
                    NonNodeData = @{
                        sentinelTenants = @(
                            @{
                                ensure = 'Present'
                                azureTenantId = 'tenant1.onmicrosoft.com'
                                azureKeyVaultName = 'mykeyvault01'
                                secretNamePrefix = 'some-prefix'
                            },
                            @{
                                ensure = 'Present'
                                azureTenantId = 'tenant2.onmicrosoft.com'
                                azureKeyVaultName = 'mykeyvault02'
                                secretNamePrefix = 'other-prefix'
                            }
                        )
                    }
                    AllNodes = @()
                }
            }
            
            # Capture verbose output
            $verboseOutput = Publish-GuestConfigurationPackage -Configuration "$script:TestWithParametersConfigPath" -ConfigurationParameters $deeplyNestedParams -Verbose 4>&1
            
            # Check that no truncation warning appears in the verbose output
            $verboseOutput | Where-Object { $_ -match 'truncated as serialization has exceeded the set depth' } | Should -BeNullOrEmpty
        }
        
        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfigurationWithParameters.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\gch_staging" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\SimpleDscConfigurationWithParameters" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}
