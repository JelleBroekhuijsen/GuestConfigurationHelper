BeforeAll {
    . $PSScriptRoot\..\Public\Publish-GuestConfigurationPackage.ps1
    . $PSScriptRoot\..\Private\Test-ConfigurationFileSizeOnDisk.ps1
    . $PSScriptRoot\..\Private\Compress-ConfigurationFileSizeOnDisk.ps1

    $script:TestConfigPath = "$PSScriptRoot\SampleConfigs\SimpleDscConfiguration.ps1"
    
    # Create a stub function for New-GuestConfigurationPackage
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

        $packagePath = Join-Path $Path "$Name.zip"
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

Describe 'Edge Cases and Additional Coverage' {
    Context 'Test-ConfigurationFileSizeOnDisk with CompressConfiguration parameter' {
        BeforeEach {
            Mock Expand-Archive {}
            Mock New-Item { return @{FullName = "$pwd\TestPackage" } }
            Mock Get-Item { return @{FullName = "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"; BaseName = 'SimpleDscConfiguration' } }
            Mock Get-ChildItem { return @{Length = 50MB} }
            Mock Measure-Object { return @{Sum = 50MB} }
            Mock Remove-Item {}
            Mock Compress-ConfigurationFileSizeOnDisk {}
        }

        It 'should call Compress-ConfigurationFileSizeOnDisk when CompressConfiguration is specified' {
            Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip" -CompressConfiguration
            Should -CommandName Compress-ConfigurationFileSizeOnDisk -Exactly 1
        }

        It 'should not call Compress-ConfigurationFileSizeOnDisk when CompressConfiguration is not specified' {
            Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"
            Should -CommandName Compress-ConfigurationFileSizeOnDisk -Exactly 0
        }
    }

    Context 'Compress-ConfigurationFileSizeOnDisk error handling' {
        BeforeEach {
            New-Item -Path "$pwd\TestModules" -ItemType Directory -Force -ErrorAction SilentlyContinue
            New-Item -Path "$pwd\TestModules\Modules" -ItemType Directory -Force -ErrorAction SilentlyContinue
        }

        It 'should handle case with no versioned folders' {
            Mock Get-ChildItem { return @() }
            { Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder "$pwd\TestModules" } | Should -Not -Throw
        }

        It 'should only remove folders matching version regex pattern' {
            Mock Get-ChildItem { 
                return @(
                    @{Name = '1.0.0'; FullName = "$pwd\TestModules\Modules\1.0.0"},
                    @{Name = 'NotAVersion'; FullName = "$pwd\TestModules\Modules\NotAVersion"}
                )
            }
            Mock Remove-Item {}
            Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder "$pwd\TestModules"
            Should -CommandName Remove-Item -ParameterFilter { $Path -like '*\1.0.0' } -Exactly 1
            Should -CommandName Remove-Item -ParameterFilter { $Path -like '*\NotAVersion' } -Exactly 0
        }

        AfterEach {
            Remove-Item -Path "$pwd\TestModules" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Publish-GuestConfigurationPackage parameter combinations' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk { return $true }
            Mock Compress-ConfigurationFileSizeOnDisk {}
        }

        It 'should work with OutputFolder and CompressConfiguration together' {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -OutputFolder "$pwd\Tests\SampleConfigs" -CompressConfiguration
            $result.ConfigurationPackage | Should -BeLike "*\Tests\SampleConfigs\SimpleDscConfiguration.zip"
        }

        It 'should work with NoCleanup and CompressConfiguration together' {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -NoCleanup -CompressConfiguration
            Test-Path -Path "$pwd\SimpleDscConfiguration" | Should -Be $true
            Test-Path -Path "$pwd\GCH_Staging" | Should -Be $true
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\GCH_Staging" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\Tests\SampleConfigs\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Publish-GuestConfigurationPackage verbose output validation' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk { return $true }
            Mock Compress-ConfigurationFileSizeOnDisk {}
        }

        It 'should output verbose messages when -Verbose is specified' {
            $verboseOutput = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" -Verbose 4>&1
            $verboseOutput | Where-Object { $_ -match 'Publish-GuestConfigurationPackage started' } | Should -Not -BeNullOrEmpty
            $verboseOutput | Where-Object { $_ -match 'Extracted configuration name' } | Should -Not -BeNullOrEmpty
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\GCH_Staging" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }

    Context 'Test-ConfigurationFileSizeOnDisk with custom staging folder' {
        BeforeEach {
            New-Item -Path "$pwd\CustomStaging" -ItemType Directory -Force -ErrorAction SilentlyContinue
        }

        It 'should use custom staging folder when specified' {
            Mock Expand-Archive {}
            Mock Get-Item { return @{FullName = "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"; BaseName = 'SimpleDscConfiguration' } }
            Mock New-Item { param($Path, $Name, $ItemType) return @{FullName = Join-Path $Path $Name } }
            Mock Get-ChildItem { return @{Length = 50MB} }
            Mock Measure-Object { return @{Sum = 50MB} }
            Mock Remove-Item {}

            Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip" -StagingFolder "$pwd\CustomStaging"
            
            Should -CommandName New-Item -ParameterFilter { $Path -eq "$pwd\CustomStaging" } -Exactly 1
        }

        AfterEach {
            Remove-Item -Path "$pwd\CustomStaging" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Publish-GuestConfigurationPackage Azure DevOps output' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk { return $true }
            Mock Compress-ConfigurationFileSizeOnDisk {}
        }

        It 'should output Azure DevOps variables' {
            $output = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath" 6>&1
            $vsoCommands = $output | Where-Object { $_ -match '##vso\[task\.setvariable' }
            $vsoCommands | Should -Not -BeNullOrEmpty
            $vsoCommands | Where-Object { $_ -match 'ConfigurationName' } | Should -Not -BeNullOrEmpty
            $vsoCommands | Where-Object { $_ -match 'ConfigurationPackage' } | Should -Not -BeNullOrEmpty
            $vsoCommands | Where-Object { $_ -match 'ConfigurationFileHash' } | Should -Not -BeNullOrEmpty
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\GCH_Staging" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }

    Context 'File hash calculation' {
        BeforeEach {
            Mock Test-ConfigurationFileSizeOnDisk { return $true }
            Mock Compress-ConfigurationFileSizeOnDisk {}
        }

        It 'should calculate SHA256 hash of the package' {
            $result = Publish-GuestConfigurationPackage -Configuration "$script:TestConfigPath"
            $result.ConfigurationFileHash | Should -Not -BeNullOrEmpty
            $result.ConfigurationFileHash.Length | Should -Be 64  # SHA256 hash is 64 characters
        }

        AfterEach {
            Remove-Item -Path "$pwd\SimpleDscConfiguration.zip" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$pwd\SimpleDscConfiguration" -Force -ErrorAction SilentlyContinue -Recurse
            Remove-Item -Path "$pwd\GCH_Staging" -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}
