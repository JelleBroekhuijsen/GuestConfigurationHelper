BeforeAll {
    . $PSScriptRoot\..\Public\Publish-GuestConfigurationPackage.ps1
    . $PSScriptRoot\..\Private\Test-ConfigurationFileSizeOnDisk.ps1
    . $PSScriptRoot\..\Private\Compress-ConfigurationFileSizeOnDisk.ps1

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
            Mock New-Item { 
                param($Path, $Name, $ItemType)
                # Mock Test-Path to return true for this mocked path
                Mock Test-Path { return $true } -ParameterFilter { $_ -like "*$Name*" }
                return [PSCustomObject]@{FullName = (Join-Path $Path $Name) }
            }
            Mock Get-Item { return [PSCustomObject]@{FullName = "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"; BaseName = 'SimpleDscConfiguration' } }
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

    Context 'Test-ConfigurationFileSizeOnDisk with custom staging folder' {
        BeforeEach {
            New-Item -Path "$pwd\CustomStaging" -ItemType Directory -Force -ErrorAction SilentlyContinue
        }

        It 'should use custom staging folder when specified' {
            Mock Expand-Archive {}
            Mock Get-Item { return [PSCustomObject]@{FullName = "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"; BaseName = 'SimpleDscConfiguration' } }
            Mock New-Item { 
                param($Path, $Name, $ItemType)
                return [PSCustomObject]@{FullName = Join-Path $Path $Name }
            }
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

    Context 'Test-ConfigurationFileSizeOnDisk size warning' {
        BeforeEach {
            Mock Expand-Archive {}
            Mock Get-Item { return [PSCustomObject]@{FullName = "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"; BaseName = 'SimpleDscConfiguration' } }
            Mock New-Item { 
                param($Path, $Name, $ItemType)
                Mock Test-Path { return $true } -ParameterFilter { $_ -like "*$Name*" }
                return [PSCustomObject]@{FullName = (Join-Path $Path $Name) }
            }
            Mock Get-ChildItem { return @{Length = 150MB} }
            Mock Measure-Object { return @{Sum = 150MB} }
            Mock Remove-Item {}
        }

        It 'should return false and output warning when package exceeds 100MB' {
            $warnings = @()
            $result = Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip" -WarningVariable warnings -WarningAction SilentlyContinue
            $result | Should -Be $false
            $warnings | Where-Object { $_ -match 'too large' } | Should -Not -BeNullOrEmpty
        }

        It 'should return true when package is under 100MB' {
            Mock Measure-Object { return @{Sum = 50MB} }
            Mock Get-ChildItem { return @{Length = 50MB} }
            $result = Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"
            $result | Should -Be $true
        }
    }

    Context 'Compress-ConfigurationFileSizeOnDisk with complex version patterns' {
        BeforeEach {
            New-Item -Path "$pwd\TestModules\Modules" -ItemType Directory -Force -ErrorAction SilentlyContinue
        }

        It 'should remove folders with semantic version format (X.Y.Z)' {
            Mock Get-ChildItem { 
                return @(
                    @{Name = '1.0.0'; FullName = "$pwd\TestModules\Modules\1.0.0"},
                    @{Name = '2.3.1'; FullName = "$pwd\TestModules\Modules\2.3.1"},
                    @{Name = '10.20.30'; FullName = "$pwd\TestModules\Modules\10.20.30"}
                )
            }
            Mock Remove-Item {}
            Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder "$pwd\TestModules"
            Should -CommandName Remove-Item -Exactly 3
        }

        It 'should remove folders with extended version format (X.Y.Z.W)' {
            Mock Get-ChildItem { 
                return @(
                    @{Name = '1.0.0.0'; FullName = "$pwd\TestModules\Modules\1.0.0.0"},
                    @{Name = '2.3.1.5'; FullName = "$pwd\TestModules\Modules\2.3.1.5"}
                )
            }
            Mock Remove-Item {}
            Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder "$pwd\TestModules"
            Should -CommandName Remove-Item -Exactly 2
        }

        It 'should not remove folders that do not match version pattern' {
            Mock Get-ChildItem { 
                return @(
                    @{Name = 'v1.0.0'; FullName = "$pwd\TestModules\Modules\v1.0.0"},
                    @{Name = 'latest'; FullName = "$pwd\TestModules\Modules\latest"},
                    @{Name = 'MyModule'; FullName = "$pwd\TestModules\Modules\MyModule"}
                )
            }
            Mock Remove-Item {}
            Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder "$pwd\TestModules"
            Should -CommandName Remove-Item -Exactly 0
        }

        AfterEach {
            Remove-Item -Path "$pwd\TestModules" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

