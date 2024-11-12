BeforeAll {
    Import-Module $pwd.Path -Force
    $nrOftestFiles = 4
    for($i=0; $i -lt $nrOftestFiles; $i++) {
@"
Configuration SampleConfiguration$i {
    param()

    Import-DscResource -ModuleName 'PSDscResources'     

    Service SampleService {
        Name = 'SampleService'
        State = 'Running'
    }
}

SampleConfiguration$i
"@ | Out-File -FilePath "$($pwd.Path)\sampleconfig$i.ps1" -Force
    }


}

Describe 'GuestConfigurationHelper' {
    Context 'invoking Publish-GuestConfigurationPackage' {
        It 'should throw an error if the input provided for $ConfigurationPath is not a valid path' {
            { Publish-GuestConfigurationPackage -ConfgurationFilePath .\absentfile.ps1 } | Should -Throw
        }
    
        It 'should throw an error if the input provided for $OutputFolder is not a valid path' {
            { Publish-GuestConfigurationPackage -ConfgurationFilePath .\sampleconfig1.ps1 -OutputFolder .\output } | Should -Throw
        }
    }
    Context 'executing Publish-GuestConfigurationPackage' {
        It 'should create a MOF file in a child folder of the current directory with the same name as the configuration' {
            Mock New-GuestConfigurationPackage {}
            Publish-GuestConfigurationPackage -ConfigurationFilePath .\sampleconfig2.ps1
            Test-Path -Path .\SampleConfiguration2\SampleConfiguration2.mof -PathType Leaf | Should -Be $true
        }
        It 'should throw an error if no MOF file is generated' {
            "" | Out-File -FilePath .\emptyconfig.ps1 -Force
            { Publish-GuestConfigurationPackage -ConfigurationFilePath .\emptyconfig.ps1 } | Should -Throw
            Remove-Item -Path .\emptyconfig.ps1 -Force
        }
        It 'should create a configuration package in the current directory with the same name as the configuration' {
            Publish-GuestConfigurationPackage -ConfigurationFilePath .\sampleconfig3.ps1
            Test-Path -Path .\SampleConfiguration3.zip -PathType Leaf | Should -Be $true
            Remove-Item -Path .\SampleConfiguration3.zip -Force
        }


    }
}

AfterAll {
    Get-ChildItem -Path .\ -Filter 'sampleconfig*' | Remove-Item -Force
}