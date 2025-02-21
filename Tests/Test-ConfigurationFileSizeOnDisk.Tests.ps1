BeforeAll {
    . $PSScriptRoot\..\Private\Test-ConfigurationFileSizeOnDisk.ps1
}

Describe 'Invoking Test-ConfigurationFileSizeOnDisk with minimal parameters' {
    Context 'testing parameter validation' {
        It 'should throw an error if the input provided for $ConfigurationPackage is not a valid path' {
            { Test-ConfigurationFileSizeOnDisk -ConfigurationPackage .\absentfile.zip } | Should -Throw "Cannot validate argument on parameter 'ConfigurationPackage'. The `" Test-Path -Path `$_ -PathType Leaf `" validation script for the argument with value `".\absentfile.zip`" did not return a result of True.*"
        }
    }
    Context 'validating results' {
        It 'should return $true if the configuration package is less than 100MB' {
            $result = Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"
            $result | Should -Be $true
        }
        It 'should return $false if the configuration package is greater than 100MB' {
            Mock Get-ChildItem { return @{
                    FullName = "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"
                } 
            }
            Mock Measure-Object { return @{
                    Sum = 105906176
                } 
            }
            $result = Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"
            $result | Should -Be $false
        }
    }
    Context 'testing cmdlet invocation' {
        BeforeEach {
            $sampleConfigPackageFile = Get-Item -Path "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"
            Mock Expand-Archive {}
            Mock Get-Item { return @{
                    FullName = $sampleConfigPackageFile.FullName
                    BaseName = $sampleConfigPackageFile.BaseName
                } 
            }
            Mock New-Item {
                return @{
                    FullName = "$PSScriptRoot\$($sampleConfigPackageFile.BaseName)"
                }
            }
            Mock Get-ChildItem {}          
            Mock Remove-Item {}
            Test-ConfigurationFileSizeOnDisk -ConfigurationPackage  "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip"
        }
        It 'should call Expand-Archive with the path to the configuration file and the path to the staging folder' {
            Should -CommandName Expand-Archive -ParameterFilter { $Path -like '*\Tests\SampleConfigPackage\SimpleDscConfiguration.zip' -and $DestinationPath -Like "*$($sampleConfigPackageFile.BaseName)" } -Exactly 1
        }
        It 'should call Get-Item with the path to the configuration file' {
            Should -CommandName Get-Item -ParameterFilter { $Path -like '*\Tests\SampleConfigPackage\SimpleDscConfiguration.zip' } -Exactly 1
        }
        It 'should call New-Item with the path to the staging folder' {
            Should -CommandName New-Item -ParameterFilter { $Name -eq $sampleConfigPackageFile.BaseName -and $ItemType -eq 'Directory' } -Exactly 1
        }     
        It 'should call Get-ChildItem' {
            Should -CommandName Get-ChildItem -Exactly 1
        }
    }
    Context 'testing error handling' {
        It 'should throw an error if a folder with the configuration name already exists in the staging folder' {
            New-Item 'SimpleDscConfiguration' -ItemType Directory
            { Test-ConfigurationFileSizeOnDisk -ConfigurationPackage "$pwd\Tests\SampleConfigPackage\SimpleDscConfiguration.zip" } | Should -Throw "An item with the specified name $pwd\SimpleDscConfiguration already exists."
        }
        AfterEach {
            Remove-Item -Path 'SimpleDscConfiguration' -Force -ErrorAction SilentlyContinue -Recurse
        }
    }
}

