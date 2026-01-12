# Sample DSC config for testing (as a regular PowerShell function for Linux compatibility)
function SimpleDscConfiguration {
  param()
  
  # Create output directory structure
  $configFolder = Join-Path $pwd "SimpleDscConfiguration"
  if (-not (Test-Path $configFolder)) {
    New-Item -ItemType Directory -Path $configFolder -Force | Out-Null
  }
  
  # Create mock MOF file
  $mofPath = Join-Path $configFolder "localhost.mof"
  @"
/*
@TargetNode='localhost'
@GeneratedBy=SimpleDscConfiguration
@GenerationDate=01/12/2026 14:43:00
@GenerationHost=localhost
*/
instance of MSFT_ServiceResource as `$MSFT_ServiceResource1ref
{
ResourceID = "[Service]SampleService";
 Name = "SampleService";
 State = "Running";
 SourceInfo = "::5::3::Service";
 ModuleName = "PSDscResources";
 ModuleVersion = "2.12.0.0";
 ConfigName = "SimpleDscConfiguration";
};
"@ | Out-File -FilePath $mofPath -Force -Encoding ascii
  
  # Return FileInfo object for MOF file
  return Get-Item $mofPath
}