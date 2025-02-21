BeforeAll {
  . $PSScriptRoot\..\Private\Compress-ConfigurationFileSizeOnDisk.ps1
}

Describe 'Invoking Test-ConfigurationFileSizeOnDisk with minimal parameters' {
  Context 'testing parameter validation' {
    It 'should throw an error if the input provided for $ExtractedConfigurationPackageFolder is not a valid path' {
      { Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder .\absentfolder } | Should -Throw "Cannot validate argument on parameter 'ExtractedConfigurationPackageFolder'. The `" Test-Path -Path `$_ -PathType Container `" validation script for the argument with value `".\absentfolder`" did not return a result of True. Determine why the validation script failed, and then try the command again."
    }
  }
  Context 'testing cmdlet invocation' {
    It 'should remove all folders matching the regex pattern from the Modules folder' {
      New-Item -Path "$pwd\Modules" -ItemType Directory
      Mock Get-ChildItem { return @(
          @{
            Name = '1.0.0'
            FullName = "$pwd\Modules\1.0.0"
          },
          @{
            Name = '2.0.0'
            FullName = "$pwd\Modules\2.0.0"
          },
          @{
            Name = '3.0.0'
            FullName = "$pwd\Modules\3.0.0"
          }
        )
      }
      Mock Remove-Item {}
      Compress-ConfigurationFileSizeOnDisk -ExtractedConfigurationPackageFolder $pwd
      Should -CommandName Remove-Item -ParameterFilter { $Path -like '*\Modules\1.0.0' -or $Path -like '*\Modules\2.0.0' -or $Path -like '*\Modules\3.0.0' } -Exactly 3
    }
    AfterAll {
      Remove-Item -Path "$pwd\Modules" -Recurse -Force
    }
  }
}

