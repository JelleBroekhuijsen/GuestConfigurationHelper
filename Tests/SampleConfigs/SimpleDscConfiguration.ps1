Configuration SimpleDscConfiguration {
  param()
  Import-DscResource -ModuleName 'PSDscResources' 
  Service SampleService {
    Name  = 'SampleService'
    State = 'Running'
  }
}

SimpleDscConfiguration