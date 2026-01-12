# Test-friendly configuration that doesn't require PSDscResources module
# This is used for unit testing only - it creates the expected MOF output structure

# This null assignment with here-string allows regex detection to work
# The pattern ^\s*Configuration\s+(\w+) will match the line inside the here-string
$null = @'
Configuration SimpleDscConfiguration
'@

function SimpleDscConfiguration {
    param()
    # Create a mock MOF file output matching what DSC would produce
    $currentLocation = Get-Location
    $configFolder = Join-Path $currentLocation "SimpleDscConfiguration"
    New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
    $mofPath = Join-Path $configFolder "localhost.mof"
    @"
/*
@TargetNode='localhost'
@GeneratedBy=TestUser
@GenerationDate=01/01/2024 00:00:00
@GenerationHost=TestHost
*/

instance of MSFT_ScriptResource as `$MSFT_ScriptResource1ref
{
    ResourceID = "[Script]SampleFile";
    GetScript = "{ return @{ Result = 'test' } }";
    TestScript = "{ return `$true }";
    SetScript = "{ }";
    SourceInfo = "::4::5::Script";
    ModuleName = "PSDscResources";
    ModuleVersion = "2.12.0.0";
    ConfigurationName = "SimpleDscConfiguration";
};

instance of OMI_ConfigurationDocument
{
    Version="2.0.0";
    MinimumCompatibleVersion = "1.0.0";
    CompatibleVersionAdditionalProperties= {"Omi_BaseResource:ConfigurationName"};
    Author="TestUser";
    GenerationDate="01/01/2024 00:00:00";
    GenerationHost="TestHost";
    Name="SimpleDscConfiguration";
};
"@ | Out-File -FilePath $mofPath -Force -Encoding UTF8
    return Get-Item $mofPath
}
