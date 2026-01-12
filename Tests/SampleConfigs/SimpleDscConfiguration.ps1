Configuration SimpleDscConfiguration {
  param()
  Import-DscResource -ModuleName 'PSDscResources'
  File SampleFile {
    DestinationPath = 'C:\temp\sample.txt'
    Contents        = 'test'
    Ensure          = 'Present'
  }
}